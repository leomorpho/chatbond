import 'package:chatbond_api/chatbond_api.dart';

abstract class InvitationsRepoInterface {
  Future<List<Invitation>> getAllInvitations();
  Future<Invitation> createInvitation(String personName);
  Future<ChatThread> acceptInvitation(String token);
  Future<bool> deleteInvitationById(String id);
}
