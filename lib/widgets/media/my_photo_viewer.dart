import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class MyPhotoViewer extends StatelessWidget {
  const MyPhotoViewer({super.key, required this.src});
  final String src;

  @override
  Widget build(BuildContext context) {
    return PhotoView(imageProvider: NetworkImage(src));
  }
}
