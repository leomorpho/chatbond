part of 'accept_invitation_cubit.dart';

enum InvitationStatus { initial, loading, success, error }

class AcceptInvitationState extends Equatable {
  const AcceptInvitationState({
    this.status = InvitationStatus.initial,
    this.chatThread,
  });

  final InvitationStatus status;
  final ChatThread? chatThread;

  AcceptInvitationState copyWith({
    InvitationStatus? status,
    ChatThread? chatThread,
  }) {
    return AcceptInvitationState(
      status: status ?? this.status,
      chatThread: chatThread ?? this.chatThread,
    );
  }

  @override
  List<Object?> get props => [status, chatThread];
}
