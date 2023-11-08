import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TouchToCopyTextWidget extends StatelessWidget {
  const TouchToCopyTextWidget({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard.')),
        );
      },
      child: Card(
          child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text),
      ),),
    );
  }
}
