import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../utility/network_image_helper.dart';
import 'add_media_test_states.dart';

class AddMediaImageTest extends StatelessWidget {
  const AddMediaImageTest({
    super.key,
    required this.canSave,
    required this.getSrc,
    required this.getInputUrl,
    required this.maxImageSizeKB,
    required this.fetchFile,
    required this.mediaFileSizeBytes,
    required this.onFetched,
    required this.onReadyToSave,
    required this.onFileTooLarge,
    required this.onFetchFailed,
  });

  final bool canSave;
  final String Function() getSrc;
  final String Function() getInputUrl;
  final int maxImageSizeKB;
  final Future<File?> Function() fetchFile;
  final int? Function() mediaFileSizeBytes;
  final void Function(File? tmpFile) onFetched;
  final VoidCallback onReadyToSave;
  final VoidCallback onFileTooLarge;
  final VoidCallback onFetchFailed;

  @override
  Widget build(BuildContext context) {
    if (canSave) {
      // On web or when ready, show the image from URL
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          NetworkImageHelper.getImageUrl(getSrc()),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return AddMediaTestError(
              message: 'Failed to load image: $error',
              src: getSrc(),
              inputUrl: getInputUrl(),
            );
          },
        ),
      );
    }

    return FutureBuilder(
      future: fetchFile(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AddMediaTestLoading(message: 'Checking image...');
        }

        final int? sizeBytes = mediaFileSizeBytes();
        if (snap.hasData || (kIsWeb && sizeBytes != null)) {
          onFetched(snap.data);

          final size = sizeBytes ?? (snap.data?.lengthSync() ?? 0);
          final double sizeInKb = size / 1024;

          if (sizeInKb <= maxImageSizeKB || sizeBytes == 0) {
            debugPrint('image size is good: $sizeInKb KB');
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              onReadyToSave();
            });
            return AddMediaTestSuccess(
                message: sizeBytes == 0
                    ? 'Image is ready! (Size validation skipped on web)'
                    : 'Image is ready! Size: ${sizeInKb.toStringAsFixed(1)} KB');
          } else {
            onFileTooLarge();
            return AddMediaTestFileSizeError(
              title: 'Image too large: ${sizeInKb.toStringAsFixed(1)} KB',
              subtitle:
                  'Maximum size is $maxImageSizeKB KB. Please compress the image.',
              url: 'https://imagecompressor.com',
              buttonText: 'Compress Image Online',
            );
          }
        }

        if (snap.hasError) {
          onFetchFailed();
          debugPrint('Error fetching image: ${snap.error}');
          return AddMediaTestError(
            message: 'Failed to load image: ${snap.error}',
            src: getSrc(),
            inputUrl: getInputUrl(),
          );
        }

        return const AddMediaTestLoading(message: 'Preparing...');
      },
    );
  }
}
