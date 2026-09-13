import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'network_image_helper.dart';

/// URL-only image embeds for Quill body JSON.
///
/// Images are stored as `{insert: {image: '<https url>'}}`. Device uploads are
/// not supported — paste a public HTTPS or Google Drive share link.
abstract final class QuillImage {
  static const String embedType = 'image';

  /// Object Replacement Character that Quill uses for embeds in plain text.
  static const String embedPlainTextMarker = '\uFFFC';

  static String sanitizeUrl(final String raw) {
    return NetworkImageHelper.sanitizeMediaUrl(raw);
  }

  static bool isHttpUrl(final String url) {
    if (url.trim().isEmpty) {
      return false;
    }
    try {
      final uri = Uri.parse(url.trim());
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority;
    } catch (_) {
      return false;
    }
  }

  /// Drive share links become `uc?id=` first; returns null if not http(s).
  static String? trySanitizeHttpUrl(final String raw) {
    final sanitized = sanitizeUrl(raw);
    if (!isHttpUrl(sanitized)) {
      return null;
    }
    return sanitized;
  }

  /// Rewrite image embed URLs in a Quill delta so stored JSON matches display.
  static List<dynamic> sanitizeDeltaImageUrls(final List<dynamic> delta) {
    return [
      for (final op in delta)
        if (op is Map) _sanitizeOp(op) else op,
    ];
  }

  static Map<dynamic, dynamic> _sanitizeOp(final Map<dynamic, dynamic> op) {
    final insert = op['insert'];
    if (insert is! Map) {
      return op;
    }
    final image = insert['image'];
    if (image is! String) {
      return op;
    }
    final sanitized = sanitizeUrl(image);
    if (sanitized == image) {
      return op;
    }
    return <dynamic, dynamic>{
      ...op,
      'insert': <dynamic, dynamic>{
        ...insert,
        'image': sanitized,
      },
    };
  }

  static String stripEmbedsFromPlainText(final String text) {
    return text.replaceAll(embedPlainTextMarker, '').trim();
  }

  static void insertUrl({
    required final quill.QuillController controller,
    required final String url,
  }) {
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;
    controller
      ..skipRequestKeyboard = true
      ..replaceText(index, length, quill.BlockEmbed.image(url), null)
      ..moveCursorToPosition(index + 1);
  }
}
