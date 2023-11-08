import 'package:auto_route/auto_route.dart';
import 'package:chatbond/presentation/shared_widgets/loading_dialogue.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SplashPage());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingDialog());
  }
}
