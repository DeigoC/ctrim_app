import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../utility/cache/local_data_manager.dart';
import '../../utility/network_image_helper.dart';

/// A widget that downloads and caches images for display.
/// Used for info pages (churches, testimonials, etc.)
class CachedImageWidget extends StatefulWidget {
  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.heroTag,
  });

  /// URL to download the image from
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Alignment alignment;
  final String? heroTag;

  @override
  State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
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
        Widget result = _buildLoadingState();

        if (snap.hasData) {
          final image = Image.memory(
            snap.data!,
            height: widget.height,
            width: widget.width,
            fit: widget.fit,
            alignment: widget.alignment,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Broken image data detected: ${error.toString()}');

              // Only retry if we haven't exceeded max retries
              if (_retryCount < _maxRetries) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await _deleteCachedImage();
                  if (mounted) {
                    setState(() {
                      _retryCount++;
                      debugPrint(
                          'Retrying image download (attempt $_retryCount/$_maxRetries)');
                    });
                  }
                });
                return _buildLoadingState();
              } else {
                _hasError = true;
                return _buildErrorState();
              }
            },
          );

          if (widget.heroTag != null) {
            return Hero(tag: widget.heroTag!, child: image);
          }
          return image;
        } else if (snap.hasError) {
          debugPrint('Image download error: ${snap.error}');
          _hasError = true;

          if (_retryCount < _maxRetries) {
            // Attempt retry after a short delay
            Future.delayed(Duration(seconds: _retryCount + 1), () {
              if (mounted) {
                setState(() {
                  _retryCount++;
                  debugPrint(
                      'Retrying image download after error (attempt $_retryCount/$_maxRetries)');
                });
              }
            });
            result = _buildLoadingState();
          } else {
            result = _buildErrorState();
          }
        }

        return result;
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: widget.height,
      width: widget.width,
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
        height: widget.height,
        width: widget.width,
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
  Future<Uint8List> _fetchCachedImage() =>
      CachedImageLoader.fetchBytes(widget.imageUrl);

  Future<void> _deleteCachedImage() async {
    final localDataManager = LocalDataManager();
    final sanitisedKey = CachedImageLoader.cacheKeyFor(widget.imageUrl);
    debugPrint('Deleting corrupted/broken cached image: $sanitisedKey');
    await localDataManager.deleteMediaImage(sanitisedKey);
  }
}

/// Shared download/cache path used by [CachedImageWidget] and orientation probes.
abstract final class CachedImageLoader {
  static String cacheKeyFor(final String imageUrl) {
    return imageUrl.replaceAll(RegExp(r'[^\w]'), '');
  }

  static Future<Uint8List> fetchBytes(final String imageUrl) async {
    final localDataManager = LocalDataManager();
    final sanitisedKey = cacheKeyFor(imageUrl);

    final cachedImage = await localDataManager.readMediaImage(sanitisedKey);
    if (cachedImage != null && cachedImage.isNotEmpty) {
      debugPrint('Using cached image for: $sanitisedKey');
      return cachedImage;
    }

    debugPrint('Downloading image from: $imageUrl');
    try {
      final resolvedUrl = NetworkImageHelper.getImageUrl(imageUrl);
      final response = await http.get(
        Uri.parse(resolvedUrl),
        headers: {'Accept': 'image/*'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Image download timed out after 30 seconds');
        },
      );

      if (response.statusCode != 200) {
        throw HttpException(
            'Failed to download image: HTTP ${response.statusCode}');
      }

      final imageBytes = response.bodyBytes;
      if (imageBytes.isEmpty) {
        throw Exception('Downloaded image is empty');
      }

      await localDataManager.writeMediaImage(sanitisedKey, imageBytes);
      debugPrint('Cached image for: $sanitisedKey');
      return imageBytes;
    } catch (e) {
      debugPrint('Error downloading image: $e');
      await localDataManager.deleteMediaImage(sanitisedKey);
      rethrow;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
