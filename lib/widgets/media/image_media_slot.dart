import 'dart:io';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImageMediaSlot extends StatefulWidget {
  const ImageMediaSlot({super.key, required this.mediaEntry, required this.onTap, required this.postID});
  final Map<String, String> mediaEntry;
  final Function()? onTap;
  final String postID;

  @override
  State<ImageMediaSlot> createState() => _ImageMediaSlotState();
}

class _ImageMediaSlotState extends State<ImageMediaSlot> {
  @override
  Widget build(BuildContext context) {
    final String? cacheDir = Provider.of<AppContext>(context, listen: false).cacheDir;

    // most likely on the webapp
    if (cacheDir == null) {
      // debugPrint('building network image');
      return _buildNetworkImage();
    }
    return _buildFileImage(cacheDir);
  }

  Widget _buildFileImage(final String cacheDir) {
    // this is a FB to allow the app to redownload on a broken file
    return FutureBuilder(
        future: _fetchFileImage(cacheDir),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            return InkWell(
                onTap: widget.onTap,
                child: Hero(
                    tag: widget.postID + widget.mediaEntry['src']!,
                    child: Image.file(
                      snap.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          debugPrint('broken image, will retry on rebuild');
                          _deleteFile(cacheDir);
                        });
                        return const Center(child: Text('The file is broken, will try again later'));
                      },
                    )));
          } else if (snap.hasError) {
            debugPrint('image error: ${snap.error}');
            result = const Center(child: Text('Something went wrong!'));
          }

          return result;
        });
  }

  Widget _buildNetworkImage() {
    return Image.network(widget.mediaEntry['src']!, fit: BoxFit.cover);
  }

  // * Logic

  Future<File> _fetchFileImage(final String cacheDir) async {
    final sanitisedFilePath = widget.mediaEntry['src']!.replaceAll(RegExp(r'[^\w]'), '');
    final fullPath = '$cacheDir/$sanitisedFilePath.png';
    final file = File(fullPath);

    if (!await file.exists()) {
      debugPrint('Creating image file for: $fullPath');
      final response = await http.get(Uri.parse(widget.mediaEntry['src']!));
      return await file.writeAsBytes(response.bodyBytes);
    }
    // debugPrint('using existing image file for: ${mediaEntry['src']!}');
    return file;
  }

  Future<bool> _deleteFile(final String cacheDir) async {
    final sanitisedFilePath = widget.mediaEntry['src']!.replaceAll(RegExp(r'[^\w]'), '');
    final fullPath = '$cacheDir/$sanitisedFilePath.png';
    final file = File(fullPath);
    if (await file.exists()) {
      debugPrint('deleting file');
      await file.delete();
    }
    return true;
  }
}
