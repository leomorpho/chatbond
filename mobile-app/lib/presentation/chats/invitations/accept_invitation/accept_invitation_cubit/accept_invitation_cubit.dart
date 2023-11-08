import 'package:bloc/bloc.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:equatable/equatable.dart';
import 'package:chatbond/data/repositories/chats_repo/chats_repo.dart';
import 'package:chatbond/data/repositories/repos.dart';

part 'accept_invitation_state.dart';

class AcceptInvitationCubit extends Cubit<AcceptInvitationState> {
  AcceptInvitationCubit(
      {required InvitationsRepo invitationsRepo,
      required ChatThreadsRepo chatsRepo})
      : _invitationsRepo = invitationsRepo,
        _chatsRepo = chatsRepo,
        super(const AcceptInvitationState());

  final InvitationsRepo _invitationsRepo;
  final ChatThreadsRepo _chatsRepo;

  Future<void> acceptInvitation(String? token) async {
    if (token == null || token.isEmpty) return;

    emit(state.copyWith(status: InvitationStatus.loading));

    try {
      final chatThread = await _invitationsRepo.acceptInvitation(token);
      await _chatsRepo.getChatInterlocutors();
      emit(
        state.copyWith(
          status: InvitationStatus.success,
          chatThread: chatThread,
        ),
      );
    } catch (_) {
      state.copyWith(status: InvitationStatus.error);
    }
  }
}
