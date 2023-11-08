import 'package:chatbond_api/src/chats/serializer/chat_thread.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:chatbond/data/repositories/invitation_repo/invitations_repo.dart';
import 'package:loggy/loggy.dart';

class AcceptInvitationFormBloc extends FormBloc<String, String> {
  AcceptInvitationFormBloc({required InvitationsRepo invitationsRepo})
      : _invitationsRepo = invitationsRepo {
    addFieldBlocs(fieldBlocs: [invitationLink]);
  }
  final invitationLink = TextFieldBloc(
    validators: [FieldBlocValidators.required],
  );

  final InvitationsRepo _invitationsRepo;
  late ChatThread? chatThread;

  String _extractInvitationCode(String url) {
    final regex = RegExp(r'\/([^\/]+)$');
    final Match? match = regex.firstMatch(url);

    if (match != null && match.groupCount >= 1) {
      final token = match.group(1)!;
      logDebug('_extractInvitationCode: $url -> $token');
      return token;
    } else {
      throw const FormatException('Invalid URL format');
    }
  }

  @override
  Future<void> onSubmitting() async {
    String invitationToken;
    try {
      invitationToken = _extractInvitationCode(invitationLink.value);
    } catch (e) {
      emitFailure(failureResponse: 'Invalid URL');
      return;
    }
    chatThread = await _invitationsRepo.acceptInvitation(invitationToken);
    emitSuccess(successResponse: 'New chat thread joined');
  }
}
