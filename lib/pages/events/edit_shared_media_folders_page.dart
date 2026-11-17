import 'package:flutter/material.dart';

import '../../firebase/db_managers/shared_media_folders_db_manager.dart';
import '../../models/shared_media_folders.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/role_access_gate.dart';
import 'add_media_drive_helpers.dart';

/// Area-admin editor for the Services and Cell Groups shared Drive folders.
class EditSharedMediaFoldersPage extends StatefulWidget {
  const EditSharedMediaFoldersPage({
    super.key,
    this.initial,
    this.loadFolders,
    this.saveFolders,
  });

  /// When set, the form opens with these values and does not read Firestore.
  final SharedMediaFolders? initial;

  final Future<SharedMediaFolders> Function()? loadFolders;
  final Future<void> Function(SharedMediaFolders folders)? saveFolders;

  @override
  State<EditSharedMediaFoldersPage> createState() =>
      _EditSharedMediaFoldersPageState();
}

class _EditSharedMediaFoldersPageState
    extends State<EditSharedMediaFoldersPage> {
  final TextEditingController _currentLabel = TextEditingController();
  final TextEditingController _currentUrl = TextEditingController();
  final TextEditingController _previousLabel = TextEditingController();
  final TextEditingController _previousUrl = TextEditingController();

  SharedMediaFolders _baseline = SharedMediaFolders.empty;
  SharedMediaFolders _draft = SharedMediaFolders.empty;
  SharedMediaFolderKind _kind = SharedMediaFolderKind.service;
  bool _loading = false;
  Object? _loadError;
  bool _saving = false;
  bool _allowPop = false;
  String? _currentUrlError;
  String? _previousUrlError;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _applyFolders(widget.initial!);
    } else {
      _loading = true;
      _load();
    }
    _currentLabel.addListener(_onFieldChanged);
    _currentUrl.addListener(_onFieldChanged);
    _previousLabel.addListener(_onFieldChanged);
    _previousUrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _currentLabel.removeListener(_onFieldChanged);
    _currentUrl.removeListener(_onFieldChanged);
    _previousLabel.removeListener(_onFieldChanged);
    _previousUrl.removeListener(_onFieldChanged);
    _currentLabel.dispose();
    _currentUrl.dispose();
    _previousLabel.dispose();
    _previousUrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    await Future<void>.value();
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final load = widget.loadFolders ?? SharedMediaFoldersDBManager().fetch;
      final folders = await load();
      if (!mounted) return;
      _applyFolders(folders);
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error;
      });
    }
  }

  void _applyFolders(SharedMediaFolders folders) {
    _baseline = folders;
    _draft = folders;
    _loadControllers();
  }

  void _loadControllers() {
    final pair = _draft.pairFor(_kind);
    _currentLabel.text = pair.currentLabel;
    _currentUrl.text = pair.currentFolderUrl;
    _previousLabel.text = pair.previousLabel;
    _previousUrl.text = pair.previousFolderUrl;
  }

  void _rememberControllers() {
    _draft = _draft.replacing(
      _kind,
      SharedMediaFolderPair(
        currentLabel: _currentLabel.text,
        currentFolderUrl: _currentUrl.text,
        previousLabel: _previousLabel.text,
        previousFolderUrl: _previousUrl.text,
      ),
    );
  }

  bool get _canStartNewMonth =>
      !_saving && extractDriveFolderId(_currentUrl.text) != null;

  String get _otherGroupLabel {
    return _kind == SharedMediaFolderKind.service
        ? SharedMediaFolderKind.cellGroup.label
        : SharedMediaFolderKind.service.label;
  }

  bool _isDirty() {
    _rememberControllers();
    return !_samePair(_draft.service, _baseline.service) ||
        !_samePair(_draft.cellGroup, _baseline.cellGroup);
  }

  bool _samePair(SharedMediaFolderPair a, SharedMediaFolderPair b) {
    return a.currentLabel == b.currentLabel &&
        a.currentFolderUrl == b.currentFolderUrl &&
        a.previousLabel == b.previousLabel &&
        a.previousFolderUrl == b.previousFolderUrl;
  }

  void _popRoute([SharedMediaFolders? result]) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  void _onSelectGroup(Set<SharedMediaFolderKind> selection) {
    final next = selection.first;
    if (next == _kind || _saving) return;
    _rememberControllers();
    setState(() {
      _kind = next;
      _currentUrlError = null;
      _previousUrlError = null;
    });
    _loadControllers();
  }

  Future<void> _onStartNewMonth() async {
    if (!_canStartNewMonth) return;
    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: 'Start a new month',
      content: 'Last month will become the folder that is current now for '
          '${_kind.label}. The month before that will no longer appear in '
          'the app. $_otherGroupLabel is left as it is. Paste the new '
          'month’s folder link before you save.',
      confirmText: 'Start new month',
    );
    if (!confirmed || !mounted) return;
    _rememberControllers();
    _draft = _draft.replacing(_kind, _draft.pairFor(_kind).startNewMonth());
    _loadControllers();
    setState(() {
      _currentUrlError = null;
      _previousUrlError = null;
    });
  }

  Future<void> _onSave() async {
    _rememberControllers();
    final serviceCurrent = SharedMediaFolderPair.validateFolderUrl(
        _draft.service.currentFolderUrl);
    final servicePrevious = SharedMediaFolderPair.validateFolderUrl(
      _draft.service.previousFolderUrl,
    );
    final cellCurrent = SharedMediaFolderPair.validateFolderUrl(
      _draft.cellGroup.currentFolderUrl,
    );
    final cellPrevious = SharedMediaFolderPair.validateFolderUrl(
      _draft.cellGroup.previousFolderUrl,
    );
    final serviceBad = serviceCurrent != null || servicePrevious != null;
    final cellBad = cellCurrent != null || cellPrevious != null;
    if (serviceBad || cellBad) {
      final show = serviceBad
          ? SharedMediaFolderKind.service
          : SharedMediaFolderKind.cellGroup;
      setState(() {
        _kind = show;
        _currentUrlError = show == SharedMediaFolderKind.service
            ? serviceCurrent
            : cellCurrent;
        _previousUrlError = show == SharedMediaFolderKind.service
            ? servicePrevious
            : cellPrevious;
      });
      _loadControllers();
      return;
    }

    final folders = SharedMediaFolders(
      service: _draft.service.normalize(),
      cellGroup: _draft.cellGroup.normalize(),
    );

    setState(() => _saving = true);
    try {
      final save = widget.saveFolders ?? SharedMediaFoldersDBManager().save;
      await save(folders);
      if (!mounted) return;
      _popRoute(folders);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save the folders: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleAccessGate(
      allow: (user) => user.canManageVolunteers,
      deniedMessage: 'Only area admins can edit shared media folders.',
      title: 'Shared media folders',
      child: _buildEditor(),
    );
  }

  Widget _buildEditor() {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowPop) return;
        if (!_isDirty()) {
          _popRoute();
          return;
        }
        final discard = await DialogManager.discardChanges(context: context);
        if (discard && mounted) _popRoute();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Shared media folders'),
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading || _loadError != null) {
      return LoadProgressBody(
        message: 'Loading shared folders',
        completedSteps: _loading ? 0 : 1,
        totalSteps: 1,
        error: _loadError,
        onRetry: _load,
      );
    }

    final gutter = ResponsiveLayout.horizontalGutter(
      MediaQuery.sizeOf(context).width,
      narrowPadding: 16,
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 32),
      children: [
        Text(
          'People adding photos to a post can pick loose files from this '
          'month’s folder, or from last month, for Services or for Cell '
          'Groups. Event folders inside the month are added with Bulk add '
          'from a folder.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
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
            onSelectionChanged: _saving ? null : _onSelectGroup,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'This month',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _currentLabel,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Label',
            hintText: 'October 2026',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _currentUrl,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Drive folder link',
            hintText: 'https://drive.google.com/drive/folders/…',
            border: const OutlineInputBorder(),
            errorText: _currentUrlError,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _canStartNewMonth ? _onStartNewMonth : null,
            icon: const Icon(Icons.event_repeat, size: 18),
            label: const Text('Start new month'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Starting a new month moves this group’s current folder to last '
          'month. Anything older than that is no longer offered in the app. '
          '$_otherGroupLabel stays as it is.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Last month',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _previousLabel,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Label',
            hintText: 'September 2026',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _previousUrl,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Drive folder link',
            hintText: 'https://drive.google.com/drive/folders/…',
            border: const OutlineInputBorder(),
            errorText: _previousUrlError,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _onSave,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ),
      ],
    );
  }
}
