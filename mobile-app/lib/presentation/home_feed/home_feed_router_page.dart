import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';

@RoutePage()
class HomeFeedRouter extends StatefulWidget {
  const HomeFeedRouter({super.key});

  @override
  State<HomeFeedRouter> createState() => _HomeFeedRouterState();
}

class _HomeFeedRouterState extends State<HomeFeedRouter>
    with AutoRouteAwareStateMixin<HomeFeedRouter> {
  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    logError('didChangeTabRoute -------------------------------');
  }

  @override
  Widget build(BuildContext context) {
    return const AutoRouter();
  }
}
