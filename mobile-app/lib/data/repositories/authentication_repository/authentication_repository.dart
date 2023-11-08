import 'dart:async';

import 'package:chatbond/data/repositories/authentication_repository/authentication_repository_interface.dart';
import 'package:chatbond/data/repositories/secure_storage_repo.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:loggy/loggy.dart';
import 'package:rxdart/rxdart.dart';

enum AuthenticationStatus { unknown, authenticated, unauthenticated }

class AuthenticationRepository implements IAuthenticationRepository {
  AuthenticationRepository({
    required SecureStorageRepo secureStorageRepo,
    required ApiClient apiClient,
  })  : _secureStorage = secureStorageRepo,
        _apiClient = apiClient;

  final SecureStorageRepo _secureStorage; // TODO: doesn't seem to be used
  final _controller = BehaviorSubject<AuthenticationStatus>();
  late final ApiClient _apiClient;

  @override
  Stream<AuthenticationStatus> get status async* {
    yield AuthenticationStatus.unknown;
    final isLoggedIn = await isAlreadyLoggedIn();
    if (isLoggedIn) {
      yield AuthenticationStatus.authenticated;
    } else {
      yield AuthenticationStatus.unauthenticated;
    }
    yield* _controller.stream;
  }

  @override
  Future<bool> isAlreadyLoggedIn() async {
    // See if we still have a valid access token
    if (await _isAccessTokenValid()) {
      return true;
    }

    // No valid access token available. Try to get a new one if we have a valid
    // refresh token.
    final currRefreshToken = await _secureStorage.getRefreshToken();
    if (currRefreshToken == null) {
      return false;
    }
    // Refresh the tokens in secure storage
    try {
      await _apiClient.auth.refreshToken(refreshToken: currRefreshToken);
      if (await _isAccessTokenValid()) {
        return true;
      }
    } catch (e) {
      logError('isAlreadyLoggedIn - $e');
    }
    return false;
  }

  /// Validates the access token, and logs out the user if the token is invalid
  Future<void> validateTokenAndLogoutIfInvalid() async {
    var isTokenValid = await _isAccessTokenValid();
    if (!isTokenValid) {
      // Try to refresh the token
      final currRefreshToken = await _secureStorage.getRefreshToken();
      if (currRefreshToken != null) {
        try {
          await _apiClient.auth.refreshToken(refreshToken: currRefreshToken);
          isTokenValid = await _isAccessTokenValid();
        } catch (e) {
          logError('Failed to refresh the token: $e');
        }
      }

      // If token is still invalid, log out
      if (!isTokenValid) {
        await logOut();
      }
    }
  }

  Future<bool> _isAccessTokenValid() async {
    late bool isValid;
    final currAccessToken = await _secureStorage.getAccessToken();
    if (currAccessToken != null) {
      isValid = await _apiClient.auth.verifyToken(token: currAccessToken);
      if (isValid) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String? dateOfBirth,
  }) async {
    await _apiClient.auth.signup(
      email: email,
      password: password,
      dateOfBirth: dateOfBirth,
      name: name,
    );
  }

  @override
  Future<void> logIn({
    required String email,
    required String password,
  }) async {
    final isLoggedIn =
        await _apiClient.auth.login(email: email, password: password);
    logInfo('AuthenticationRepository.logIn - isLoggedIn: $isLoggedIn');
    if (isLoggedIn) {
      _controller.add(AuthenticationStatus.authenticated);
      logInfo(
          'AuthenticationRepository.logIn - added `AuthenticationStatus.authenticated` to bloc stream');
    } else {
      throw Exception('Login failed due to bad credentials');
    }
  }

  @override
  Future<void> logOut() async {
    _apiClient.auth.logout();
    await _secureStorage.emptySecureStorageNow();
    _controller.add(AuthenticationStatus.unauthenticated);

    logDebug('AuthenticationRepository - logged user out');
  }

  @override
  void triggerTokenExpired() {
    _controller.add(AuthenticationStatus.unauthenticated);
  }

  @override
  Future<bool> checkEmailAvailability(String email) async {
    return _apiClient.auth.checkEmailAvailability(email);
  }

  @override
  void dispose() => _controller.close();
}
