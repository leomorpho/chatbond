import 'package:flutter/material.dart';

class SizedIcon extends StatelessWidget {
  const SizedIcon({super.key, this.size = 50, required this.icon});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
    );
  }
}
