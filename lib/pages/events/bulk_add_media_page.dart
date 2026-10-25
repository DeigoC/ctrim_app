import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

import '../../firebase/db_managers/shared_media_folders_db_manager.dart';
import '../../models/shared_media_folders.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/drive_folder_listing.dart';
import '../../utility/event_context.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/app_dialog.dart';
import 'add_media_drive_helpers.dart';

/// Which add-media method [BulkAddMediaPage] opens on.
enum BulkAddMediaTab {
  thisMonth,
  driveFolder,
  pasteUrls,
}

/// Max image size used by [AddMediaFilePage] (1.5 MB).
const int _maxImageSizeKB = 1536;

/// Bulk-add media from a public Google Drive folder, or by pasting many URLs.
class BulkAddMediaPage extends StatefulWidget {
  const BulkAddMediaPage({
    super.key,
    required this.eventContext,
    this.listing,
    this.initialTab = BulkAddMediaTab.thisMonth,
    this.folders,
    this.loadFolders,
  });

  final EventContext eventContext;

  /// Optional override for tests / custom listing backends.
  final DriveFolderListing? listing;

  final BulkAddMediaTab initialTab;

  /// When set, the month tab uses this instead of reading Firestore.
  final SharedMediaFolders? folders;

  /// Override for the settings fetch. Ignored when [folders] is set.
  final Future<SharedMediaFolders> Function()? loadFolders;

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

  SharedMediaFolders? _folders;
  SharedMediaFolderKind _kind = SharedMediaFolderKind.service;
  bool _loadingSettings = false;
  String? _settingsError;
  bool _showingPrevious = false;
  bool _loadingMonth = false;
  String? _monthError;
  List<DriveFolderEntry> _monthEntries = const [];
  final Set<String> _selectedMonthIds = {};
  int _monthListGeneration = 0;

  /// Photo tiles are the default. The list shows each file name and date.
  bool _gridView = true;

  List<_BulkUrlCandidate> _urlCandidates = const [];
  final Set<int> _selectedUrlIndexes = {};

  @override
  void initState() {
    super.initState();
    if (widget.eventContext.head.cellGroupIDs.isNotEmpty) {
      _kind = SharedMediaFolderKind.cellGroup;
    }
    _tabController = TabController(
      length: BulkAddMediaTab.values.length,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    _tabController.addListener(_onBulkTabChanged);
    unawaited(_bootstrapMonthFolder());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onBulkTabChanged);
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

  SharedMediaFolderPair? get _activePair => _folders?.pairFor(_kind);

  SharedMediaFolder? get _activeMonthFolder {
    final pair = _activePair;
    if (pair == null) return null;
    return _showingPrevious ? pair.previous : pair.current;
  }

  void _onBulkTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index != BulkAddMediaTab.thisMonth.index) return;
    final folder = _activeMonthFolder;
    if (folder == null || _loadingMonth || _loadingSettings) return;
    if (_monthEntries.isNotEmpty || _monthError != null) return;
    unawaited(_listMonthFolder(folder.folderId));
  }

  Future<void> _bootstrapMonthFolder() async {
    await Future<void>.value();
    if (!mounted) return;

    if (widget.folders != null) {
      _folders = widget.folders;
    } else {
      setState(() {
        _loadingSettings = true;
        _settingsError = null;
      });
      try {
        final load = widget.loadFolders ?? SharedMediaFoldersDBManager().fetch;
        final folders = await load();
        if (!mounted) return;
        _folders = folders;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loadingSettings = false;
          _settingsError = 'Could not load the shared folder.';
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() => _loadingSettings = false);

    if (_tabController.index != BulkAddMediaTab.thisMonth.index) return;
    final folder = _activeMonthFolder;
    if (folder == null) return;
    await _listMonthFolder(folder.folderId);
  }

  Future<void> _listMonthFolder(String folderId) async {
    final generation = ++_monthListGeneration;
    setState(() {
      _loadingMonth = true;
      _monthError = null;
      _monthEntries = const [];
      _selectedMonthIds.clear();
    });

    try {
      final entries = await _listing.listPublicFolder(folderId);
      if (!mounted || generation != _monthListGeneration) return;
      setState(() {
        _monthEntries = entries;
        _loadingMonth = false;
      });
    } on DriveFolderListingException catch (e) {
      if (!mounted || generation != _monthListGeneration) return;
      setState(() {
        _monthError = e.message;
        _loadingMonth = false;
      });
    } catch (e) {
      if (!mounted || generation != _monthListGeneration) return;
      setState(() {
        _monthError = 'Could not read the folder: $e';
        _loadingMonth = false;
      });
    }
  }

  void _onShowPreviousMonth(bool previous) {
    if (previous == _showingPrevious || _importing) return;
    setState(() => _showingPrevious = previous);
    _showActiveMonth();
  }

  void _onSelectGroup(SharedMediaFolderKind kind) {
    if (kind == _kind || _importing) return;
    setState(() {
      _kind = kind;
      if (_activePair?.previous == null) _showingPrevious = false;
    });
    _showActiveMonth();
  }

  void _showActiveMonth() {
    final folder = _activeMonthFolder;
    if (folder == null) {
      setState(() {
        _monthListGeneration++;
        _monthEntries = const [];
        _selectedMonthIds.clear();
        _monthError = null;
        _loadingMonth = false;
      });
      return;
    }
    unawaited(_listMonthFolder(folder.folderId));
  }

  Future<void> _openActiveMonthInDrive() async {
    final url = _activeMonthFolder?.openUrl;
    if (url == null) return;
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  String _monthChipLabel({required bool previous}) {
    final pair = _activePair;
    if (pair == null) return previous ? 'Last month' : 'This month';
    final slot = previous ? pair.previous : pair.current;
    if (slot != null) {
      return slot.displayLabel(previous ? 'Last month' : 'This month');
    }
    final stored = previous ? pair.previousLabel : pair.currentLabel;
    final trimmed = stored.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return previous ? 'Last month' : 'This month';
  }

  Future<void> _onImportSelectedMonthEntries() async {
    final selected = _monthEntries
        .where((e) => _selectedMonthIds.contains(e.id) && e.isImportableMedia)
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'This month'),
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
          _buildMonthTab(gutter),
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
                'pick which images or videos to add. Newest changes are listed '
                'first.',
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
                _buildMediaChoices(mediaEntries, _selectedIds),
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

  Widget _buildMediaChoices(
    List<DriveFolderEntry> mediaEntries,
    Set<String> selectedIds,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  Text(
                    '${selectedIds.length} of ${mediaEntries.length} selected',
                    style: theme.textTheme.titleSmall,
                  ),
                  TextButton(
                    onPressed: _importing
                        ? null
                        : () {
                            setState(() {
                              selectedIds
                                ..clear()
                                ..addAll(mediaEntries.map((e) => e.id));
                            });
                          },
                    child: const Text('Select all'),
                  ),
                  TextButton(
                    onPressed:
                        _importing ? null : () => setState(selectedIds.clear),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: _gridView ? 'Show file names' : 'Show as photos',
              onPressed: _importing
                  ? null
                  : () => setState(() => _gridView = !_gridView),
              icon: Icon(_gridView ? Icons.view_list : Icons.grid_view),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_gridView)
          _buildMediaGrid(mediaEntries, selectedIds)
        else
          ...mediaEntries.map(
            (entry) => _buildFolderEntryTile(
              entry,
              selected: selectedIds.contains(entry.id),
              onSelected: (value) =>
                  _setMediaSelected(selectedIds, entry.id, value),
            ),
          ),
      ],
    );
  }

  void _setMediaSelected(Set<String> selectedIds, String id, bool selected) {
    setState(() {
      if (selected) {
        selectedIds.add(id);
      } else {
        selectedIds.remove(id);
      }
    });
  }

  int _mediaGridColumns(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  Widget _buildMediaGrid(
    List<DriveFolderEntry> mediaEntries,
    Set<String> selectedIds,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mediaEntries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _mediaGridColumns(constraints.maxWidth),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final entry = mediaEntries[index];
            return _buildMediaGridTile(
              entry,
              selected: selectedIds.contains(entry.id),
              onSelected: (value) =>
                  _setMediaSelected(selectedIds, entry.id, value),
            );
          },
        );
      },
    );
  }

  Widget _buildMediaGridTile(
    DriveFolderEntry entry, {
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final alreadyAdded = _existingSrcs.contains(entry.directMediaUrl);
    final label = entry.name.isEmpty ? 'Photo' : entry.name;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        enabled: !alreadyAdded && !_importing,
        label: alreadyAdded ? '$label, already in this post' : label,
        child: Material(
          color: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.12),
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap:
                alreadyAdded || _importing ? null : () => onSelected(!selected),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildMediaPreview(entry),
                if (alreadyAdded)
                  ColoredBox(
                    color: colorScheme.surface.withValues(alpha: 0.55),
                    child: Center(
                      child: Text(
                        'Added',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                if (selected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(DriveFolderEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!entry.isImage) {
      return Icon(
        Icons.videocam_outlined,
        size: 36,
        color: colorScheme.onSurfaceVariant,
      );
    }
    return Image.network(
      NetworkImageHelper.getImageUrl(entry.directMediaUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(
        Icons.broken_image_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildFolderEntryTile(
    DriveFolderEntry entry, {
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final alreadyAdded = _existingSrcs.contains(entry.directMediaUrl);
    final detail = entry.modifiedCaption.isNotEmpty
        ? entry.modifiedCaption
        : (entry.mimeType.isEmpty ? entry.mediaType : entry.mimeType);

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
            : (value) => onSelected(value ?? false),
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
        subtitle: Text(alreadyAdded ? 'Already in this post' : detail),
      ),
    );
  }

  Widget _buildMonthTab(double gutter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final active = _activeMonthFolder;
    final mediaEntries =
        _monthEntries.where((e) => e.isImportableMedia).toList();
    final showGroupChoice = !_loadingSettings && _settingsError == null;
    final showMonthSwitch = _activePair?.previous != null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 16),
            children: [
              Text(
                'Loose photos in the shared month folder, newest first. Pick the '
                'ones that belong on this post.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (showGroupChoice) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<SharedMediaFolderKind>(
                    showSelectedIcon: false,
                    segments: [
                      for (final kind in SharedMediaFolderKind.displayOrder)
                        ButtonSegment<SharedMediaFolderKind>(
                          value: kind,
                          label: Text(kind.label),
                        ),
                    ],
                    selected: {_kind},
                    onSelectionChanged: _importing
                        ? null
                        : (selection) => _onSelectGroup(selection.first),
                  ),
                ),
              ],
              if (showMonthSwitch) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text(_monthChipLabel(previous: false)),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text(_monthChipLabel(previous: true)),
                      ),
                    ],
                    selected: {_showingPrevious},
                    onSelectionChanged: _importing
                        ? null
                        : (selection) => _onShowPreviousMonth(selection.first),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Photos inside an event folder are added with Bulk add from a folder.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (active != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _openActiveMonthInDrive,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open in Google Drive'),
                  ),
                ),
              ],
              if (_loadingSettings) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ] else if (_settingsError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _settingsError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: _bootstrapMonthFolder,
                    child: const Text('Retry'),
                  ),
                ),
              ] else if (active == null) ...[
                const SizedBox(height: 16),
                Text(
                  _showingPrevious
                      ? 'Last month’s ${_kind.label} folder isn’t set.'
                      : 'This month’s ${_kind.label} folder isn’t set yet. '
                          'An area admin can add the Google Drive link from '
                          'Personal.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else if (_loadingMonth) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ] else if (_monthError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _monthError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: () {
                      final folder = _activeMonthFolder;
                      if (folder == null) return;
                      unawaited(_listMonthFolder(folder.folderId));
                    },
                    child: const Text('Retry'),
                  ),
                ),
              ] else if (mediaEntries.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildMediaChoices(mediaEntries, _selectedMonthIds),
              ] else if (_monthEntries.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'That folder has ${_monthEntries.length} item(s), but none '
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
            enabled: _selectedMonthIds.isNotEmpty && !_importing,
            label: _importing
                ? 'Adding…'
                : 'Add ${_selectedMonthIds.length} to gallery',
            onPressed: _onImportSelectedMonthEntries,
          ),
      ],
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
      final looksVideo =
          mediaNameLooksLikeVideo(part) || mediaNameLooksLikeVideo(src);
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
      content: 'This month\n'
          '1. Loose photos in the shared month folder are listed for you\n'
          '2. Switch to last month when that folder is set\n'
          '3. Photos inside an event folder use the Drive folder tab\n\n'
          'Drive folder\n'
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
