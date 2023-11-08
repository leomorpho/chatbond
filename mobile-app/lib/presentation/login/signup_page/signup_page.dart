import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/locale_keys.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond/presentation/login/login.dart';
import 'package:chatbond/presentation/shared_widgets/constants.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/sized_icon.dart';
import 'package:chatbond/presentation/shared_widgets/string_formatter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';

@RoutePage()
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, this.cameFromLogin = false});

  /// TODO: not sure if we need age for legal reasons
  static const askForAge = false;
  final bool cameFromLogin;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _showEmailVerificationOverlay = false;

  void showEmailVerificationOverlay() {
    setState(() {
      _showEmailVerificationOverlay = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignUpFormBloc(
        authenticationRepository: context.read<AuthenticationRepository>(),
        askForAge: SignUpPage.askForAge,
      ),
      child: Builder(
        builder: (context) {
          final loginFormBloc = context.read<SignUpFormBloc>();

          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: !_showEmailVerificationOverlay
                ? AppBar(
                    title: Text(LocaleKeys.signup.tr().toTitleCase()),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (widget.cameFromLogin) {
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
                  )
                : null,
            body: FormBlocListener<SignUpFormBloc, String, String>(
              onSubmitting: (context, state) {
                LoadingDialog.show(context);
              },
              onSubmissionFailed: (context, state) {
                LoadingDialog.hide(context);
              },
              onSuccess: (context, state) {
                LoadingDialog.hide(context);

                showEmailVerificationOverlay();
              },
              onFailure: (context, state) {
                LoadingDialog.hide(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.failureResponse!)),
                );
              },
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: AutofillGroup(
                      child: Padding(
                        padding: const EdgeInsets.all(authButtonPadding),
                        child: Center(
                          child: SizedBox(
                            width: authFieldsWidth,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const SizedIcon(
                                  icon: Icons.lock_open,
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                TextFieldBlocBuilder(
                                  textFieldBloc: loginFormBloc.username,
                                  keyboardType: TextInputType.name,
                                  autofillHints: const [
                                    AutofillHints.username,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                    prefixIcon: Icon(Icons.person),
                                    hintText:
                                        'Friends see this name. Choose wisely!',
                                  ),
                                ),
                                TextFieldBlocBuilder(
                                  textFieldBloc: loginFormBloc.email,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [
                                    AutofillHints.email,
                                  ],
                                  decoration: InputDecoration(
                                    labelText:
                                        LocaleKeys.email.tr().toCapitalized(),
                                    prefixIcon: const Icon(Icons.email),
                                  ),
                                  suffixButton: SuffixButton.asyncValidating,
                                ),
                                if (SignUpPage.askForAge) ...[
                                  const SizedBox(height: 16),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '13+: The minimum fun age. Sorry, younger folks, but we must check!',
                                    ),
                                  ),
                                  DateTimeFieldBlocBuilder(
                                    dateTimeFieldBloc: loginFormBloc.birthdate,
                                    format: DateFormat('dd-MM-yyyy'),
                                    initialDate: DateTime.now().subtract(
                                      const Duration(days: 365 * 13 + 3),
                                    ),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now().subtract(
                                      const Duration(days: 365 * 10),
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Birthdate, please?',
                                      prefixIcon: Icon(Icons.calendar_today),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 40,
                                  ),
                                ],
                                TextFieldBlocBuilder(
                                  textFieldBloc: loginFormBloc.password,
                                  suffixButton: SuffixButton.obscureText,
                                  autofillHints: const [AutofillHints.password],
                                  decoration: InputDecoration(
                                    labelText: LocaleKeys.password
                                        .tr()
                                        .toCapitalized(),
                                    prefixIcon: const Icon(Icons.lock),
                                  ),
                                ),
                                const SizedBox(
                                  height: 40,
                                ),
                                SizedBox(
                                  width: authFieldsWidth,
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'By registering, you agree to ',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary, // for the hyperlink effect
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              'our Privacy Policy and User Agreements.',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary, // for the hyperlink effect
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              context.router.push(
                                                UserTermsRoute(
                                                  cameFromSignup: true,
                                                ),
                                              );
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                  width:
                                      authFieldsWidth, // TODO: create a reusable component with these specs and use throughout auth routes
                                  height: authFieldsHeight,
                                  child: ElevatedButton(
                                    onPressed: loginFormBloc.submit,
                                    child: Text(LocaleKeys.signup.tr()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_showEmailVerificationOverlay)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Theme.of(context)
                            .colorScheme
                            .background
                            .withOpacity(1), // Semi-transparent background
                        child: SizedBox(
                          width: authFieldsWidth,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedIcon(
                                  icon: Icons.email_outlined,
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                const Text(
                                  'Check your email',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                Text(
                                  'We just sent an email verification link to ${loginFormBloc.email.value}.',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                SizedBox(
                                  width: authFieldsWidth / 2,
                                  height: authFieldsHeight,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Code to remove the overlay and pop the current page
                                      AutoRouter.of(context).replaceAll(
                                        [
                                          const AnonymousRouterRoute(),
                                          LoginRoute(),
                                        ],
                                      );
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Go to login '),
                                        Icon(
                                          Icons.arrow_forward,
                                          size: 15,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
