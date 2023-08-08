import 'dart:io';

import 'package:ctrim_app/utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';

class MyUserAvatar extends StatelessWidget {
  const MyUserAvatar(this._user, {super.key, this.radius, this.tmpImageSrc});
  final User _user;
  final double? radius;
  final String? tmpImageSrc;

  @override
  Widget build(BuildContext context) {
    if (_user.imgSrc != '' || tmpImageSrc != null) {
      return _buildImageAvatar(context);
    }
    return _buildTextAvatar();
  }

  Widget _buildImageAvatar(BuildContext context) {
    final String filePath = '${Provider.of<AppContext>(context, listen: false).appDir}/user_imgs/${_user.id}.png';
    final File imgFile = File(filePath);
    return CircleAvatar(
        backgroundImage: (tmpImageSrc != null ? NetworkImage(tmpImageSrc!) : FileImage(imgFile)) as ImageProvider,
        radius: radius);
  }

  Widget _buildTextAvatar() {
    return CircleAvatar(
        radius: radius,
        child: Text(_user.initials, style: TextStyle(fontSize: radius == null ? null : (radius! * 0.7))));
  }
}
