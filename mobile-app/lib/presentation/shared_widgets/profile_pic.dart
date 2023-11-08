import 'package:avatars/avatars.dart';
import 'package:chatbond_api/chatbond_api.dart';
import 'package:flutter/material.dart';

class ProfilePicture extends StatelessWidget {
  const ProfilePicture({
    super.key,
    required this.username,
    required this.email,
    this.numUnseenMessages,
    this.avatarSize = 16,
  });

  final String username;
  final String email;
  final int? numUnseenMessages;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Stack(
      children: <Widget>[
        Avatar(
          useCache: true,
          elevation: 3,
          sources: [
            GravatarSource(email),
          ],
          // use the 'name' parameter if you want to display initials when the image is not available
          // or 'value' to display a specific string
          name: username, // replace this with the user's actual name
          placeholderColors: [color],
          shape: AvatarShape.circle(avatarSize), // half of width and height
        ),
        if (numUnseenMessages != null && numUnseenMessages! > 0)
          Positioned(
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(
                minWidth: 12,
                minHeight: 12,
              ),
              child: Text(
                numUnseenMessages.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
      ],
    );
  }
}

class FacePile extends StatelessWidget {
  const FacePile({
    super.key,
    required this.interlocutors,
    required this.avatarSize,
    this.separationBorderSize = 1,
    this.text,
  });

  final List<Interlocutor> interlocutors;
  final double avatarSize;
  final double separationBorderSize;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < interlocutors.length; i++)
          Container(
            margin: EdgeInsets.zero,
            child: Align(
              widthFactor: 0.5,
              child: CircleAvatar(
                radius: avatarSize,
                backgroundColor: Colors.white,
                child: Tooltip(
                  message: interlocutors[i].name,
                  child: ProfilePicture(
                    username: interlocutors[i].username,
                    email: interlocutors[i].email,
                    avatarSize: avatarSize -
                        separationBorderSize, // You can adjust as needed
                  ),
                ),
              ),
            ),
          ),
        if (text != null) ...[
          const SizedBox(
            width: 15,
          ),
          Text(
            '$text ${interlocutors.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
        ]
      ],
    );
  }
}
