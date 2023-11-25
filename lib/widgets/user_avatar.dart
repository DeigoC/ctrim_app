import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utility/app_context.dart';

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

  Widget _buildImageAvatar(final BuildContext context) {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final String? appDir = appContext.appDir;

    if (tmpImageSrc != null) {
      return CircleAvatar(backgroundImage: NetworkImage(tmpImageSrc!), radius: radius);
    }

    if (appDir != null && (appContext.currentUser.id != _user.id || !appContext.useUserImageSrc)) {
      // debugPrint('using the file for user profile image - ID ${_user.id}');
      return _buildFileImage(appDir);
    } else {
      return CircleAvatar(backgroundImage: NetworkImage(_user.imgSrc), radius: radius);
    }
  }

  Widget _buildFileImage(final String appDir) {
    return FutureBuilder(
        future: _fetchFileImage(appDir),
        builder: (_, snap) {
          Widget result = const CircularProgressIndicator();

          if (snap.hasData) {
            return CircleAvatar(
              backgroundImage: FileImage(snap.data!),
              radius: radius,
              onBackgroundImageError: (exception, stackTrace) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  debugPrint('broken user image, will retry on rebuild - ID ${_user.id}');
                  _deleteFile(appDir);
                });
              },
            );
          } else if (snap.hasError) {
            debugPrint('ID ${_user.id} - user image error: ${snap.error}');
            result = const Center(child: Text('!'));
          }
          return result;
        });
  }

  Widget _buildTextAvatar() {
    return CircleAvatar(
        radius: radius,
        child: Text(_user.initials, style: TextStyle(fontSize: radius == null ? null : (radius! * 0.7))));
  }

  // * Logic

  Future<File> _fetchFileImage(final String appDir) async {
    final String filePath = '$appDir/user_imgs/${_user.id}.png';
    final File imgFile = File(filePath);

    if (!await imgFile.exists()) {
      debugPrint('attempting to fetch image for user: ${_user.id} with file: $filePath');
      final response = await http.get(Uri.parse(_user.imgSrc));
      return await imgFile.writeAsBytes(response.bodyBytes);
    }
    return imgFile;
  }

  Future<bool> _deleteFile(final String appDir) async {
    final String filePath = '$appDir/user_imgs/${_user.id}.png';
    final File imgFile = File(filePath);
    if (await imgFile.exists()) {
      debugPrint('deleting file');
      await imgFile.delete();
    }
    return true;
  }
}
