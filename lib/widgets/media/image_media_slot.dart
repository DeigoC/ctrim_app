import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ImageMediaSlot extends StatelessWidget {
  const ImageMediaSlot({super.key, required this.mediaEntry, required this.onTap, required this.postID});
  final Map<String, String> mediaEntry;
  final Function()? onTap;
  final String postID;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _fetchImage(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            return InkWell(
                onTap: onTap,
                child: Hero(tag: postID + mediaEntry['src']!, child: Image.file(snap.data!, fit: BoxFit.cover)));
          } else if (snap.hasError) {
            debugPrint('image error: ${snap.error}');
            result = const Center(child: Text('Something went wrong!'));
          }

          return result;
        });
  }

  Future<File> _fetchImage() async {
    final dir = await getTemporaryDirectory();
    final sanitisedFilePath = mediaEntry['src']!.replaceAll(RegExp(r'[^\w]'), '');
    final fullPath = '${dir.path}/$sanitisedFilePath.png';
    final file = File(fullPath);

    if (!await file.exists()) {
      debugPrint('Creating image file for: $fullPath');
      final response = await http.get(Uri.parse(mediaEntry['src']!));
      return await file.writeAsBytes(response.bodyBytes);
    }
    // debugPrint('using existing image file for: ${mediaEntry['src']!}');
    return file;
  }
}
