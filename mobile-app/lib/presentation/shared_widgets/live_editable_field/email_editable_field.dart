import 'package:flutter/material.dart';

class EmailEditableField extends StatelessWidget {
  const EmailEditableField({
    super.key,
    required this.title,
    required this.content,
    this.onTap,
  });

  final String title;
  final String content;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(
            height: 1,
          ),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            title: Text(content),
            trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
            onTap: onTap,
            enabled: onTap != null,
          ),
        ],
      ),
    );
  }
}
