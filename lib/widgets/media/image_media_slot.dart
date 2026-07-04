import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../utility/local_data_manager.dart';
import '../../utility/network_image_helper.dart';

class ImageMediaSlot extends StatefulWidget {
  const ImageMediaSlot({super.key, required this.mediaEntry, required this.onTap, required this.postID});
  final Map<String, dynamic> mediaEntry;
  final Function()? onTap;
  final String postID;

  @override
  State<ImageMediaSlot> createState() => _ImageMediaSlotState();
}

class _ImageMediaSlotState extends State<ImageMediaSlot> {
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return _buildCachedImage();
  }

  Widget _buildCachedImage() {
    if (_hasError && _retryCount >= _maxRetries) {
      return _buildErrorState();
    }

    return FutureBuilder<Uint8List>(
        future: _fetchCachedImage(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            return InkWell(
                onTap: widget.onTap,
                child: Hero(
                    tag: widget.postID + widget.mediaEntry['src']!,
                    child: Image.memory(
                      snap.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Broken image data detected: ${error.toString()}');

                        // Only retry if we haven't exceeded max retries
                        if (_retryCount < _maxRetries) {
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            await _deleteCachedImage();
                            if (mounted) {
                              setState(() {
                                _retryCount++;
                                debugPrint('Retrying image download (attempt $_retryCount/$_maxRetries)');
                              });
                            }
                          });
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Retrying...', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        } else {
                          _hasError = true;
                          return _buildErrorState();
                        }
                      },
                    )));
          } else if (snap.hasError) {
            debugPrint('Image download error: ${snap.error}');
            _hasError = true;

            if (_retryCount < _maxRetries) {
              // Attempt retry after a short delay
              Future.delayed(Duration(seconds: _retryCount + 1), () {
                if (mounted) {
                  setState(() {
                    _retryCount++;
                    debugPrint('Retrying image download after error (attempt $_retryCount/$_maxRetries)');
                  });
                }
              });
              result = _buildLoadingState();
            } else {
              result = _buildErrorState();
            }
          }

          return result;
        });
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (_retryCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Attempt $_retryCount/$_maxRetries',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
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
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                _retryCount >= _maxRetries ? 'Failed to load' : 'Tap to retry',
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
  Future<Uint8List> _fetchCachedImage() async {
    final localDataManager = LocalDataManager();
    final sanitisedKey = widget.mediaEntry['src']!.replaceAll(RegExp(r'[^\w]'), '');

    // Check if image exists in cache
    final cachedImage = await localDataManager.readMediaImage(sanitisedKey);
    if (cachedImage != null && cachedImage.isNotEmpty) {
      debugPrint('Using cached image for: $sanitisedKey');
      return cachedImage;
    }

    // Download and cache the image
    debugPrint('Downloading image for: $sanitisedKey');
    try {
      final imageUrl = NetworkImageHelper.getImageUrl(widget.mediaEntry['src']!);
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {'Accept': 'image/*'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Image download timed out after 30 seconds');
        },
      );

      if (response.statusCode != 200) {
        throw HttpException('Failed to download image: HTTP ${response.statusCode}');
      }

      final imageBytes = response.bodyBytes;

      if (imageBytes.isEmpty) {
        throw Exception('Downloaded image is empty');
      }

      // Cache the image
      await localDataManager.writeMediaImage(sanitisedKey, imageBytes);
      debugPrint('Cached image for: $sanitisedKey');

      return imageBytes;
    } catch (e) {
      debugPrint('Error downloading image: $e');
      // Clean up partial cache if it exists
      await localDataManager.deleteMediaImage(sanitisedKey);
      rethrow;
    }
  }

  Future<void> _deleteCachedImage() async {
    final localDataManager = LocalDataManager();
    final sanitisedKey = widget.mediaEntry['src']!.replaceAll(RegExp(r'[^\w]'), '');
    debugPrint('Deleting corrupted/broken cached image: $sanitisedKey');
    await localDataManager.deleteMediaImage(sanitisedKey);
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
