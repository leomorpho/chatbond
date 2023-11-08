import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/locale_keys.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/presentation/login/login.dart';
import 'package:chatbond/presentation/shared_widgets/constants.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/navigation_bar.dart';
import 'package:chatbond/presentation/shared_widgets/navigation_drawer.dart';
import 'package:chatbond/presentation/shared_widgets/sized_icon.dart';
import 'package:chatbond/presentation/shared_widgets/string_formatter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
    this.onLoginSuccessCallback,
  });

  final void Function()? onLoginSuccessCallback;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final loginFormBloc = context.read<LoginFormBloc>();
        final isMobile = ResponsiveBreakpoints.of(context).isMobile;
        return Scaffold(
          // resizeToAvoidBottomInset: false,
          appBar: isMobile
              ? AppBar(
                  title: Text(LocaleKeys.login.tr().toTitleCase()),
                  leading: Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    },
                  ),
                )
              : null,
          drawer: DrawerNav(),
          body: Column(
            children: [
              if (!isMobile) const NavigationBarWeb(),
              Expanded(
                child: MaxWidthView(
                  child: FormBlocListener<LoginFormBloc, String, String>(
                    onSubmitting: (context, state) {
                      LoadingDialog.show(context);
                    },
                    onSubmissionFailed: (context, state) {
                      LoadingDialog.hide(context);
                    },
                    onSuccess: (context, state) {
                      LoadingDialog.hide(context);
                      // TODO: callback is only used in a guard and seems overriden
                      // here, do we really need it?
                      // onLoginSuccessCallback?.call();
                      AutoRouter.of(context).replaceAll([
                        const HomeTabsRouterRoute(),
                        const HomeFeedRouter(),
                      ]);
                    },
                    onFailure: (context, state) {
                      LoadingDialog.hide(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.failureResponse!)),
                      );
                    },
                    child: SingleChildScrollView(
                      child: AutofillGroup(
                        child: Padding(
                          padding: const EdgeInsets.all(authButtonPadding),
                          child: Column(
                            children: <Widget>[
                              SizedBox(
                                width: authFieldsWidth,
                                child: Column(
                                  children: [
                                    const SizedIcon(
                                      icon: Icons.login,
                                    ),
                                    const SizedBox(
                                      height: 24,
                                    ),
                                    TextFieldBlocBuilder(
                                      textFieldBloc: loginFormBloc.email,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [
                                        AutofillHints.username,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: LocaleKeys.email
                                            .tr()
                                            .toCapitalized(),
                                        prefixIcon: const Icon(Icons.email),
                                      ),
                                    ),
                                    TextFieldBlocBuilder(
                                      textFieldBloc: loginFormBloc.password,
                                      suffixButton: SuffixButton.obscureText,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: LocaleKeys.password
                                            .tr()
                                            .toCapitalized(),
                                        prefixIcon: const Icon(Icons.lock),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.all(authButtonPadding),
                                child: TextButton(
                                  onPressed: () => {
                                    context.pushRoute(PasswordResetRoute(
                                      cameFromLogin: true,
                                    )),
                                  },
                                  child: Text(
                                    LocaleKeys.forgotPassword
                                        .tr()
                                        .toTitleCase(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: authFieldsWidth,
                                height: authFieldsHeight,
                                child: ElevatedButton(
                                  onPressed: loginFormBloc.submit,
                                  child: Text(LocaleKeys.login.tr()),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.all(authButtonPadding),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      LocaleKeys.dontHaveAndAccountQuestion
                                          .tr()
                                          .toCapitalized(),
                                    ),
                                    TextButton(
                                      onPressed: () => {
                                        context.pushRoute(
                                          SignUpRoute(
                                            cameFromLogin: true,
                                          ),
                                        ),
                                      },
                                      child: Text(
                                        LocaleKeys.signup.tr(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
