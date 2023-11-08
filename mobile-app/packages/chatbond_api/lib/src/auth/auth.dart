import 'dart:convert';

import 'package:chatbond_api/chatbond_api.dart';
import 'package:chatbond_api/src/auth/auth_interface.dart';
import 'package:chatbond_api/src/auth/serializer/token_create.dart';
import 'package:chatbond_api/src/auth/serializer/token_refresh.dart';
import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';

/// {@template auth}
/// A class for handling authentication operations in a Flutter application.
///
/// This class provides a set of methods to interact with the Chatbond API
/// for managing user authentication. It includes operations such as signup,
/// login, logout, token verification, and token refreshing.
///
/// Example usage:
///
/// ```dart
/// final auth = Auth(
///   baseUrl: 'https://api.example.com',
///   accessTokenUpdater: (token) => 'update_token_function',
///   accessTokenGetter: () => 'get_token_function',
/// );
///
/// // Sign up a new user
/// final isSignedUp = await auth.signup(
///   name: 'john_doe',
///   email: 'john.doe@example.com',
///   password: 'password123',
/// );
///
/// // Log in a user
/// final isLoggedIn = await auth.login(
///   email: 'john.doe@example.com',
///   password: 'password123',
/// );
///
/// // Refresh a token
/// final refreshedToken = await auth.refreshToken(
///   refreshToken: 'your_refresh_token');
///
/// // Verify a token
/// final isTokenValid = await auth.verifyToken(token: 'your_jwt_token');
///
/// // Log out a user
/// auth.logout();
/// ```
///
/// {@endtemplate}
class Auth implements AuthInterface {
  Auth({
    required this.baseUrl,
    required this.accessTokenUpdater,
    required this.refreshTokenUpdater,
    required this.accessTokenGetter,
    required this.refreshTokenGetter,
    required this.getAccessTokenFromCookie,
    required this.getRefreshTokenFromCookie,
  });

  final String baseUrl;
  final TokenUpdater accessTokenUpdater;
  final TokenGetter accessTokenGetter;
  final TokenUpdater refreshTokenUpdater;
  final TokenGetter refreshTokenGetter;
  final GetAccessTokenFromCookie getAccessTokenFromCookie;
  final GetRefreshTokenFromCookie getRefreshTokenFromCookie;

  @override
  Future<User> signup({
    required String email,
    required String password,
    required String name,
    required String? dateOfBirth,
  }) async {
    final url = Uri.parse('$baseUrl/auth/users/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'date_of_birth': dateOfBirth,
      }),
    );

    if (response.statusCode == 201) {
      return User.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      logError(
        'Failed to create user - email: $email, response.body: ${response.body}, response.statusCode: ${response.statusCode}',
      );
      throw Exception('Failed to create user');
    }
  }

  @override
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/jwt/create/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final token = TokenCreate.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      accessTokenUpdater(token.access); // Update the token
      refreshTokenUpdater(token.refresh); // Update the refresh token
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<TokenRefresh> refreshToken({required String refreshToken}) async {
    final url = Uri.parse('$baseUrl/auth/jwt/refresh/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'refresh': refreshToken,
      }),
    );
    logDebug('Status Code: ${response.statusCode} |'
        ' Headers: ${response.headers} | Body: ${response.body}');
    if (response.statusCode == 200) {
      final token = TokenRefresh.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      accessTokenUpdater(token.access);
      refreshTokenUpdater(token.refresh);
      return token;
    } else {
      throw Exception('Failed to refresh the token');
    }
  }

  @override
  Future<bool> verifyToken({required String token}) async {
    final url = Uri.parse('$baseUrl/auth/jwt/verify/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  @override
  void logout() {
    accessTokenUpdater(null); // Destroy the stored token
  }

  @override
  Future<bool> checkEmailAvailability(String email) async {
    final url = Uri.parse('$baseUrl/api/v1/check-email/$email/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return true;
    } else {
      logError(
        'Tried to register with registered email - email: $email, response.body: ${response.body}, response.statusCode: ${response.statusCode}',
      );
      return false;
    }
  }
}
