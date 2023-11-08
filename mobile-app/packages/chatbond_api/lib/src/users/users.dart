import 'dart:convert';

import 'package:chatbond_api/chatbond_api.dart';
import 'package:chatbond_api/src/users/users_interface.dart';
import 'package:http/http.dart' as http;

class Users implements UserInterface {
  Users({
    required this.baseUrl,
    required this.client,
    required this.accessTokenGetter,
  });

  final String baseUrl;
  final http.Client client;
  final TokenGetter accessTokenGetter;

  @override
  Future<User> getUserDetails() async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url = Uri.parse('$baseUrl/auth/users/me/');
    final response = await client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to retrieve user details');
    }
  }

  // Update the user's information using PUT
  @override
  Future<User> updateUser({required User updatedUser}) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url = Uri.parse('$baseUrl/auth/users/me/');
    final response = await client.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updatedUser.toJson()),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to update the user');
    }
  }

  // Update the user's information partially using PATCH
  @override
  Future<User> patchUser({required Map<String, dynamic> updatedFields}) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url = Uri.parse('$baseUrl/auth/users/me/');
    final response = await client.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updatedFields),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to partially update the user');
    }
  }

  // Delete the user's account using DELETE
  @override
  Future<void> deleteUser() async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }

    final url = Uri.parse('$baseUrl/auth/users/me/');
    final response = await client.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete the user');
    }
  }

  @override
  Future<bool> activateUser({
    required String uid,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/auth/users/activation/');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': uid,
        'token': token,
      }),
    );

    if (response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 403) {
      // As far as we're concerned, they're already activated so
      // just tell them they're activated.
      return true;
    } else {
      throw Exception('Failed to activate the user');
    }
  }

  @override
  Future<bool> resendActivationEmail({required String email}) async {
    final url = Uri.parse('$baseUrl/auth/users/resend_activation/');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to resend activation email');
    }
  }

  @override
  Future<bool> sendResetEmail({required String email}) async {
    final url = Uri.parse('$baseUrl/auth/users/reset_email/');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to send reset email');
    }
  }

  @override
  Future<bool> confirmResetEmail({required String newEmail}) async {
    final url = Uri.parse('$baseUrl/auth/users/reset_email_confirm/');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'new_email': newEmail,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to confirm reset email');
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    final url = Uri.parse('$baseUrl/auth/users/reset_password/');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode == 204) {
      return;
    } else {
      throw Exception('Failed to reset password');
    }
  }

  @override
  Future<bool> resetPasswordConfirm({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/users/reset_password_confirm/');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': uid,
        'token': token,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to confirm password reset');
    }
  }

  @override
  Future<bool> setEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final url = Uri.parse('$baseUrl/auth/users/set_email/');
    final response = await client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_email': newEmail,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to set email');
    }
  }

  @override
  Future<bool> setPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final url = Uri.parse('$baseUrl/auth/users/set_password/');
    final response = await client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to set password');
    }
  }

  // You can add other API functions here later
}
