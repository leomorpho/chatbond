import 'package:avatars/avatars.dart';
import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';

class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({
    super.key,
    required this.onEditClicked,
    required this.email,
    required this.username,
    this.imagePath,
    this.isEdit = false,
  });

  final bool isEdit;
  final VoidCallback onEditClicked;
  final String? imagePath;
  final String email;
  final String username;

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      logDebug('ProfileHeaderWidget showing image from $imagePath');
    } else {
      logDebug('ProfileHeaderWidget showing default custom avatar');
    }
    final color = Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              buildImage(context),
              if (isEdit)
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: buildEditIcon(color),
                ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            username,
            style: const TextStyle(fontSize: 24),
          )
        ],
      ),
    );
  }

  Widget buildImage(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: Avatar(
          useCache: true,
          elevation: 3,
          sources: [
            if (imagePath != null) GenericSource(NetworkImage(imagePath!)),
            if (imagePath == null) GravatarSource(email),
            // other sources can be added here
            // e.g., GitHubSource('username'),
          ],
          // use the 'name' parameter if you want to display initials when the image is not available
          // or 'value' to display a specific string
          name: username, // replace this with the user's actual name
          placeholderColors: [color],
          shape: AvatarShape.circle(64), // half of width and height
        ),
      ),
    );
  }

  Widget buildEditIcon(Color color) => InkWell(
        onTap: onEditClicked,
        child: buildCircle(
          color: Colors.white,
          all: 3,
          child: buildCircle(
            color: color,
            all: 8,
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );

  Widget buildCircle({
    required Widget child,
    required double all,
    required Color color,
  }) =>
      ClipOval(
        child: Container(
          padding: EdgeInsets.all(all),
          color: color,
          child: child,
        ),
      );
}
