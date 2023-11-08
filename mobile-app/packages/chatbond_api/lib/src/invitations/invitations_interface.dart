import 'package:chatbond_api/src/chats/serializer/chat_thread.dart';
import 'package:chatbond_api/src/invitations/serializer/invitation.dart';

abstract class InvitationsInterface {
  Future<Invitation> createInvitation(String personName);
  Future<bool> deleteInvitationById(String id);
  Future<ChatThread> acceptInvitation(String token);

  Future<List<Invitation>> getInvitations();
  Future<Invitation> getInvitationById(String id);
}
