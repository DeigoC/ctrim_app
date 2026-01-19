import 'dart:io';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/network_image_helper.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class MyPhotoViewer extends StatelessWidget {
  const MyPhotoViewer({super.key, required this.src, required this.postID, required this.onLockTap});
  final String src;
  final String postID;
  final Function onLockTap;

  // in theory the file already exists in cache
  @override
  Widget build(BuildContext context) {
    final String? cacheDir = Provider.of<AppContext>(context, listen: false).cacheDir;
    final sanitisedFilePath = src.replaceAll(RegExp(r'[^\w]'), '');
    final fullPath = '$cacheDir/$sanitisedFilePath.png';
    final file = File(fullPath);

    final ImageProvider image =
        (file.existsSync() ? FileImage(file) : NetworkImage(NetworkImageHelper.getImageUrl(src))) as ImageProvider;
    return InkWell(
      onTap: () {
        // debugPrint('tap once');
        onLockTap();
      },
      child: PhotoView(
        imageProvider: image,
        heroAttributes: PhotoViewHeroAttributes(tag: postID + src),
        errorBuilder: (context, error, stackTrace) {
          // ? Technically the image media slot will be the one trying to do the fixing.
          // once that is done, the file should be fixed?
          return const Center(child: Text('The image is broken, will try to fetch and rebuild later'));
        },
      ),
    );
  }
}
