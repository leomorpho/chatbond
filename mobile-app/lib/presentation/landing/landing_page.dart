import 'package:auto_route/auto_route.dart';
import 'package:chatbond/presentation/shared_widgets/max_width_wrapper.dart';
import 'package:chatbond/presentation/shared_widgets/navigation_bar.dart';
import 'package:chatbond/presentation/shared_widgets/navigation_drawer.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';

@RoutePage()
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: const Text('Home'),
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
          const SizedBox(
            height: 16,
          ),
          Flexible(
            child: MaxWidthView(
              child: const Text('Landing Page...work in progress!'),
            ),
          ),
        ],
      ),
    );
  }
}
