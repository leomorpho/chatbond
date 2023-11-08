import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/locale_keys.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond/presentation/chats/invitations/create_invitation/create_invitation_bloc.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/string_formatter.dart';
import 'package:chatbond/utils.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:share_plus/share_plus.dart';

@RoutePage()
class CreateInvitationPage extends StatelessWidget {
  const CreateInvitationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateInvitationWizardBloc(
        invitationsRepo: context.read<InvitationsRepo>(),
      ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(LocaleKeys.createNewInvitation).tr(),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  context.read<CreateInvitationWizardBloc>().deleteInvitation();
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: MaxWidthView(
              child:
                  FormBlocListener<CreateInvitationWizardBloc, String, String>(
                onSubmitting: (context, state) => LoadingDialog.show(context),
                onSubmissionFailed: (context, state) {
                  LoadingDialog.hide(context);
                },
                onSuccess: (context, state) {
                  LoadingDialog.hide(context);
                  if (state.stepCompleted == state.lastStep) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully created a new invitation!'),
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
                onFailure: (context, state) {
                  LoadingDialog.hide(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.failureResponse!)),
                  );
                  context.read<CreateInvitationWizardBloc>().deleteInvitation();
                },
                onSubmissionCancelled: (context, state) {
                  context.read<CreateInvitationWizardBloc>().deleteInvitation();

                  // TODO: delete invitation. Currently, they get auto-deleted after 30 days in BE.
                },
                child: StepperFormBlocBuilder<CreateInvitationWizardBloc>(
                  stepsBuilder: (formBloc) {
                    return [
                      _inviteeNameStep(formBloc!),
                      _shareInvitationStep(context, formBloc),
                    ];
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  FormBlocStep _inviteeNameStep(
    CreateInvitationWizardBloc createInvitationWizardBloc,
  ) {
    return FormBlocStep(
      title: const Text(LocaleKeys.inviteeName).tr(),
      content: TextFieldBlocBuilder(
        textFieldBloc: createInvitationWizardBloc.inviteeName,
        decoration: InputDecoration(
          labelText: LocaleKeys.inviteeName.tr(),
          prefixIcon: const Icon(Icons.person),
        ),
      ),
    );
  }
  // TODO: have a conditional "Continue" field that is reachable only once
  // the invitation has been shared. If it hasn't been shared, immediately
  // delete the invitation creating on the BE when the user backtracks out
  // of the "create invitation" flow.

  FormBlocStep _shareInvitationStep(
    BuildContext context,
    CreateInvitationWizardBloc createInvitationWizardBloc,
  ) {
    return FormBlocStep(
      title: Text(LocaleKeys.shareInvitation.tr()),
      content: Column(
        children: [
          if (createInvitationWizardBloc.createdInvitation != null)
            InvitationInfoWidget(
              invitation: createInvitationWizardBloc.createdInvitation!,
            ),
          if (createInvitationWizardBloc.createdInvitation == null)
            const Center(child: Text('Failed to create invitation'))
        ],
      ),
    );
  }
}

class InvitationInfoWidget extends StatelessWidget {
  const InvitationInfoWidget({
    super.key,
    required this.invitation,
  });

  final Invitation invitation;

  Future<void> shareInvitation() async {
    logDebug('shareInvitation - $invitation');
    await Share.share('Invitation created for ${invitation.inviteeName}: '
        '${invitation.inviteUrl}');
  }

  @override
  Widget build(BuildContext context) {
    var instructionText = LocaleKeys.tapToCopy.tr().toTitleCase();

    if (kIsWeb) {
      instructionText = LocaleKeys.clickToCopy.tr().toTitleCase();
    }
    final invitationMessage = createInviteMessage(
      inviteeName: invitation.inviteeName,
      url: invitation.inviteUrl,
    );
    final shareWithText = LocaleKeys.shareWith.tr();
    final expiryTimeText = LocaleKeys.invitationExpirationMessage.tr(
      args: [invitation.validityDurationInDays.toString()],
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '$instructionText:',
          ),
        ),
        InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: invitationMessage));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocaleKeys.invitationLinkCopiedToClipboad.tr()),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              invitationMessage,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            expiryTimeText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (!kIsWeb)
          ElevatedButton.icon(
            onPressed: () async {
              await shareInvitation();
              // Navigator.pop(context);
            },
            icon: const Icon(Icons.share),
            label: Text(shareWithText),
          ),
      ],
    );
  }
}
