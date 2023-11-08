import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/presentation/shared_widgets/logo.dart';
import 'package:flutter/material.dart';

class DrawerNav extends Drawer {
  DrawerNav({super.key})
      : super(
          child: ListView(
            children: [
              LogoWithTextWidget(),
              // const DrawerHeader(child: Text('Drawer Header')),
              const DrawerNavItem(
                title: 'Home',
                route: LandingRoute(),
              ),
              DrawerNavItem(
                title: 'Login/Signup',
                route: LoginRoute(),
              ),
            ],
          ),
        );
}

class DrawerNavItem extends StatelessWidget {
  const DrawerNavItem({super.key, required this.title, required this.route});

  final String title;
  final PageRouteInfo route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      onTap: () {
        AutoRouter.of(context).replace(route);
        Scaffold.of(context).closeDrawer();
      },
    );
  }
}
