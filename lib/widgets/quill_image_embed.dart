import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:http/http.dart' as http;

import '../utility/network_image_helper.dart';
import '../utility/quill_image.dart';
import 'common/app_dialog.dart';

List<quill.EmbedBuilder> quillEmbedBuilders() {
  return const <quill.EmbedBuilder>[
    QuillImageEmbedBuilder(),
  ];
}

/// Renders `{image: url}` embeds with Drive sanitisation and the CORS proxy.
class QuillImageEmbedBuilder extends quill.EmbedBuilder {
  const QuillImageEmbedBuilder();

  @override
  String get key => quill.BlockEmbed.imageType;

  @override
  String toPlainText(final quill.Embed node) => '';

  @override
  Widget build(
    final BuildContext context,
    final quill.EmbedContext embedContext,
  ) {
    final raw = embedContext.node.value.data;
    final url = QuillImage.sanitizeUrl(raw is String ? raw : raw.toString());
    return QuillNetworkImage(url: url);
  }
}

/// Avoids [UnimplementedError] if a body contains an unknown embed type.
class QuillUnsupportedEmbedBuilder extends quill.EmbedBuilder {
  const QuillUnsupportedEmbedBuilder();

  @override
  String get key => 'unsupported';

  @override
  Widget build(
    final BuildContext context,
    final quill.EmbedContext embedContext,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Unsupported content',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Network image used inside the editor and read-only viewer.
class QuillNetworkImage extends StatelessWidget {
  const QuillNetworkImage({super.key, required this.url});

  final String url;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!QuillImage.isHttpUrl(url)) {
      return _broken(colorScheme, 'Missing image URL');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Image.network(
            NetworkImageHelper.getImageUrl(url),
            width: double.infinity,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) {
                return child;
              }
              return SizedBox(
                height: 160,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) =>
                _broken(colorScheme, 'Could not load image'),
          ),
        ),
      ),
    );
  }

  Widget _broken(final ColorScheme colorScheme, final String message) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: colorScheme.error),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Future<void> insertQuillImageFromUrl({
  required final BuildContext context,
  required final quill.QuillController controller,
}) async {
  final url = await showQuillImageUrlDialog(context);
  if (url == null || !context.mounted) {
    return;
  }
  QuillImage.insertUrl(controller: controller, url: url);
}

/// URL-only image picker. Gallery and camera are not offered.
Future<String?> showQuillImageUrlDialog(final BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const QuillImageUrlDialog(),
  );
}

class QuillImageUrlDialog extends StatefulWidget {
  const QuillImageUrlDialog({super.key});

  @override
  State<QuillImageUrlDialog> createState() => QuillImageUrlDialogState();
}

class QuillImageUrlDialogState extends State<QuillImageUrlDialog> {
  final TextEditingController _urlController = TextEditingController();
  bool _testing = false;
  bool _testSucceeded = false;
  String? _errorMessage;
  String? _previewUrl;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String? get _sanitizedUrl =>
      QuillImage.trySanitizeHttpUrl(_urlController.text);

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sanitized = _sanitizedUrl;

    return AppDialog(
      icon: Icons.image_outlined,
      title: 'Insert image',
      message:
          'Paste a public HTTPS image URL. Google Drive share links are converted automatically.',
      actions: AppDialogActions(
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: _insert,
        confirmLabel: 'Insert',
        confirmIcon: Icons.add_photo_alternate_outlined,
        confirmEnabled: sanitized != null && !_testing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('quill-image-url-field'),
            controller: _urlController,
            autofocus: true,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: AppDialog.inputDecoration(
              label: 'Image URL',
              hint: 'https://…',
              prefixIcon: const Icon(Icons.link),
            ),
            onChanged: (_) {
              setState(() {
                _testSucceeded = false;
                _errorMessage = null;
                _previewUrl = null;
              });
            },
            onSubmitted: (_) => _insert(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _testing || sanitized == null ? null : _testUrl,
              icon: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.visibility_outlined),
              label: Text(_testing ? 'Testing…' : 'Test'),
            ),
          ),
          if (_previewUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Image.network(
                    NetworkImageHelper.getImageUrl(_previewUrl!),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (_testSucceeded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Image loaded successfully.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 16, color: colorScheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.error),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _testUrl() async {
    final sanitized = _sanitizedUrl;
    if (sanitized == null) {
      return;
    }

    setState(() {
      _testing = true;
      _testSucceeded = false;
      _errorMessage = null;
      _previewUrl = sanitized;
      if (_urlController.text.trim() != sanitized) {
        _urlController.text = sanitized;
      }
    });

    try {
      final imageUrl = NetworkImageHelper.getImageUrl(sanitized);
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      if (response.bodyBytes.isEmpty) {
        throw Exception('Empty response');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _testing = false;
        _testSucceeded = true;
        _errorMessage = null;
        _previewUrl = sanitized;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _testing = false;
        _testSucceeded = false;
        _errorMessage = _failureMessage(sanitized);
      });
    }
  }

  String _failureMessage(final String url) {
    if (url.contains('drive.google.com')) {
      return 'Could not load the image. For Google Drive, share as '
          '“Anyone with the link” (Viewer), then test again.';
    }
    return 'Could not load the image. Check the URL is a public HTTPS '
        'image link and try again.';
  }

  void _insert() {
    final sanitized = _sanitizedUrl;
    if (sanitized == null) {
      return;
    }
    Navigator.of(context).pop(sanitized);
  }
}
