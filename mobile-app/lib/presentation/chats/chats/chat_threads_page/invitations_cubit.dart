import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chatbond/data/events.dart';
import 'package:chatbond/data/repositories/realtime_repo/realtime_repo.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';
import 'package:loggy/loggy.dart';

class InvitationsCubit extends Cubit<InvitationsState> {
  InvitationsCubit({required this.invitationRepo, required this.realtimeRepo})
      : super(InvitationsInitial()) {
    invitationCreatedSubscription =
        invitationRepo.invitationCreatedStream.listen(_onInvitationCreated);

    invitationRealtimeSubscription = realtimeRepo
        .invitationRealtimeEventController.stream
        .listen((realtimeUpdateEvent) {
      logInfo(
        'InvitationsCubit received a new Invitation update event',
      );

      final invitation = Invitation.fromJson(realtimeUpdateEvent.data.content);
      logDebug(
        'InvitationsCubit deserialized an Invitation: $invitation',
      );
      if (realtimeUpdateEvent.action == RealtimeUpdateAction.delete) {
        deleteInvitation(invitation);
      }
    });
  }

  final InvitationsRepo invitationRepo;
  final RealtimeRepo realtimeRepo;
  List<Invitation> invitations = [];

  late StreamSubscription<InvitationCreatedEvent> invitationCreatedSubscription;
  late final StreamSubscription<RealtimeUpdateEvent>
      invitationRealtimeSubscription;

  void deleteInvitation(Invitation invitation, {bool callBackend = false}) {
    final invitationIndex =
        invitations.indexWhere((element) => element.id == invitation.id);

    if (invitationIndex != -1) {
      // Check if the invitation exists in the list
      invitations.removeAt(invitationIndex); // Remove the invitation
      emit(
        InvitationsLoaded(
          invitations: List.from(invitations),
        ),
      ); // Emit new state
      logInfo('Invitation with id ${invitation.id} has been removed');

      if (callBackend) {
        // Call the backend without awaiting its completion
        invitationRepo.deleteInvitationById(invitation.id).then((success) {
          if (success) {
            logInfo('Invitation successfully deleted from backend');
          } else {
            logWarning('Failed to delete invitation from backend');
          }
        }).catchError((error) {
          logError('An error occurred while deleting invitation: $error');
        });
      }
    } else {
      logWarning(
        'Tried to delete an invitation that does not exist in the list',
      );
    }
  }

  Future<void> fetchInvitations() async {
    try {
      invitations = await invitationRepo.getAllInvitations();
      emit(InvitationsLoaded(invitations: List.from(invitations)));
    } catch (e) {
      // Handle errors as appropriate
      logError('Error fetching invitations: $e');
    }
  }

  void _onInvitationCreated(InvitationCreatedEvent event) {
    invitations.add(event.invitation); // Add the new invitation
    emit(
      InvitationsLoaded(
        invitations: List.from(invitations),
      ),
    ); // Emit new state
  }

  @override
  Future<void> close() {
    invitationCreatedSubscription.cancel();
    invitationRealtimeSubscription.cancel();
    return super.close();
  }
}

sealed class InvitationsState extends Equatable {
  const InvitationsState();

  @override
  List<Object> get props => [];
}

final class InvitationsInitial extends InvitationsState {}

class InvitationsLoaded extends InvitationsState {
  const InvitationsLoaded({required this.invitations});
  final List<Invitation> invitations;

  @override
  List<Object> get props => [invitations];
}
