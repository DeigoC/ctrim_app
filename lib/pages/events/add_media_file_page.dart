import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/app_dialog.dart';
import 'add_media_drive_helpers.dart';
import 'add_media_image_test.dart';
import 'add_media_source_form.dart';
import 'add_media_video_test.dart';

class AddMediaFilePage extends StatefulWidget {
  const AddMediaFilePage({
    super.key,
    required this.eventContext,
    this.initialIsVideo = false,

    /// When true, pops with the tested/sanitised media map instead of
    /// writing into [eventContext.media] (used by template media pools).
    this.returnResultOnly = false,
  });
  final EventContext eventContext;
  final bool initialIsVideo;
  final bool returnResultOnly;

  @override
  State<AddMediaFilePage> createState() => _AddMediaFilePageState();
}

class _AddMediaFilePageState extends State<AddMediaFilePage> {
  final TextEditingController _tecSrc = TextEditingController(),
      _tecThumbnailSrc = TextEditingController();
  final FocusNode _srcFocusNode = FocusNode();
  final int _maxImageSizeKB = 1536; // 1.5mb
  final int _maxVideoSizeMB = 128;
  VideoPlayerController? _videoPlayerController;
  bool _canSave = false,
      _canTestSrc = false,
      _isVideo = false,
      _isTesting = false;
  bool _allowPop = false;
  bool _isSaved = false;
  String _src = '';
  File? _tmpFile;
  int? _mediaFileSizeBytes;

  void _popRouteAfterAllowing({Object? result}) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  bool _hasUnsavedChanges() {
    return _tecSrc.text.trim().isNotEmpty ||
        _tecThumbnailSrc.text.trim().isNotEmpty ||
        _canSave ||
        _isTesting;
  }

  @override
  void initState() {
    super.initState();
    _isVideo = widget.initialIsVideo;
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      debugPrint('Disposing the video player!');
      _videoPlayerController!.dispose();
    }
    _srcFocusNode.dispose();
    _tecSrc.dispose();
    _tecThumbnailSrc.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _allowPop || _isSaved,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowPop || _isSaved) return;
        if (!_hasUnsavedChanges()) {
          _popRouteAfterAllowing();
          return;
        }
        final shouldPop = await DialogManager.discardChanges(context: context);
        if (shouldPop && mounted) {
          _popRouteAfterAllowing();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(_isVideo ? 'Add video' : 'Add image'),
          backgroundColor: colorScheme.surface,
          actions: [
            if (_canSave)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilledButton.tonalIcon(
                  onPressed: _onSaveClick,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.tertiaryContainer,
                    foregroundColor: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            IconButton(
                onPressed: _showHelp,
                icon: const Icon(Icons.help_outline),
                tooltip: 'Help'),
            const SizedBox(width: 4),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double webHorizontalPadding = ResponsiveLayout.horizontalGutter(
        MediaQuery.sizeOf(context).width,
        narrowPadding: 16);

    return SingleChildScrollView(
      padding:
          EdgeInsets.symmetric(vertical: 16, horizontal: webHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '1. Paste a public URL  ·  2. Choose type  ·  3. Test & preview  ·  4. Add',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Media Preview Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: _buildMediaTestSlot(),
            ),
          ),
          const SizedBox(height: 16),
          AddMediaSourceForm(
            srcController: _tecSrc,
            thumbnailController: _tecThumbnailSrc,
            srcFocusNode: _srcFocusNode,
            isVideo: _isVideo,
            maxImageSizeKB: _maxImageSizeKB,
            maxVideoSizeMB: _maxVideoSizeMB,
            onSrcChanged: _onSrcTextChange,
            onSrcTap: _pasteMediaUrlFromClipboardIfEmpty,
            onClearSrc: _onClearMediaSrc,
            onPasteSrc: _pasteMediaUrlFromClipboardIfEmpty,
            onIsVideoChange: _onIsVideoChange,
            onClearThumbnail: _onClearThumbnailSrc,
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _canTestSrc && !_isTesting ? _onTestSrcClick : null,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.preview),
                  label: Text(_isTesting ? 'Testing...' : 'Test & Preview'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _canSave ? _onSaveClick : null,
            icon: const Icon(Icons.add),
            label: Text(_addButtonLabel),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMediaTestSlot() {
    if (!_isTesting) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Media Preview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a URL and test to see preview',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isVideo ? _buildVideoPlayerTest() : _buildImageTest(),
      ),
    );
  }

  Widget _buildImageTest() {
    return AddMediaImageTest(
      canSave: _canSave,
      getSrc: () => _src,
      getInputUrl: () => _tecSrc.text,
      maxImageSizeKB: _maxImageSizeKB,
      fetchFile: () => _fetchFile(true),
      mediaFileSizeBytes: () => _mediaFileSizeBytes,
      onFetched: (file) {
        _canTestSrc = true;
        _tmpFile = file;
      },
      onReadyToSave: () {
        setState(() {
          _canSave = true;
        });
      },
      onFileTooLarge: () {
        _canSave = false;
        _canTestSrc = true;
      },
      onFetchFailed: () {
        _canTestSrc = true;
      },
    );
  }

  Widget _buildVideoPlayerTest() {
    return AddMediaVideoPlayerTest(
      canSave: _canSave,
      getSrc: () => _src,
      getInputUrl: () => _tecSrc.text,
      maxVideoSizeMB: _maxVideoSizeMB,
      fetchFile: () => _fetchFile(false),
      mediaFileSizeBytes: () => _mediaFileSizeBytes,
      videoPlayerController: _videoPlayerController,
      isVideo: _isVideo,
      onFetched: (file) {
        _canTestSrc = true;
        _tmpFile = file;
      },
      onControllerCreated: (controller) {
        _videoPlayerController = controller;
      },
      onVideoReady: () {
        setState(() {
          _canSave = true;
          _videoPlayerController!.play();
        });
      },
      onVideoInitFailed: () {
        setState(() {
          _canTestSrc = true;
        });
      },
      onFileTooLarge: () {
        _canTestSrc = true;
        _canSave = false;
      },
      onFetchFailed: () {
        _canTestSrc = true;
      },
    );
  }

  // * Logic

  Future<File?> _fetchFile(final bool isImage) async {
    if (kIsWeb) {
      // On web, just validate the URL and check file size via HEAD request
      return await _validateMediaOnWeb(isImage);
    }

    // Native platforms: download and cache
    try {
      final dir = await getTemporaryDirectory();
      _src = _sanitiseSrc();
      final srcUrl = NetworkImageHelper.getImageUrl(_src);
      debugPrint('Fetching from: $srcUrl');

      final String type = isImage ? '.png' : '.mp4';
      final String tmpPath = '${dir.path}/tmp$type';
      final File tmp = File(tmpPath);

      if (await tmp.exists()) {
        debugPrint('Removing existing temp file');
        await tmp.delete();
      }

      final response = await http.get(
        Uri.parse(srcUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Media-Fetcher/1.0)',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _mediaFileSizeBytes = response.bodyBytes.length;
        return await tmp.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: Failed to fetch media file');
      }
    } catch (e) {
      debugPrint('Error fetching file: $e');
      rethrow;
    }
  }

  /// Validate media on web without writing a temp file.
  ///
  /// Uses GET (not HEAD) and no custom headers: Flutter web's browser client
  /// often fails CORS preflight when sending User-Agent / HEAD to the proxy.
  Future<File?> _validateMediaOnWeb(bool isImage) async {
    try {
      _src = _sanitiseSrc();
      final srcUrl = NetworkImageHelper.getImageUrl(_src);
      debugPrint('Validating web media from: $srcUrl');

      final response = await http
          .get(Uri.parse(srcUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _mediaFileSizeBytes = response.bodyBytes.length;
        debugPrint('Media size on web: $_mediaFileSizeBytes bytes');
        return null; // Web mode: no local file cache
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: Failed to validate media');
      }
    } catch (e) {
      debugPrint('Error validating media on web: $e');
      rethrow;
    }
  }

  void _onClearMediaSrc() {
    setState(() {
      _canTestSrc = true;
      _tecSrc.clear();
    });
  }

  /// On tap / paste icon: fill from clipboard when the field is empty.
  Future<void> _pasteMediaUrlFromClipboardIfEmpty() async {
    if (_tecSrc.text.trim().isNotEmpty) return;

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) return;
      if (!isValidMediaUrl(text) && !driveShareLinkRegExp.hasMatch(text)) {
        return;
      }

      _tecSrc.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      _onSrcTextChange(text);
    } catch (e) {
      debugPrint('Clipboard paste failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not read clipboard. Paste manually (⌘V / Ctrl+V).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onClearThumbnailSrc() {
    setState(() {
      _tecThumbnailSrc.clear();
    });
  }

  void _onSaveClick() {
    final String mediaKind = _isVideo ? 'video' : 'image';
    final String confirmMessage = widget.returnResultOnly
        ? 'Add this $mediaKind to the template media pool?'
        : 'Save this $mediaKind to the event media?';

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AppDialog(
          icon: Icons.save_outlined,
          title: widget.returnResultOnly ? 'Add Media' : 'Save Media',
          message: confirmMessage,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isVideo ? Icons.videocam : Icons.image,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Type: ${_isVideo ? 'Video' : 'Image'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Source: ${_src.length > 50 ? '${_src.substring(0, 47)}...' : _src}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          actions: AppDialogActions(
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () {
              final Map<String, dynamic> data = {
                'title': '',
                'src': _src,
                'type': _isVideo ? 'vid' : 'img',
              };
              final thumbnail = sanitiseMediaUrl(_tecThumbnailSrc.text);
              if (_isVideo && thumbnail.isNotEmpty) {
                data['thumbnailSrc'] = thumbnail;
              }

              if (widget.returnResultOnly) {
                Navigator.of(context).pop();
                _isSaved = true;
                _popRouteAfterAllowing(result: data);
                return;
              }

              widget.eventContext.media.addMediaFile(data);
              Navigator.of(context).pop();
              _isSaved = true;
              _popRouteAfterAllowing();
            },
            confirmLabel: widget.returnResultOnly ? 'Add' : 'Save',
          ),
        );
      },
    );
  }

  void _onTestSrcClick() {
    setState(() {
      if (_videoPlayerController != null) {
        _videoPlayerController!.pause();
        _videoPlayerController!.dispose();
        _videoPlayerController = null;
      }
      _src = '';
      _canSave = false;
      _tmpFile = null;
      _mediaFileSizeBytes = null;
      _isTesting = true;
      _canTestSrc = false;
    });
  }

  void _onSrcTextChange(String newText) {
    setState(() {
      final trimmedText = newText.trim();

      if (trimmedText.isEmpty) {
        _canTestSrc = false;
      } else {
        _canTestSrc = isValidMediaUrl(trimmedText) ||
            driveShareLinkRegExp.hasMatch(trimmedText);
      }

      // Reset states when URL changes
      if (_isTesting) {
        _isTesting = false;
        _canSave = false;
        _tmpFile = null;
        _mediaFileSizeBytes = null;
        if (_videoPlayerController != null) {
          _videoPlayerController!.dispose();
          _videoPlayerController = null;
        }
      }
    });
  }

  void _onIsVideoChange(bool newState) {
    setState(() {
      _isVideo = newState;
    });
  }

  String get _addButtonLabel {
    if (widget.returnResultOnly) {
      return _isVideo ? 'Add video to pool' : 'Add image to pool';
    }
    return _isVideo ? 'Add video to gallery' : 'Add image to gallery';
  }

  String _sanitiseSrc() => sanitiseMediaUrl(_tecSrc.text);

  void _showHelp() {
    DialogManager.showAlertDialog(
      context: context,
      icon: Icons.help_outline,
      title: 'Adding Media Files',
      content: 'Supported sources\n'
          '• Direct HTTPS URLs to images/videos\n'
          '• Google Drive public links\n'
          '• Any publicly accessible media URL\n\n'
          'File size limits\n'
          '• Images: Maximum $_maxImageSizeKB KB\n'
          '• Videos: Maximum $_maxVideoSizeMB MB\n\n'
          'Google Drive setup\n'
          '1. Upload file to Google Drive\n'
          '2. Right-click → Share\n'
          '3. Change access to “Anyone with the link”\n'
          '4. Copy and paste the share link\n\n'
          'Tips\n'
          '• Test your URL before saving\n'
          '• For videos, add a thumbnail for better preview\n'
          '• Compress large files using the suggested tools',
    );
  }
}
