import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AnonymousRouterPage extends StatelessWidget {
  const AnonymousRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AutoRouter();
  }
}
