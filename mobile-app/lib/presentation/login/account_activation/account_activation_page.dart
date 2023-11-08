import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/data/repositories/repos.dart';
import 'package:chatbond/presentation/login/account_activation/account_activation_bloc.dart';
import 'package:chatbond/presentation/shared_widgets/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AccountActivationPage extends StatefulWidget {
  AccountActivationPage({
    super.key,
    @PathParam('uid') required this.uid,
    @PathParam('token') required this.token,
  }) {}

  final String uid;
  final String token;

  @override
  AccountActivationPageState createState() => AccountActivationPageState();
}

class AccountActivationPageState extends State<AccountActivationPage> {
  late AccountActivationCubit activationCubit;
  late Future<void> activationFuture;

  @override
  void initState() {
    super.initState();
    activationCubit =
        AccountActivationCubit(userRepo: context.read<UserRepo>());
    activationFuture = activationCubit.activateUser(widget.uid, widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: activationFuture,
      builder: (context, snapshot) {
        return BlocProvider(
          create: (_) => activationCubit,
          child: BlocBuilder<AccountActivationCubit, ActivationState>(
            builder: (context, state) {
              if (state == ActivationState.initial) {
                return const Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: authFieldsWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Activating... 🚀'),
                          SizedBox(height: 40),
                          CircularProgressIndicator(),
                        ],
                      ),
                    ),
                  ),
                );
              } else if (state == ActivationState.activated) {
                return Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: authFieldsWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Account activated successfully. ✅'),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: () => AutoRouter.of(context).replaceAll(
                              [const AnonymousRouterRoute(), LoginRoute()],
                            ),
                            child: const Text('Go to Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else if (state == ActivationState.failed) {
                return const Scaffold(
                  body: Center(
                    child: Text('Account activation failed. ❌'),
                  ),
                );
              } else {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
