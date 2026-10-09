import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../utility/dialog_manager.dart';
import '../../utility/drive_folder_listing.dart';
import '../../utility/event_context.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/app_dialog.dart';
import 'add_media_drive_helpers.dart';

/// Max image size used by [AddMediaFilePage] (1.5 MB).
const int _maxImageSizeKB = 1536;

/// Bulk-add media from a public Google Drive folder, or by pasting many URLs.
class BulkAddMediaPage extends StatefulWidget {
  const BulkAddMediaPage({
    super.key,
    required this.eventContext,
    this.listing,
  });

  final EventContext eventContext;

  /// Optional override for tests / custom listing backends.
  final DriveFolderListing? listing;

  @override
  State<BulkAddMediaPage> createState() => _BulkAddMediaPageState();
}

class _BulkAddMediaPageState extends State<BulkAddMediaPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _folderController = TextEditingController();
  final TextEditingController _urlsController = TextEditingController();
  late final DriveFolderListing _listing =
      widget.listing ?? DriveFolderListing();
  bool _loadingFolder = false;
  bool _importing = false;
  String? _folderError;
  List<DriveFolderEntry> _folderEntries = const [];
  final Set<String> _selectedIds = {};

  List<_BulkUrlCandidate> _urlCandidates = const [];
  final Set<int> _selectedUrlIndexes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _folderController.dispose();
    _urlsController.dispose();
    super.dispose();
  }

  Set<String> get _existingSrcs {
    return {
      for (final item in widget.eventContext.media.allMedia)
        if (item['src'] is String) item['src'] as String,
      for (final item in widget.eventContext.head.media)
        if (item['src'] is String) item['src'] as String,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gutter = ResponsiveLayout.horizontalGutter(
      MediaQuery.sizeOf(context).width,
      narrowPadding: 16,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Bulk add media'),
        backgroundColor: colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Drive folder'),
            Tab(text: 'Paste URLs'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFolderTab(gutter),
          _buildUrlsTab(gutter),
        ],
      ),
    );
  }

  Widget _buildFolderTab(double gutter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaEntries =
        _folderEntries.where((e) => e.isImportableMedia).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 16),
            children: [
              Text(
                'Paste a public Google Drive folder link. The app reads the '
                'folder’s shared file list (no Google API signup) and lets you '
                'pick which images or videos to add.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _folderController,
                decoration: InputDecoration(
                  labelText: 'Drive folder link',
                  hintText: 'https://drive.google.com/drive/folders/…',
                  suffixIcon: IconButton(
                    tooltip: 'Paste',
                    onPressed: () => _pasteInto(_folderController),
                    icon: const Icon(Icons.content_paste),
                  ),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _onListFolder(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _loadingFolder ? null : _onListFolder,
                  icon: _loadingFolder
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.folder_open, size: 18),
                  label: Text(_loadingFolder ? 'Reading…' : 'List files'),
                ),
              ),
              if (_folderError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _folderError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
              if (mediaEntries.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      '${_selectedIds.length} of ${mediaEntries.length} selected',
                      style: theme.textTheme.titleSmall,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIds
                            ..clear()
                            ..addAll(mediaEntries.map((e) => e.id));
                        });
                      },
                      child: const Text('Select all'),
                    ),
                    TextButton(
                      onPressed: () => setState(_selectedIds.clear),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...mediaEntries.map(_buildFolderEntryTile),
              ] else if (_folderEntries.isNotEmpty && !_loadingFolder) ...[
                const SizedBox(height: 16),
                Text(
                  'That folder has ${_folderEntries.length} item(s), but none '
                  'look like images or videos. Nested folders are not imported.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (mediaEntries.isNotEmpty)
          _buildBottomBar(
            enabled: _selectedIds.isNotEmpty && !_importing,
            label: _importing
                ? 'Adding…'
                : 'Add ${_selectedIds.length} to gallery',
            onPressed: _onImportSelectedFolderEntries,
          ),
      ],
    );
  }

  Widget _buildFolderEntryTile(DriveFolderEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    final alreadyAdded = _existingSrcs.contains(entry.directMediaUrl);
    final selected = _selectedIds.contains(entry.id);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: alreadyAdded || _importing
            ? null
            : (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(entry.id);
                  } else {
                    _selectedIds.remove(entry.id);
                  }
                });
              },
        secondary: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: entry.isImage
              ? Image.network(
                  NetworkImageHelper.getImageUrl(entry.directMediaUrl),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    Icons.videocam_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        title: Text(
          entry.name.isEmpty ? entry.id : entry.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          alreadyAdded
              ? 'Already in this post'
              : (entry.mimeType.isEmpty ? entry.mediaType : entry.mimeType),
        ),
      ),
    );
  }

  Widget _buildUrlsTab(double gutter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 16),
            children: [
              Text(
                'Paste many public image or video URLs — one per line. '
                'Google Drive file share links are converted automatically.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlsController,
                decoration: InputDecoration(
                  labelText: 'Media URLs',
                  alignLabelWithHint: true,
                  hintText:
                      'https://drive.google.com/file/d/…/view?usp=sharing\n'
                      'https://example.com/photo.jpg',
                  suffixIcon: IconButton(
                    tooltip: 'Paste',
                    onPressed: () => _pasteInto(_urlsController),
                    icon: const Icon(Icons.content_paste),
                  ),
                ),
                minLines: 6,
                maxLines: 12,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _onParseUrls,
                  icon: const Icon(Icons.playlist_add_check, size: 18),
                  label: const Text('Review links'),
                ),
              ),
              if (_urlCandidates.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      '${_selectedUrlIndexes.length} of ${_urlCandidates.length} selected',
                      style: theme.textTheme.titleSmall,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedUrlIndexes
                            ..clear()
                            ..addAll(
                              Iterable.generate(_urlCandidates.length),
                            );
                        });
                      },
                      child: const Text('Select all'),
                    ),
                    TextButton(
                      onPressed: () => setState(_selectedUrlIndexes.clear),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_urlCandidates.length, (index) {
                  final candidate = _urlCandidates[index];
                  final alreadyAdded = _existingSrcs.contains(candidate.src);
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.12),
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _selectedUrlIndexes.contains(index),
                      onChanged: alreadyAdded || _importing
                          ? null
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedUrlIndexes.add(index);
                                } else {
                                  _selectedUrlIndexes.remove(index);
                                }
                              });
                            },
                      title: Text(
                        candidate.src,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                      subtitle: Text(
                        alreadyAdded
                            ? 'Already in this post'
                            : (candidate.isVideo ? 'Video' : 'Image'),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        if (_urlCandidates.isNotEmpty)
          _buildBottomBar(
            enabled: _selectedUrlIndexes.isNotEmpty && !_importing,
            label: _importing
                ? 'Adding…'
                : 'Add ${_selectedUrlIndexes.length} to gallery',
            onPressed: _onImportSelectedUrls,
          ),
      ],
    );
  }

  Widget _buildBottomBar({
    required bool enabled,
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      color: colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: enabled ? onPressed : null,
              icon: _importing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(label),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pasteInto(TextEditingController controller) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty) return;
      setState(() => controller.text = text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read clipboard.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onListFolder() async {
    final folderId = extractDriveFolderId(_folderController.text);
    if (folderId == null) {
      setState(() {
        _folderError =
            'Paste a Google Drive folder link (…/drive/folders/…), or the folder id.';
        _folderEntries = const [];
        _selectedIds.clear();
      });
      return;
    }

    setState(() {
      _loadingFolder = true;
      _folderError = null;
      _folderEntries = const [];
      _selectedIds.clear();
    });

    try {
      final entries = await _listing.listPublicFolder(folderId);
      if (!mounted) return;
      final media = entries.where((e) => e.isImportableMedia).toList();
      setState(() {
        _folderEntries = entries;
        _selectedIds.addAll(
          media
              .where((e) => !_existingSrcs.contains(e.directMediaUrl))
              .map((e) => e.id),
        );
        _loadingFolder = false;
      });
    } on DriveFolderListingException catch (e) {
      if (!mounted) return;
      setState(() {
        _folderError = e.message;
        _loadingFolder = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _folderError = 'Could not read the folder: $e';
        _loadingFolder = false;
      });
    }
  }

  void _onParseUrls() {
    final rawParts = splitMediaUrlList(_urlsController.text);
    final candidates = <_BulkUrlCandidate>[];
    for (final part in rawParts) {
      if (!isTestableMediaUrl(part)) continue;
      final src = sanitiseMediaUrl(part);
      final looksVideo = mediaNameLooksLikeVideo(part) ||
          mediaNameLooksLikeVideo(src);
      candidates.add(_BulkUrlCandidate(src: src, isVideo: looksVideo));
    }

    setState(() {
      _urlCandidates = candidates;
      _selectedUrlIndexes
        ..clear()
        ..addAll(
          [
            for (var i = 0; i < candidates.length; i++)
              if (!_existingSrcs.contains(candidates[i].src)) i,
          ],
        );
    });

    if (candidates.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No usable image or video URLs found in that text.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onImportSelectedFolderEntries() async {
    final selected = _folderEntries
        .where((e) => _selectedIds.contains(e.id) && e.isImportableMedia)
        .toList();
    await _importMediaMaps([
      for (final entry in selected)
        {
          'title': entry.name,
          'src': entry.directMediaUrl,
          'type': entry.mediaType,
        },
    ]);
  }

  Future<void> _onImportSelectedUrls() async {
    await _importMediaMaps([
      for (final index in _selectedUrlIndexes.toList()..sort())
        {
          'title': '',
          'src': _urlCandidates[index].src,
          'type': _urlCandidates[index].isVideo ? 'vid' : 'img',
        },
    ]);
  }

  Future<void> _importMediaMaps(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.library_add_check_outlined,
        title: 'Add to gallery',
        message:
            'Add ${items.length} media item(s) to this post? Oversized images '
            '(over $_maxImageSizeKB KB) will be skipped. Save the post afterwards '
            'to keep the changes.',
        actions: AppDialogActions(
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          confirmLabel: 'Add',
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _importing = true);

    var added = 0;
    var skippedExisting = 0;
    var skippedLarge = 0;
    var failed = 0;
    final existing = _existingSrcs;

    for (final item in items) {
      final src = item['src'] as String? ?? '';
      if (src.isEmpty) continue;
      if (existing.contains(src)) {
        skippedExisting++;
        continue;
      }

      final type = item['type'] as String? ?? 'img';
      if (type == 'img') {
        final ok = await _imageWithinSizeLimit(src);
        if (ok == null) {
          failed++;
          continue;
        }
        if (!ok) {
          skippedLarge++;
          continue;
        }
      }

      widget.eventContext.media.addMediaFile({
        'title': item['title'] ?? '',
        'src': src,
        'type': type,
        if (item['thumbnailSrc'] != null) 'thumbnailSrc': item['thumbnailSrc'],
      });
      widget.eventContext.head.addKeyMediaIfRoom(
        type: type,
        src: src,
        title: (item['title'] as String?) ?? '',
        thumbnail: (item['thumbnailSrc'] as String?) ?? '',
      );
      existing.add(src);
      added++;
    }

    widget.eventContext.allowSavingOfTheEdit();
    if (!mounted) return;
    setState(() => _importing = false);

    final parts = <String>[
      if (added > 0) 'Added $added',
      if (skippedExisting > 0) 'skipped $skippedExisting already present',
      if (skippedLarge > 0) 'skipped $skippedLarge over size limit',
      if (failed > 0) 'failed $failed',
    ];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(parts.isEmpty ? 'Nothing added.' : parts.join(' · ')),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (added > 0 && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  /// Returns `true` when within limit, `false` when too large, `null` on fetch failure.
  Future<bool?> _imageWithinSizeLimit(String src) async {
    try {
      final response = await http
          .get(Uri.parse(NetworkImageHelper.getImageUrl(src)))
          .timeout(const Duration(seconds: 45));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final bytes = response.bodyBytes.length;
      return bytes <= _maxImageSizeKB * 1024;
    } catch (_) {
      return null;
    }
  }

  void _showHelp() {
    DialogManager.showAlertDialog(
      context: context,
      icon: Icons.help_outline,
      title: 'Bulk add media',
      content: 'Drive folder\n'
          '1. Put images (or videos) in a Google Drive folder\n'
          '2. Share the folder as “Anyone with the link” (Viewer)\n'
          '3. Paste the folder link here and tap List files\n'
          '4. Pick what to add — no Google API project is required\n\n'
          'Paste URLs\n'
          '• One public HTTPS or Drive file link per line\n'
          '• Useful when you already have individual share links\n\n'
          'Limits\n'
          '• Images: max $_maxImageSizeKB KB each\n'
          '• Nested Drive folders are not opened automatically\n'
          '• Save the post after importing to keep the gallery',
    );
  }
}

class _BulkUrlCandidate {
  const _BulkUrlCandidate({required this.src, required this.isVideo});
  final String src;
  final bool isVideo;
}
