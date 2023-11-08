import 'package:flutter/material.dart';

/// Used when loading items at the bottom of the screen,
/// for example in an infinite vertical scroll window.
class BottomScreenLoader extends StatelessWidget {
  const BottomScreenLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
