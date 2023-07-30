import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class MyPhotoViewer extends StatelessWidget {
  const MyPhotoViewer({super.key, required this.src, required this.heroPrefix});
  final String src;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    return PhotoView(imageProvider: NetworkImage(src), heroAttributes: PhotoViewHeroAttributes(tag: heroPrefix + src));
  }
}
