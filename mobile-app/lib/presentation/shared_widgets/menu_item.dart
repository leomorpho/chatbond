import 'package:flutter/material.dart';

class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required this.iconData,
    required this.onTap,
    this.title,
    this.titleWidget,
  });

  final IconData iconData;
  final VoidCallback onTap;
  final String? title;
  final Widget? titleWidget;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      leading: Icon(iconData),
      title: titleWidget ??
          Text(title!), // TODO: improve, this isn't good practice to use !
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
