import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utility/app_context.dart';
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
    final String? cacheDir = Provider.of<AppContext>(context, listen: false).cacheDir;

    // most likely on the webapp
    if (cacheDir == null) {
      return _buildNetworkImage();
    }
    return _buildFileImage(cacheDir);
  }

  Widget _buildFileImage(final String cacheDir) {
    if (_hasError && _retryCount >= _maxRetries) {
      return _buildErrorState();
    }

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
                        debugPrint('Broken image file detected: ${error.toString()}');

                        // Only retry if we haven't exceeded max retries
                        if (_retryCount < _maxRetries) {
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            await _deleteFile(cacheDir);
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

  Widget _buildNetworkImage() {
    return InkWell(
      onTap: widget.onTap,
      child: Image.network(
        NetworkImageHelper.getImageUrl(widget.mediaEntry['src']!),
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingState();
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Network image error: ${error.toString()}');
          return _buildErrorState();
        },
      ),
    );
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
        color: colorScheme.errorContainer.withOpacity(0.3),
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
  Future<File> _fetchFileImage(final String cacheDir) async {
    final sanitisedFilePath = widget.mediaEntry['src']!.replaceAll(RegExp(r'[^\w]'), '');
    final fullPath = '$cacheDir/tmpImages/$sanitisedFilePath.png';
    final file = File(fullPath);

    if (!await file.exists()) {
      debugPrint('Creating image file for: $fullPath');

      try {
        final response = await http.get(
          Uri.parse(widget.mediaEntry['src']!),
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

        // Ensure directory exists
        await file.parent.create(recursive: true);

        return await file.writeAsBytes(response.bodyBytes);
      } catch (e) {
        debugPrint('Error downloading image: $e');
        // Clean up partial file if it exists
        if (await file.exists()) {
          await file.delete();
        }
        rethrow;
      }
    }

    // Verify file is valid before returning
    if (await file.length() == 0) {
      debugPrint('Image file is empty, deleting and re-downloading');
      await file.delete();
      throw Exception('Cached image file was empty');
    }

    return file;
  }

  Future<bool> _deleteFile(final String cacheDir) async {
    final sanitisedFilePath = widget.mediaEntry['src']!.replaceAll(RegExp(r'[^\w]'), '');
    final fullPath = '$cacheDir/tmpImages/$sanitisedFilePath.png';
    final file = File(fullPath);
    if (await file.exists()) {
      debugPrint('Deleting corrupted/broken image file: $fullPath');
      await file.delete();
    }
    return true;
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
