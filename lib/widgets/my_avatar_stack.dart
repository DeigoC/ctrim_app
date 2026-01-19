import 'dart:io';

import 'package:avatar_stack/avatar_stack.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/network_image_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MyAvatarStack extends StatelessWidget {
  const MyAvatarStack({super.key, required this.users, required this.appDir});
  final List<User> users;
  final String? appDir;

  @override
  Widget build(BuildContext context) {
    final List<ImageProvider> avatars = List<ImageProvider>.empty(growable: true);

    for (final thisU in users) {
      if (thisU.imgSrc.isNotEmpty && appDir != null) {
        final path = '$appDir/user_imgs/${thisU.id}.png';
        avatars.add(FileImage(File(path)));
      } else if (thisU.imgSrc.isNotEmpty) {
        avatars.add(NetworkImage(NetworkImageHelper.getImageUrl(thisU.imgSrc)));
      } else {
        avatars.add(const AssetImage('assets/images/Generic-Profile.jpg'));
      }
    }

    // TODO consider using a WidgetStack for our custom Avatars
    // WidgetStack(positions: positions, stackedWidgets: stackedWidgets, buildInfoWidget: buildInfoWidget)
    return AvatarStack(
      height: kToolbarHeight,
      width: kIsWeb ? null : 90,
      avatars: avatars,
    );
  }
}
