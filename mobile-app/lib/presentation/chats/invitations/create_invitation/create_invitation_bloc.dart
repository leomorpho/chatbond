import 'package:chatbond/config/logger/logger_types.dart';
import 'package:chatbond/data/repositories/invitation_repo/invitations_repo.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:loggy/loggy.dart';

class CreateInvitationWizardBloc extends FormBloc<String, String>
    with BlocLogger {
  CreateInvitationWizardBloc({
    required InvitationsRepo invitationsRepo,
  }) : _invitationsRepo = invitationsRepo {
    addFieldBlocs(
      fieldBlocs: [inviteeName],
    );
    addFieldBlocs(
      step: 1,
      fieldBlocs: [
        inviteeName
      ], // TODO: Hack necessary to show second window of wizard
    );
  }

  // ignore: inference_failure_on_instance_creation
  final inviteeName = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
    ],
  );

  final InvitationsRepo _invitationsRepo;
  Invitation? createdInvitation;

  void deleteInvitation() {
    if (createdInvitation != null) {
      _deleteInvitationById(createdInvitation!.id);
    }
  }

  void _deleteInvitationById(String id) {
    _invitationsRepo.deleteInvitationById(id).then((success) {
      if (success) {
        logInfo('Invitation successfully deleted from backend');
      } else {
        logWarning('Failed to delete invitation from backend');
      }
    }).catchError((error) {
      logError('An error occurred while deleting invitation: $error');
    });
  }

  @override
  Future<void> onSubmitting() async {
    if (state.currentStep == 0) {
      try {
        createdInvitation =
            await _invitationsRepo.createInvitation(inviteeName.value);
        logDebug('Successfully created invitation for ${inviteeName.value}');
        emitSuccess(
          canSubmitAgain: true,
          successResponse:
              'Invitation created for ${createdInvitation?.inviteeName}',
        );
      } catch (e) {
        logError('CreateInvitationWizardBloc.onSubmitting: $e');
        emitFailure(
          failureResponse: 'Failed to create invitation...are you online?',
        );
      }
    } else if (state.currentStep == 1) {
      emitSuccess();
    }
  }
}
