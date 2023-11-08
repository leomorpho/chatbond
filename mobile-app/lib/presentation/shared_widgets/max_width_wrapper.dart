import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class MaxWidthView extends StatelessWidget {
  MaxWidthView({
    super.key,
    required this.child,
    this.maxWidth = 800,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaxWidthExternalBox(maxWidth: maxWidth, child: child);
  }
}

class MaxWidthExternalBox extends StatelessWidget {
  const MaxWidthExternalBox({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaxWidthBox(
      maxWidth: maxWidth,
      background:
          Container(color: Theme.of(context).appBarTheme.backgroundColor),
      child: ResponsiveScaledBox(
        width: ResponsiveValue<double>(
          context,
          conditionalValues: [
            Condition.equals(name: MOBILE, value: 450),
            Condition.between(start: 800, end: 1100, value: 800),
            Condition.between(start: 1000, end: 1200, value: 800),
            // There are no conditions for width over 1200
            // because the `maxWidth` is set to 1200 via the MaxWidthView.
          ],
        ).value,
        child:
            BouncingScrollWrapper.builder(context, child, dragWithMouse: true),
      ),
    );
  }
}
