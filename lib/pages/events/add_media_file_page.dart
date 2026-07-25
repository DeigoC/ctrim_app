import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/video_player.dart';

import '../../utility/event_context.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/responsive_layout.dart';

class AddMediaFilePage extends StatefulWidget {
  const AddMediaFilePage({
    super.key,
    required this.eventContext,
    this.initialIsVideo = false,
  });
  final EventContext eventContext;
  final bool initialIsVideo;

  @override
  State<AddMediaFilePage> createState() => _AddMediaFilePageState();
}

class _AddMediaFilePageState extends State<AddMediaFilePage> {
  final TextEditingController _tecSrc = TextEditingController(), _tecThumbnailSrc = TextEditingController();
  final FocusNode _srcFocusNode = FocusNode();
  final RegExp _driveRegExp = RegExp(r"drive.google.com/file/d/([a-zA-Z0-9_-]+)");
  final int _maxImageSizeKB = 1536; // 1.5mb
  final int _maxVideoSizeMB = 128;
  VideoPlayerController? _videoPlayerController;
  bool _canSave = false, _canTestSrc = false, _isVideo = false, _isTesting = false;
  String _src = '';
  File? _tmpFile;
  int? _mediaFileSizeBytes;

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

    return Scaffold(
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
          IconButton(onPressed: _showHelp, icon: const Icon(Icons.help_outline), tooltip: 'Help'),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double webHorizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 16);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: webHorizontalPadding),
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
                  Icon(Icons.info_outline, size: 20, color: colorScheme.onPrimaryContainer),
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
              side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: _buildMediaTestSlot(),
            ),
          ),
          const SizedBox(height: 16),

          // URL Input Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.link, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Media source',
                        style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the field to paste a link from your clipboard. Google Drive share links are converted automatically.',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tecSrc,
                    focusNode: _srcFocusNode,
                    onChanged: _onSrcTextChange,
                    onTap: _pasteMediaUrlFromClipboardIfEmpty,
                    decoration: InputDecoration(
                      hintText: 'Tap to paste URL from clipboard',
                      label: const Text('Media URL*'),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(_isVideo ? Icons.videocam : Icons.image),
                      suffixIcon: _tecSrc.text.isNotEmpty
                          ? IconButton(
                              onPressed: _onClearMediaSrc,
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear URL',
                            )
                          : IconButton(
                              onPressed: _pasteMediaUrlFromClipboardIfEmpty,
                              icon: const Icon(Icons.content_paste),
                              tooltip: 'Paste from clipboard',
                            ),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 8),
                  _buildUrlValidationMessage(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Media Type Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.category_outlined, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Media type',
                        style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMediaTypeOption(
                          icon: Icons.image,
                          label: 'Image',
                          isSelected: !_isVideo,
                          onTap: () => _onIsVideoChange(false),
                          subtitle: 'Max $_maxImageSizeKB KB',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMediaTypeOption(
                          icon: Icons.videocam,
                          label: 'Video',
                          isSelected: _isVideo,
                          onTap: () => _onIsVideoChange(true),
                          subtitle: 'Max $_maxVideoSizeMB MB',
                        ),
                      ),
                    ],
                  ),
                  if (_isVideo) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tecThumbnailSrc,
                      decoration: InputDecoration(
                        hintText: 'https://example.com/thumbnail.jpg',
                        label: const Text('Video Thumbnail URL (Optional)'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.image),
                        suffixIcon: _tecThumbnailSrc.text.isNotEmpty
                            ? IconButton(
                                onPressed: _onClearThumbnailSrc,
                                icon: const Icon(Icons.clear),
                                tooltip: 'Clear thumbnail URL',
                              )
                            : null,
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _canTestSrc && !_isTesting ? _onTestSrcClick : null,
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
            label: Text(_isVideo ? 'Add video to gallery' : 'Add image to gallery'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMediaTypeOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlValidationMessage() {
    if (_tecSrc.text.trim().isEmpty) return const SizedBox.shrink();

    final bool isValid = _isValidUrl(_tecSrc.text);
    final bool isGoogleDrive = _driveRegExp.hasMatch(_tecSrc.text);

    if (isGoogleDrive) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info, color: Colors.blue, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Google Drive link detected - will be automatically converted to direct link',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!isValid) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Please enter a valid URL starting with https://',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          SelectionArea(
            child: SelectableText(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: message));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy error'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.green.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'Ready!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSizeError(String title, String subtitle, String url, String buttonText) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber,
            size: 48,
            color: Colors.orange.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'File Too Large',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => launchUrlString(url),
            icon: const Icon(Icons.open_in_new),
            label: Text(buttonText),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Media Preview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a URL and test to see preview',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
    if (_canSave) {
      // On web or when ready, show the image from URL
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          NetworkImageHelper.getImageUrl(_src),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorState('Failed to load image: $error');
          },
        ),
      );
    }

    return FutureBuilder(
      future: _fetchFile(true),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingState('Checking image...');
        }

        if (snap.hasData || (kIsWeb && _mediaFileSizeBytes != null)) {
          _canTestSrc = true;
          _tmpFile = snap.data;

          final size = _mediaFileSizeBytes ?? (_tmpFile?.lengthSync() ?? 0);
          final double sizeInKb = size / 1024;

          if (sizeInKb <= _maxImageSizeKB || _mediaFileSizeBytes == 0) {
            debugPrint('image size is good: $sizeInKb KB');
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              setState(() {
                _canSave = true;
              });
            });
            return _buildSuccessState(_mediaFileSizeBytes == 0
                ? 'Image is ready! (Size validation skipped on web)'
                : 'Image is ready! Size: ${sizeInKb.toStringAsFixed(1)} KB');
          } else {
            _canSave = false;
            _canTestSrc = true;
            return _buildFileSizeError(
              'Image too large: ${sizeInKb.toStringAsFixed(1)} KB',
              'Maximum size is $_maxImageSizeKB KB. Please compress the image.',
              'https://imagecompressor.com',
              'Compress Image Online',
            );
          }
        }

        if (snap.hasError) {
          _canTestSrc = true;
          debugPrint('Error fetching image: ${snap.error}');
          return _buildErrorState('Failed to load image: ${snap.error}');
        }

        return _buildLoadingState('Preparing...');
      },
    );
  }

  Widget _buildVideoPlayerTest() {
    if (_canSave) {
      // On web, use network video player
      if (kIsWeb) {
        return _buildVideoPlayer();
      }
      // On native, use cached file
      return _buildVideoPlayer();
    }

    return FutureBuilder(
      future: _fetchFile(false),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingState('Checking video...');
        }

        if (snap.hasData || (kIsWeb && _mediaFileSizeBytes != null)) {
          _canTestSrc = true;
          _tmpFile = snap.data;

          final size = _mediaFileSizeBytes ?? (_tmpFile?.lengthSync() ?? 0);
          final double sizeInMb = size / (1024 * 1024);

          if (sizeInMb <= _maxVideoSizeMB || _mediaFileSizeBytes == 0) {
            debugPrint('video size is good: $sizeInMb MB');

            // Initialize video player
            if (kIsWeb) {
              _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(_src));
            } else {
              _videoPlayerController = VideoPlayerController.file(_tmpFile!);
            }

            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              _videoPlayerController!.initialize().then((_) {
                setState(() {
                  _canSave = true;
                  _videoPlayerController!.play();
                });
              }).catchError((error) {
                debugPrint('Error initializing video player: $error');
                setState(() {
                  _canTestSrc = true;
                });
              });
            });

            return _buildLoadingState('Initializing video player...');
          } else {
            _canTestSrc = true;
            _canSave = false;
            return _buildFileSizeError(
              'Video too large: ${sizeInMb.toStringAsFixed(1)} MB',
              'Maximum size is $_maxVideoSizeMB MB. Please compress the video.',
              'https://www.freeconvert.com/video-compressor',
              'Compress Video Online',
            );
          }
        }

        if (snap.hasError) {
          _canTestSrc = true;
          debugPrint('Error fetching video: ${snap.error}');
          return _buildErrorState('Failed to load video: ${snap.error}');
        }

        return _buildLoadingState('Preparing...');
      },
    );
  }

  Widget _buildVideoPlayer() {
    if (!_videoPlayerController!.value.isInitialized) {
      return _buildLoadingState('Initializing video...');
    }

    debugPrint('Video player initialized!');
    _videoPlayerController!.play();
    _videoPlayerController!.setLooping(true);

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              ),
            ),
          ),
        ),
        if (_isVideo) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Video is ready! You can add a thumbnail URL above for better preview.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // * Logic

  bool _isValidUrl(String url) {
    if (url.trim().isEmpty) return false;
    try {
      final uri = Uri.parse(url.trim());
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

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
        throw Exception('HTTP ${response.statusCode}: Failed to fetch media file');
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

      final response = await http.get(Uri.parse(srcUrl)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _mediaFileSizeBytes = response.bodyBytes.length;
        debugPrint('Media size on web: $_mediaFileSizeBytes bytes');
        return null; // Web mode: no local file cache
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to validate media');
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
      if (!_isValidUrl(text) && !_driveRegExp.hasMatch(text)) return;

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
          content: Text('Could not read clipboard. Paste manually (⌘V / Ctrl+V).'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.save, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Save Media'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Save this ${_isVideo ? 'video' : 'image'} to the event media?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isVideo ? Icons.videocam : Icons.image,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Type: ${_isVideo ? 'Video' : 'Image'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Source: ${_src.length > 50 ? '${_src.substring(0, 47)}...' : _src}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final Map<String, dynamic> data = {
                'title': '',
                'src': _src,
                'type': _isVideo ? 'vid' : 'img',
              };
              if (_isVideo && _tecThumbnailSrc.text.trim().isNotEmpty) {
                data['thumbnailSrc'] = _tecThumbnailSrc.text.trim();
              }

              widget.eventContext.media.addMediaFile(data);
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close page
            },
            child: const Text('Save'),
          ),
        ],
      ),
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
        _canTestSrc = _isValidUrl(trimmedText) || _driveRegExp.hasMatch(trimmedText);
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

  String _sanitiseSrc() {
    RegExpMatch? match = _driveRegExp.firstMatch(_tecSrc.text.trim());
    if (match != null) {
      String id = match.group(1)!;
      debugPrint('Link is a GoogleDrive Share link. Parsing now. ID is $id');
      return 'https://drive.google.com/uc?id=$id';
    }
    return _tecSrc.text.trim();
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Adding Media Files'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                'Supported Sources',
                '• Direct HTTPS URLs to images/videos\n• Google Drive public links\n• Any publicly accessible media URL',
                Icons.link,
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'File Size Limits',
                '• Images: Maximum $_maxImageSizeKB KB\n• Videos: Maximum $_maxVideoSizeMB MB',
                Icons.storage,
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'Google Drive Setup',
                '1. Upload file to Google Drive\n2. Right-click → Share\n3. Change access to "Anyone with the link"\n4. Copy and paste the share link',
                Icons.cloud,
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'Tips',
                '• Test your URL before saving\n• For videos, add a thumbnail for better preview\n• Compress large files using the suggested tools',
                Icons.tips_and_updates,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
