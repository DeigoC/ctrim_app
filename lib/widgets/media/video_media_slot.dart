import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class VideoMediaSlot extends StatefulWidget {
  const VideoMediaSlot({super.key, required this.mediaEntry, required this.onTap, required this.postId});
  final String postId;
  final Map<String, dynamic> mediaEntry;
  final Function()? onTap;

  @override
  State<VideoMediaSlot> createState() => _VideoMediaSlotState();
}

class _VideoMediaSlotState extends State<VideoMediaSlot> {
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError && _retryCount >= _maxRetries) {
      return _buildErrorState();
    }

    return FutureBuilder(
        future: _attemptToGetOrFetchThumbnail(),
        builder: (_, snap) {
          if (snap.hasData) {
            return _buildExistingThumbnail(snap.data!);
          } else if (snap.hasError) {
            debugPrint('Video thumbnail error: ${snap.error}');
            _hasError = true;

            if (_retryCount < _maxRetries) {
              // Retry after delay
              Future.delayed(Duration(seconds: _retryCount + 1), () {
                if (mounted) {
                  setState(() {
                    _retryCount++;
                    _hasError = false;
                    debugPrint('Retrying video thumbnail (attempt $_retryCount/$_maxRetries)');
                  });
                }
              });
              return _buildLoadingState();
            } else {
              return _buildErrorState();
            }
          }

          return _buildLoadingState();
        });
  }

  Widget _buildExistingThumbnail(final File thumbnail) {
    return InkWell(
        onTap: widget.onTap,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(
            child: Image.file(
              thumbnail,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Broken video thumbnail detected: ${error.toString()}');

                if (_retryCount < _maxRetries) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await _deleteThumbnailFile();
                    if (mounted) {
                      setState(() {
                        _retryCount++;
                        debugPrint('Retrying video thumbnail after image error (attempt $_retryCount/$_maxRetries)');
                      });
                    }
                  });
                  return _buildLoadingState();
                } else {
                  return _buildErrorState();
                }
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.play_circle_filled, color: Colors.white, size: 48),
          ),
        ]));
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            if (_retryCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Attempt $_retryCount/$_maxRetries',
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _retryCount < _maxRetries
          ? () {
              if (mounted) {
                setState(() {
                  _hasError = false;
                  _retryCount++;
                });
              }
            }
          : null,
      child: Container(
        color: colorScheme.errorContainer.withOpacity(0.3),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                _retryCount >= _maxRetries ? 'Failed to load video' : 'Tap to retry',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // * Logic
  Future<File> _attemptToGetOrFetchThumbnail() async {
    final String title = _removeSpecialCharacters(widget.mediaEntry['src']!);
    final String path = '${(await getApplicationDocumentsDirectory()).path}/posts/${widget.postId}/$title.webp';
    final File imgFile = File(path);

    // Check if thumbnail exists and is valid
    if (await imgFile.exists()) {
      final fileSize = await imgFile.length();
      if (fileSize > 0) {
        debugPrint('Using existing video thumbnail: $path');
        return imgFile;
      } else {
        debugPrint('Existing thumbnail is empty, deleting and re-downloading');
        await imgFile.delete();
      }
    }

    // Fetch thumbnail
    final String? thumbSrc = widget.mediaEntry['thumbnailSrc'];
    if (thumbSrc == null || thumbSrc.isEmpty) {
      debugPrint('No thumbnail source provided for video');
      throw Exception('No thumbnail source available');
    }

    debugPrint('Downloading video thumbnail: $thumbSrc');

    try {
      final response = await http.get(
        Uri.parse(thumbSrc),
        headers: {'Accept': 'image/*'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Video thumbnail download timed out after 30 seconds');
        },
      );

      if (response.statusCode != 200) {
        throw HttpException('Failed to download thumbnail: HTTP ${response.statusCode}');
      }

      // Ensure directory exists
      await imgFile.parent.create(recursive: true);

      await imgFile.writeAsBytes(response.bodyBytes);
      debugPrint('Saved video thumbnail to: $path');

      return imgFile;
    } catch (e) {
      debugPrint('Error downloading video thumbnail: $e');
      // Clean up partial file if it exists
      if (await imgFile.exists()) {
        await imgFile.delete();
      }
      rethrow;
    }
  }

  Future<void> _deleteThumbnailFile() async {
    final String title = _removeSpecialCharacters(widget.mediaEntry['src']!);
    final String path = '${(await getApplicationDocumentsDirectory()).path}/posts/${widget.postId}/$title.webp';
    final File file = File(path);

    if (await file.exists()) {
      debugPrint('Deleting corrupted video thumbnail: $path');
      await file.delete();
    }
  }

  String _removeSpecialCharacters(final String webLink) {
    return webLink.replaceAll(RegExp(r'[^\w]'), '');
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
