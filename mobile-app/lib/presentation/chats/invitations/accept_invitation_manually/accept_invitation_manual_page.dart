import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:chatbond/config/locale_keys.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond/presentation/chats/invitations/accept_invitation_manually/accept_invitation_manually_bloc.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/string_formatter.dart';

@RoutePage()
class ManuallyAcceptInvitationRoute extends StatelessWidget {
  const ManuallyAcceptInvitationRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AcceptInvitationFormBloc(
        invitationsRepo: context.read<InvitationsRepo>(),
      ),
      child: Builder(
        builder: (context) {
          final formBloc = context.read<AcceptInvitationFormBloc>();

          return Scaffold(
            appBar: AppBar(
              title: Text(
                LocaleKeys.acceptInvitationManually.tr().toCapitalized(),
              ),
            ),
            body: MaxWidthView(
              child: FormBlocListener<AcceptInvitationFormBloc, String, String>(
                onSubmitting: (context, state) {
                  // Show loading dialog
                },
                onSuccess: (context, state) {
                  // Redirect to ChatThreadPage
                },
                onFailure: (context, state) {
                  // Handle failure
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Warning: This page is to be used only if the magic '
                        "invitation link isn't working. "
                        'Paste the whole URL here  '
                        '(e.g.: chatbond/invite/hkljgJF)',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      TextFieldBlocBuilder(
                        textFieldBloc: formBloc.invitationLink,
                        decoration: const InputDecoration(
                          labelText: 'Invitation Code',
                          prefixIcon: Icon(Icons.code),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _getClipboardText(context),
                        icon: const Icon(Icons.content_paste),
                        label: const Text('Paste from clipboard'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: formBloc.submit,
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _getClipboardText(BuildContext context) async {
    final formBloc = context.read<AcceptInvitationFormBloc>();
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final clipboardText = clipboardData?.text;
    if (clipboardText != null) {
      formBloc.invitationLink.updateValue(clipboardText);
    }
  }
}
