import 'package:auto_route/auto_route.dart';
import 'package:chatbond/config/router/router.gr.dart';
import 'package:flutter/material.dart';

class LogoWithTextWidget extends StatelessWidget {
  const LogoWithTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.router
              .replaceAll([const AnonymousRouterRoute(), const LandingRoute()]);
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 1, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/chatbond/apple-icon-180x180.png',
                  height: 50,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(1, 16, 16, 16),
              child: Text(
                'hatbond',
                style: TextStyle(
                  fontSize: 25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
