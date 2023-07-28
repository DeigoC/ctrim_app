import 'package:flutter/material.dart';

import '../models/user.dart';

class MyUserAvatar extends StatelessWidget {
  const MyUserAvatar(this._user, {super.key, this.radius, this.tmpImageSrc});
  final User _user;
  final double? radius;
  final String? tmpImageSrc;

  @override
  Widget build(BuildContext context) {
    if (_user.imgSrc != '' || tmpImageSrc != null) {
      return _buildImageAvatar();
    }
    return _buildTextAvatar();
  }

  Widget _buildImageAvatar() {
    return CircleAvatar(
        backgroundImage: NetworkImage(tmpImageSrc != null ? tmpImageSrc! : _user.imgSrc), radius: radius);
  }

  Widget _buildTextAvatar() {
    return CircleAvatar(
        radius: radius,
        child: Text(_user.initials, style: TextStyle(fontSize: radius == null ? null : (radius! * 0.7))));
  }
}
