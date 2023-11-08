import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/locale_keys.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond/presentation/login/password_reset_confirm_page/password_reset_confirm_bloc.dart';
import 'package:chatbond/presentation/shared_widgets/constants.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/sized_icon.dart';
import 'package:chatbond/presentation/shared_widgets/string_formatter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';

@RoutePage()
class PasswordResetConfirmPage extends StatelessWidget {
  const PasswordResetConfirmPage({
    super.key,
    @PathParam('uid') required this.uid,
    @PathParam('token') required this.token,
  });

  final String uid;
  final String token;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PasswordResetConfirmFormBloc(
        userRepo: context.read<UserRepo>(),
        uid: uid,
        token: token,
      ),
      child: Builder(
        builder: (context) {
          final passwordResetFormBloc =
              context.read<PasswordResetConfirmFormBloc>();

          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: const Text('Choose a new password'),
            ),
            body: MaxWidthView(
              child: FormBlocListener<PasswordResetConfirmFormBloc, String,
                  String>(
                onSubmitting: (context, state) {
                  LoadingDialog.show(context);
                },
                onSubmissionFailed: (context, state) {
                  LoadingDialog.hide(context);
                },
                onSuccess: (context, state) {
                  LoadingDialog.hide(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('You password was reset! You can log in now.'),
                    ),
                  );
                  context.router.pop();
                },
                onFailure: (context, state) {
                  LoadingDialog.hide(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.failureResponse!)),
                  );
                },
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: AutofillGroup(
                    child: Padding(
                      padding: const EdgeInsets.all(authButtonPadding),
                      child: Column(
                        children: <Widget>[
                          const SizedIcon(
                            icon: Icons.lock_reset,
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          SizedBox(
                            width: authFieldsWidth,
                            child: TextFieldBlocBuilder(
                              textFieldBloc: passwordResetFormBloc.password,
                              suffixButton: SuffixButton.obscureText,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText:
                                    LocaleKeys.password.tr().toCapitalized(),
                                prefixIcon: const Icon(Icons.lock),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: authFieldsWidth,
                            height: authFieldsHeight,
                            child: ElevatedButton(
                              onPressed: passwordResetFormBloc.submit,
                              child: const Text(
                                'Change password',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
