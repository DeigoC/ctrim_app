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
      return _wrapHero(_buildErrorState());
    }

    final peeked = CachedImageLoader.peekBytes(widget.imageUrl);
    if (peeked != null) {
      return _wrapHero(_imageFromBytes(peeked));
    }

    return _wrapHero(
      FutureBuilder<Uint8List>(
        future: _fetchCachedImage(),
        builder: (_, snap) {
          Widget result = _buildLoadingState();

          if (snap.hasData) {
            // Hoist the loaded photo to be the Hero child (not this FutureBuilder)
            // so the next navigation can fly the picture.
            if (CachedImageLoader.peekBytes(widget.imageUrl) != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }
            return _imageFromBytes(snap.data!);
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
      ),
    );
  }

  /// Keeps the [Hero] in the tree on the first frame. The shuttle uses the
  /// photo already on screen so a placeholder does not fly across.
  Widget _wrapHero(final Widget child) {
    final tag = widget.heroTag;
    if (tag == null || tag.isEmpty) return child;
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      flightShuttleBuilder: (
        context,
        animation,
        direction,
        fromContext,
        toContext,
      ) {
        // A new image, not the route's child. On pop that child is replaced
        // by an empty placeholder, so reusing it leaves nothing to fly.
        final bytes = CachedImageLoader.peekBytes(widget.imageUrl);
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }
        final outgoing = fromContext.widget;
        if (outgoing is Hero) return outgoing.child;
        return child;
      },
      child: child,
    );
  }

  Widget _imageFromBytes(final Uint8List bytes) {
    return Image.memory(
      bytes,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      alignment: widget.alignment,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Broken image data detected: ${error.toString()}');

        if (_retryCount < _maxRetries) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            CachedImageLoader.forgetBytes(widget.imageUrl);
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
        }
        _hasError = true;
        return _buildErrorState();
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
      _remember(imageUrl, cachedImage);
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
      _remember(imageUrl, imageBytes);
      return imageBytes;
    } catch (e) {
      debugPrint('Error downloading image: $e');
      forgetBytes(imageUrl);
      await localDataManager.deleteMediaImage(sanitisedKey);
      rethrow;
    }
  }

  static final Map<String, Uint8List> _memoryBytes = {};

  /// Bytes already shown this session, so a second widget can paint a [Hero]
  /// on its first frame.
  static Uint8List? peekBytes(final String imageUrl) {
    final bytes = _memoryBytes[cacheKeyFor(imageUrl)];
    if (bytes == null || bytes.isEmpty) return null;
    return bytes;
  }

  static void forgetBytes(final String imageUrl) {
    _memoryBytes.remove(cacheKeyFor(imageUrl));
  }

  static void _remember(final String imageUrl, final Uint8List bytes) {
    if (bytes.isEmpty) return;
    _memoryBytes[cacheKeyFor(imageUrl)] = bytes;
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
