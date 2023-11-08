import 'package:flutter/material.dart';

class InvitationsCRUDWidget extends StatelessWidget {
  const InvitationsCRUDWidget({
    // required this.inviteTitle,
    required this.inviteButtonLabel,
    required this.acceptInviteButtonLabel,
    required this.onCreateInvitePressed,
    required this.onManuallyAcceptInvitePressed,
    this.cardBorderRadius = 24,
    super.key,
  });

  // final String inviteTitle;
  final String inviteButtonLabel;
  final String acceptInviteButtonLabel;
  final VoidCallback onCreateInvitePressed;
  final VoidCallback onManuallyAcceptInvitePressed;
  final double cardBorderRadius;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.person_add),
          TextButton(
            onPressed: onCreateInvitePressed,
            child: Text(
              inviteButtonLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onManuallyAcceptInvitePressed,
            child: Text(
              acceptInviteButtonLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
