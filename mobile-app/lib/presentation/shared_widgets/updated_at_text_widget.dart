import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// TODO: internationalize
class UpdatedAtTextWidget extends StatelessWidget {
  const UpdatedAtTextWidget({
    super.key,
    required this.updatedAt,
    this.minAgo = 'min ago',
    this.hrAgo = 'hr ago',
    this.yesterday = 'Yesterday',
    this.daysAgo = 'days ago',
  });

  final DateTime updatedAt;
  final String minAgo;
  final String hrAgo;
  final String yesterday;
  final String daysAgo;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    String timeText;

    if (difference.inMinutes < 60) {
      timeText = '${difference.inMinutes} $minAgo';
    } else if (difference.inHours < 3) {
      timeText = '${difference.inHours} $hrAgo';
    } else if (difference.inHours < 24) {
      final timeFormat = DateFormat.jm();
      timeText = timeFormat.format(updatedAt);
    } else if (difference.inHours < 48) {
      timeText = yesterday;
    } else if (difference.inDays < 3) {
      timeText = '${difference.inDays} $daysAgo';
    } else {
      final dateFormat = DateFormat.yMMMMd();
      timeText = dateFormat.format(updatedAt);
    }

    return Text(
      timeText,
      style: const TextStyle(
        fontSize: 12, // specify your size here
        fontWeight: FontWeight.w300, // light
        color: Colors.grey, // you can choose your preferred color
      ),
    );
  }
}
