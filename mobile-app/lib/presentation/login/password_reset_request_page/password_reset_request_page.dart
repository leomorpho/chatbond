import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/locale_keys.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond/presentation/login/password_reset_request_page/password_reset_request_bloc.dart';
import 'package:chatbond/presentation/shared_widgets/constants.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/sized_icon.dart';
import 'package:chatbond/presentation/shared_widgets/string_formatter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';

@RoutePage()
class PasswordResetPage extends StatelessWidget {
  const PasswordResetPage({super.key, this.cameFromLogin = false});

  final bool cameFromLogin;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PasswordResetRequestFormBloc(
        userRepo: context.read<UserRepo>(),
      ),
      child: Builder(
        builder: (context) {
          final passwordResetFormBloc =
              context.read<PasswordResetRequestFormBloc>();

          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text(LocaleKeys.passwordReset.tr().toTitleCase()),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (cameFromLogin) {
                    context.router.pop();
                  } else {
                    AutoRouter.of(context).replaceAll(
                      [
                        const AnonymousRouterRoute(),
                        LoginRoute(),
                      ],
                    );
                  }
                },
              ),
            ),
            body: MaxWidthView(
              child: FormBlocListener<PasswordResetRequestFormBloc, String,
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
                    const SnackBar(content: Text('Password reset email sent!')),
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
                          const SizedBox(
                            width: authFieldsWidth,
                            child: Text(
                              'Enter the email address associated with your account'
                              " and we'll send you a link to reset your password.",
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          SizedBox(
                            width: authFieldsWidth,
                            child: TextFieldBlocBuilder(
                              textFieldBloc: passwordResetFormBloc.email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [
                                AutofillHints.username,
                              ],
                              decoration: InputDecoration(
                                labelText:
                                    LocaleKeys.email.tr().toCapitalized(),
                                prefixIcon: const Icon(Icons.email),
                              ),
                            ),
                          ),
                          SizedBox(
                            width:
                                authFieldsWidth, // TODO: create a reusable component with these specs and use throughout auth routes
                            height: authFieldsHeight,
                            child: ElevatedButton(
                              onPressed: passwordResetFormBloc.submit,
                              child: const Text(
                                'Reset password',
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
