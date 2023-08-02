import 'dart:io';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class MyPhotoViewer extends StatelessWidget {
  const MyPhotoViewer({super.key, required this.src, required this.postID});
  final String src;
  final String postID;

  // in theory the file already exists in cache
  @override
  Widget build(BuildContext context) {
    final String cacheDir = Provider.of<AppContext>(context, listen: false).cacheDir;
    final sanitisedFilePath = src.replaceAll(RegExp(r'[^\w]'), '');
    final fullPath = '$cacheDir/$sanitisedFilePath.png';
    final file = File(fullPath);
    final ImageProvider image = (file.existsSync() ? FileImage(file) : NetworkImage(src)) as ImageProvider;
    return PhotoView(imageProvider: image, heroAttributes: PhotoViewHeroAttributes(tag: postID + src));
  }
}
