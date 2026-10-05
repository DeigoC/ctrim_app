import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'app_links.dart';
import 'quill_image.dart';

/// Plain text prepared for the open-post share sheet.
abstract final class PostShareText {
  static const String extractFailed = 'Unable to extract post content';

  /// Public permalink for [postId].
  static String link(String postId) => AppLinks.postUrl(postId);

  /// Title, permalink, then the About body as plain text.
  static String writeUp({
    required String title,
    required String postId,
    required List<dynamic> body,
    String extractFailedMessage = extractFailed,
  }) {
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln(link(postId))
      ..writeln('---')
      ..writeln();

    try {
      final document = quill.Document.fromJson(body);
      buffer.write(
        QuillImage.stripEmbedsFromPlainText(document.toPlainText()),
      );
    } catch (_) {
      buffer.write(extractFailedMessage);
    }
    return buffer.toString();
  }
}
