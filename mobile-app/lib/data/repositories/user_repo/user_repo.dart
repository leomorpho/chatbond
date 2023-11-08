import 'dart:async';

import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/data/repositories/global_state.dart';
import 'package:chatbond/service_locator.dart';
import 'package:chatbond_api/chatbond_api.dart';

abstract class UserRepoInterface {
  Future<User?> getCurrentUser();
}

class UserRepo with RepoLogger implements UserRepoInterface {
  UserRepo({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  User? _user;

  final StreamController<User> _currUserUpdatesStreamController =
      StreamController<User>.broadcast();

  @override
  Stream<User> get userUpdatesStream => _currUserUpdatesStreamController.stream;

  @override
  Future<User> getCurrentUser() async {
    User user;

    if (_user != null) {
      user = _user!;
    } else {
      user = await _apiClient.users.getUserDetails();
    }

    if (getIt.get<GlobalState>().currUser == null) {
      getIt.get<GlobalState>().currUser = user;
    }

    return user;
  }

  Future<bool> setEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    return _apiClient.users
        .setEmail(currentPassword: currentPassword, newEmail: newEmail);
    //TODO: _currUserUpdatesStreamController
  }

  Future<void> resetEmail({required String email}) {
    return _apiClient.users.sendResetEmail(email: email);
  }

  Future<bool> setPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _apiClient.users.setPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    //TODO: _currUserUpdatesStreamController
  }

  Future<void> resetPassword({required String email}) {
    return _apiClient.users.resetPassword(email: email);
  }

  Future<void> resetPasswordConfirm({
    required String uid,
    required String token,
    required String newPassword,
  }) {
    return _apiClient.users
        .resetPasswordConfirm(uid: uid, token: token, newPassword: newPassword);
  }

  Future<void> resetEmailConfirm({required String newEmail}) {
    return _apiClient.users.confirmResetEmail(newEmail: newEmail);
  }

  Future<void> resendActivation({required String email}) {
    return _apiClient.users.resendActivationEmail(email: email);
  }

  Future<bool> activateUser(String uid, String token) {
    return _apiClient.users.activateUser(uid: uid, token: token);
  }

  Future<User> updateUser(User user) async {
    final updatedUser = await _apiClient.users.updateUser(updatedUser: user);
    _currUserUpdatesStreamController.add(user);
    getIt.get<GlobalState>().currUser = updatedUser;
    return updatedUser;
  }

  Future<User> patchUser(Map<String, dynamic> patchedUser) async {
    final updatedUser = _apiClient.users.patchUser(updatedFields: patchedUser);
    // TODO: _currUserUpdatesStreamController
    // TODO: getIt.get<GlobalState>().currUser = updatedUser;
    return updatedUser;
  }

  Future<void> deleteUser() async {
    return _apiClient.users.deleteUser();
  }
}
