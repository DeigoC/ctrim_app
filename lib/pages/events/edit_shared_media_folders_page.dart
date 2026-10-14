import 'package:flutter/material.dart';

import '../../firebase/db_managers/shared_media_folders_db_manager.dart';
import '../../models/shared_media_folders.dart';
import '../../utility/dialog_manager.dart';
import 'add_media_drive_helpers.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/load_progress_body.dart';

/// Area-admin editor for this month’s shared Drive folder and the previous one.
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
    _previousUrl.dispose();
    _previousLabel.dispose();
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
    _currentLabel.text = folders.currentLabel;
    _currentUrl.text = folders.currentFolderUrl;
    _previousLabel.text = folders.previousLabel;
    _previousUrl.text = folders.previousFolderUrl;
  }

  bool get _canStartNewMonth =>
      !_saving && extractDriveFolderId(_currentUrl.text) != null;

  bool _isDirty() {
    return _currentLabel.text.trim() != _baseline.currentLabel ||
        _currentUrl.text.trim() != _baseline.currentFolderUrl ||
        _previousLabel.text.trim() != _baseline.previousLabel ||
        _previousUrl.text.trim() != _baseline.previousFolderUrl;
  }

  void _popRoute([SharedMediaFolders? result]) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  Future<void> _onStartNewMonth() async {
    if (!_canStartNewMonth) return;
    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: 'Start a new month',
      content:
          'Last month will become the folder that is current now. The month '
          'before that will no longer appear in the app. Paste the new '
          'month’s folder link before you save.',
      confirmText: 'Start new month',
    );
    if (!confirmed || !mounted) return;
    final next = SharedMediaFolders(
      currentLabel: _currentLabel.text,
      currentFolderUrl: _currentUrl.text,
      previousLabel: _previousLabel.text,
      previousFolderUrl: _previousUrl.text,
    ).startNewMonth();
    _currentLabel.text = next.currentLabel;
    _currentUrl.text = next.currentFolderUrl;
    _previousLabel.text = next.previousLabel;
    _previousUrl.text = next.previousFolderUrl;
    setState(() {
      _currentUrlError = null;
      _previousUrlError = null;
    });
  }

  Future<void> _onSave() async {
    final currentUrlError =
        SharedMediaFolders.validateFolderUrl(_currentUrl.text);
    final previousUrlError =
        SharedMediaFolders.validateFolderUrl(_previousUrl.text);
    setState(() {
      _currentUrlError = currentUrlError;
      _previousUrlError = previousUrlError;
    });
    if (currentUrlError != null || previousUrlError != null) return;

    final folders = SharedMediaFolders.normalized(
      currentLabel: _currentLabel.text,
      currentFolderUrl: _currentUrl.text,
      previousLabel: _previousLabel.text,
      previousFolderUrl: _previousUrl.text,
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
          'month’s folder, or from last month. Event folders inside the month '
          'are added with Bulk add from a folder.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
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
          'Starting a new month moves the current folder to last month. '
          'Anything older than that is no longer offered in the app.',
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
