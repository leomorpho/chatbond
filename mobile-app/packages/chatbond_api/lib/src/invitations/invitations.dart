import 'dart:convert';

import 'package:chatbond_api/chatbond_api.dart';
import 'package:chatbond_api/src/invitations/invitations_interface.dart';
import 'package:chatbond_api/src/invitations/serializer/create_invitation.dart';
import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';

/// {@template invitations}
/// A class for handling chat invitations in a Flutter application.
///
/// This class provides a set of methods to interact with the Chatbond API
/// for managing chat invitations. It includes operations such as creating
/// an invitation, retrieving an invitation by ID, deleting an invitation by ID,
/// and accepting an invitation using a token.
///
/// Example usage:
///
/// ```dart
/// final invitations = Invitations(
///   baseUrl: 'https://api.example.com',
///   accessTokenGetter: () => 'your_jwt_token',
/// );
///
/// // Create a new invitation
/// final newInvitation = await invitations.createInvitation();
///
/// // Get an invitation by ID
/// final invitation = await invitations.getInvitationById(1);
///
/// // Delete an invitation by ID
/// await invitations.deleteInvitationById(1);
///
/// // Accept an invitation using a token
/// await invitations.acceptInvitation('invitation_token');
/// ```
///
/// {@endtemplate}
class Invitations implements InvitationsInterface {
  Invitations({
    required this.baseUrl,
    required this.client,
    required this.accessTokenGetter,
  });

  final String baseUrl;
  final http.Client client;
  final TokenGetter accessTokenGetter;

  @override
  Future<Invitation> createInvitation(String inviteeName) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final apiUrl = '$baseUrl/api/v1/create-invitation/';
    final response = await client.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(CreateInvitation(inviteeName: inviteeName).toJson()),
    );

    if (response.statusCode == 201) {
      return Invitation.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to create invitation');
    }
  }

  @override
  Future<bool> deleteInvitationById(String id) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final apiUrl = '$baseUrl/api/v1/invitations/$id/';
    final response = await client.delete(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      logError('Failed to delete invitation');
      return false;
    }
    return true;
  }

  @override
  Future<ChatThread> acceptInvitation(String token) async {
    final userToken = accessTokenGetter();
    if (userToken == null) {
      throw Exception('User token is not set');
    }
    final apiUrl = '$baseUrl/api/v1/invitations/accept/$token/';
    final response = await client.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $userToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to accept invitation');
    }
    return ChatThread.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<Invitation>> getInvitations() async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final response = await client.get(
      Uri.parse('$baseUrl/api/v1/invitations/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as List<dynamic>;
      return responseData
          .map((data) => Invitation.fromJson(data as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch invitations');
    }
  }

  @override
  Future<Invitation> getInvitationById(String id) async {
    final token = accessTokenGetter();
    if (token == null) {
      throw Exception('Token is not set');
    }
    final apiUrl = '$baseUrl/api/v1/invitations/$id/';
    final response = await client.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Invitation.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to retrieve invitation');
    }
  }

  // You can add other API functions here later
}
