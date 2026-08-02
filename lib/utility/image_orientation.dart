import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Visual orientation of a raster image for layout decisions.
enum ImageOrientation {
  portrait,
  landscape,
  square,
}

abstract final class ImageOrientationHelper {
  /// Classifies by width/height. Slight square tolerance avoids flip-flopping.
  static ImageOrientation fromSize(final double width, final double height) {
    if (width <= 0 || height <= 0) {
      return ImageOrientation.landscape;
    }
    final ratio = width / height;
    if (ratio < 0.92) {
      return ImageOrientation.portrait;
    }
    if (ratio > 1.08) {
      return ImageOrientation.landscape;
    }
    return ImageOrientation.square;
  }

  static ImageOrientation fromPixelSize(final int width, final int height) {
    return fromSize(width.toDouble(), height.toDouble());
  }

  /// Decodes via [MemoryImage] so EXIF orientation is applied (phone portraits).
  static Future<Size?> decodeSize(final Uint8List bytes) async {
    if (bytes.isEmpty) {
      return null;
    }

    final provider = MemoryImage(bytes);
    final stream = provider.resolve(const ImageConfiguration());
    final completer = Completer<Size?>();

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) {
          completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()),
          );
        }
        stream.removeListener(listener);
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    return completer.future;
  }

  static Future<ImageOrientation> orientationFromBytes(
      final Uint8List bytes) async {
    final size = await decodeSize(bytes);
    if (size == null) {
      return ImageOrientation.landscape;
    }
    return fromSize(size.width, size.height);
  }

  /// Fits [intrinsic] inside [maxWidth] x [maxHeight] while keeping aspect ratio.
  static Size fitWithin({
    required Size intrinsic,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (intrinsic.width <= 0 || intrinsic.height <= 0) {
      return Size(maxWidth, maxHeight * 0.4);
    }

    final aspect = intrinsic.width / intrinsic.height;
    var width = maxWidth;
    var height = width / aspect;

    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspect;
    }

    return Size(width, height);
  }
}
