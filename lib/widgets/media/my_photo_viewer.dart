import 'dart:typed_data';
import 'package:ctrim_app/utility/local_data_manager.dart';
import 'package:ctrim_app/utility/network_image_helper.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class MyPhotoViewer extends StatelessWidget {
  const MyPhotoViewer({super.key, required this.src, required this.postID, required this.onLockTap});
  final String src;
  final String postID;
  final Function onLockTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _getCachedImage(),
      builder: (context, snapshot) {
        final ImageProvider image;

        if (snapshot.hasData && snapshot.data != null) {
          // Use cached image from Hive
          image = MemoryImage(snapshot.data!);
        } else {
          // Fall back to network image with CORS support
          image = NetworkImage(NetworkImageHelper.getImageUrl(src));
        }

        return InkWell(
          onTap: () {
            onLockTap();
          },
          child: PhotoView(
            imageProvider: image,
            heroAttributes: PhotoViewHeroAttributes(tag: postID + src),
            loadingBuilder: (context, event) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return const SizedBox.shrink();
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Failed to load image'),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<Uint8List?> _getCachedImage() async {
    final localDataManager = LocalDataManager();
    final sanitisedKey = src.replaceAll(RegExp(r'[^\w]'), '');
    return await localDataManager.readMediaImage(sanitisedKey);
  }
}
