import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:chatbond/presentation/shared_widgets/logo.dart';
import 'package:flutter/material.dart';

class NavigationBarWeb extends StatefulWidget {
  const NavigationBarWeb({super.key});

  @override
  State<NavigationBarWeb> createState() => _NavigationBarWebState();
}

class _NavigationBarWebState extends State<NavigationBarWeb> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const LogoWithTextWidget(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              NavigationItem(
                title: 'Home',
                route: const LandingRoute(),
                selected: index == 0,
                onHighlight: onHighlight,
              ),
              NavigationItem(
                title: 'Login/Signup',
                route: LoginRoute(),
                selected: index == 1,
                onHighlight: onHighlight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void onHighlight(String route) {
    switch (route) {
      case LandingRoute.name:
        changeHighlight(0);
        break;
      case LoginRoute.name:
        changeHighlight(1);
        break;
      default:
        changeHighlight(0);
        break;
    }
  }

  void changeHighlight(int newIndex) {
    setState(() {
      index = newIndex;
    });
  }
}

class NavigationItem extends StatefulWidget {
  const NavigationItem({
    super.key,
    required this.title,
    required this.route,
    required this.selected,
    required this.onHighlight,
  });

  final String title;
  final PageRouteInfo route;
  final bool selected;
  final Function onHighlight;

  @override
  NavigationItemState createState() => NavigationItemState();
}

class NavigationItemState extends State<NavigationItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (event) => setState(() {
        isHovered = true;
      }),
      onExit: (event) => setState(() {
        isHovered = false;
      }),
      child: GestureDetector(
        onTap: () {
          context.router.replace(widget.route);
          widget.onHighlight(widget.route.routeName);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 20,
              color: isHovered
                  ? Theme.of(context).hintColor
                  : null, // Default color
              decoration: isHovered ? TextDecoration.underline : null,
            ),
          ),
        ),
      ),
    );
  }
}
