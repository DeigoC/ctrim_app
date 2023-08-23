import 'dart:io';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImageMediaSlot extends StatelessWidget {
  const ImageMediaSlot({super.key, required this.mediaEntry, required this.onTap, required this.postID});
  final Map<String, String> mediaEntry;
  final Function()? onTap;
  final String postID;

  @override
  Widget build(BuildContext context) {
    final String? cacheDir = Provider.of<AppContext>(context, listen: false).cacheDir;

    // most likely on the webapp
    if (cacheDir == null) {
      debugPrint('building network image');
      return _buildNetworkImage();
    }

    return FutureBuilder(
        future: _fetchFileImage(cacheDir),
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

  Widget _buildNetworkImage() {
    return Image.network(mediaEntry['src']!, fit: BoxFit.cover);
  }

  Future<File> _fetchFileImage(final String cacheDir) async {
    final sanitisedFilePath = mediaEntry['src']!.replaceAll(RegExp(r'[^\w]'), '');
    final fullPath = '$cacheDir/$sanitisedFilePath.png';
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
