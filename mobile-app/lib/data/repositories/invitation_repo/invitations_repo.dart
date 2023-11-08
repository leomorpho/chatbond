import 'dart:async';

import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/data/events.dart';
import 'package:chatbond/data/repositories/invitation_repo/invitations_repo_interface.dart';
import 'package:chatbond_api/chatbond_api.dart';

class InvitationsRepo with RepoLogger implements InvitationsRepoInterface {
  InvitationsRepo({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  final StreamController<InvitationCreatedEvent>
      _invitationCreatedStreamController =
      StreamController<InvitationCreatedEvent>.broadcast();
  Stream<InvitationCreatedEvent> get invitationCreatedStream =>
      _invitationCreatedStreamController.stream;

  final StreamController<InvitationAcceptedEvent>
      _invitationAcceptedStreamController =
      StreamController<InvitationAcceptedEvent>.broadcast();
  Stream<InvitationAcceptedEvent> get invitationAcceptedStream =>
      _invitationAcceptedStreamController.stream;

  @override
  Future<List<Invitation>> getAllInvitations() async {
    return _apiClient.invitations.getInvitations();
  }

  @override
  Future<Invitation> createInvitation(String inviteeName) async {
    final invitation =
        await _apiClient.invitations.createInvitation(inviteeName);

    _invitationCreatedStreamController
        .add(InvitationCreatedEvent(invitation: invitation));

    return invitation;
  }

  @override
  Future<ChatThread> acceptInvitation(String token) async {
    final chatThread = await _apiClient.invitations.acceptInvitation(token);

    // TODO: trigger a refresh of chat threads as there will be a new one.
    _invitationAcceptedStreamController
        .add(InvitationAcceptedEvent(chatThread: chatThread));

    return chatThread;
  }

  @override
  Future<bool> deleteInvitationById(String id) async {
    return _apiClient.invitations.deleteInvitationById(id);
  }
}
