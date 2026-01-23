import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utility/local_data_manager.dart';
import '../../utility/network_image_helper.dart';

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

    return FutureBuilder<Uint8List>(
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

  Widget _buildExistingThumbnail(final Uint8List thumbnail) {
    return InkWell(
        onTap: widget.onTap,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(
            child: Image.memory(
              thumbnail,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Broken video thumbnail detected: ${error.toString()}');

                if (_retryCount < _maxRetries) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await _deleteThumbnailCache();
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
  Future<Uint8List> _attemptToGetOrFetchThumbnail() async {
    final localDataManager = LocalDataManager();
    final String videoKey = _removeSpecialCharacters(widget.mediaEntry['src']!);

    // Check if thumbnail exists in cache
    final cachedThumbnail = await localDataManager.readVideoThumbnail(widget.postId, videoKey);
    if (cachedThumbnail != null && cachedThumbnail.isNotEmpty) {
      debugPrint('Using cached video thumbnail for: ${widget.postId}/$videoKey');
      return cachedThumbnail;
    }

    // Fetch thumbnail
    final String? thumbSrc = widget.mediaEntry['thumbnailSrc'];
    if (thumbSrc == null || thumbSrc.isEmpty) {
      debugPrint('No thumbnail source provided for video');
      throw Exception('No thumbnail source available');
    }

    debugPrint('Downloading video thumbnail: $thumbSrc');

    try {
      final thumbnailUrl = NetworkImageHelper.getImageUrl(thumbSrc);
      final response = await http.get(
        Uri.parse(thumbnailUrl),
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

      final thumbnailBytes = response.bodyBytes;

      if (thumbnailBytes.isEmpty) {
        throw Exception('Downloaded thumbnail is empty');
      }

      // Cache the thumbnail
      await localDataManager.writeVideoThumbnail(widget.postId, videoKey, thumbnailBytes);
      debugPrint('Cached video thumbnail for: ${widget.postId}/$videoKey');

      return thumbnailBytes;
    } catch (e) {
      debugPrint('Error downloading video thumbnail: $e');
      // Clean up partial cache if it exists
      await localDataManager.deleteVideoThumbnail(widget.postId, videoKey);
      rethrow;
    }
  }

  Future<void> _deleteThumbnailCache() async {
    final localDataManager = LocalDataManager();
    final String videoKey = _removeSpecialCharacters(widget.mediaEntry['src']!);
    debugPrint('Deleting corrupted video thumbnail: ${widget.postId}/$videoKey');
    await localDataManager.deleteVideoThumbnail(widget.postId, videoKey);
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
