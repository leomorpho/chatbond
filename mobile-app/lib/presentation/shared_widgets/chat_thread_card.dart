import 'package:chatbond/presentation/shared_widgets/profile_pic.dart';
import 'package:chatbond/presentation/shared_widgets/updated_at_text_widget.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/material.dart';

class ChatThreadCard extends StatelessWidget {
  const ChatThreadCard({
    required this.interlocutor,
    required this.updatedAt,
    required this.numUnseenMessages,
    required this.onWidgetTap,
    this.numAnswerableQuestions, // TODO: eventually must be required
    this.cardBorderRadius = 24,
    super.key,
  });

  final Interlocutor interlocutor;
  final DateTime updatedAt;
  final int numUnseenMessages;
  final VoidCallback onWidgetTap;
  final int? numAnswerableQuestions;
  final double cardBorderRadius;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
      ),
      child: InkWell(
        onTap: onWidgetTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Row(
                  children: [
                    ProfilePicture(
                      username: interlocutor.username,
                      email: interlocutor.email,
                      numUnseenMessages: numUnseenMessages,
                      avatarSize: 24,
                    ),
                    const SizedBox(
                      width: 16,
                    ), // Add some spacing between the badge and the names
                    Text(
                      interlocutor.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // TODO
                subtitle: numAnswerableQuestions != null &&
                        numAnswerableQuestions! > 0
                    ? Text('$numAnswerableQuestions answerable questions')
                    : null,
                trailing: UpdatedAtTextWidget(
                  updatedAt: updatedAt,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
