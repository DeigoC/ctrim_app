import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../firebase/db_managers/user_db_manager.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/local_data_manager.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/user_avatar.dart';

/// Lets the signed-in volunteer update their own profile picture URL.
class EditProfilePicturePage extends StatefulWidget {
  const EditProfilePicturePage({super.key});

  @override
  State<EditProfilePicturePage> createState() => _EditProfilePicturePageState();
}

class _EditProfilePicturePageState extends State<EditProfilePicturePage> {
  static final RegExp _driveRegExp = RegExp(r'https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');
  static final RegExp _driveRegExpLoose = RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');

  final UserDBManager _userDBManager = UserDBManager();
  late final TextEditingController _tecImgSrc;
  late final AppContext _appContext;

  String _previewSrc = '';
  bool _testing = false;
  bool _imageValidated = false;
  bool _canSave = false;
  bool _allowPop = false;
  bool _isSaved = false;
  String? _validationMessage;

  late final String _initialSrc;

  void _popRouteAfterAllowing({Object? result}) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  bool _hasUnsavedChanges() {
    return _sanitiseSrc() != _initialSrc;
  }

  @override
  void initState() {
    super.initState();
    _appContext = Provider.of<AppContext>(context, listen: false);
    _previewSrc = _appContext.currentUser.imgSrc;
    _initialSrc = _previewSrc;
    _tecImgSrc = TextEditingController(text: _previewSrc);
    _tecImgSrc.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _tecImgSrc.removeListener(_onUrlChanged);
    _tecImgSrc.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final sanitized = _sanitiseSrc();
    final changed = sanitized != _appContext.currentUser.imgSrc;
    setState(() {
      if (sanitized != _previewSrc) {
        _imageValidated = false;
        _validationMessage = null;
        _testing = false;
      }
      _canSave = changed && _imageValidated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final horizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 16);

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
      appBar: AppBar(title: const Text('Edit profile picture')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Preview',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  MyUserAvatar(
                    _appContext.currentUser,
                    radius: 64,
                    tmpImageSrc: _testing || _imageValidated ? _previewSrc : null,
                  ),
                  if (_validationMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _validationMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Image URL',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paste a public link to your photo. Google Drive share links work — use the help section below.',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tecImgSrc,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Image URL',
                      hintText: 'https://… or Google Drive share link',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: 'Clear',
                        onPressed: _tecImgSrc.text.isEmpty ? null : () => _tecImgSrc.clear(),
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _tecImgSrc.text.trim().isEmpty ? null : _onTestImageClick,
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Test image'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _canSave ? _onSaveClick : null,
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildHelpSection(theme, colorScheme),
        ],
      ),
    ),
    );
  }

  Widget _buildHelpSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.help_outline, color: colorScheme.primary),
        title: const Text('How to set your photo'),
        subtitle: const Text('Google Drive steps and tips'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Using Google Drive (recommended)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          const _HelpStep(
            number: 1,
            text: 'Upload your photo to Google Drive (from drive.google.com or the Drive app).',
          ),
          const _HelpStep(
            number: 2,
            text: 'Open the file → Share (or Get link).',
          ),
          const _HelpStep(
            number: 3,
            text: 'Under General access, choose Anyone with the link (Viewer). Copy the link.',
          ),
          const _HelpStep(
            number: 4,
            text: 'Paste that link in the Image URL field above, then tap Test image.',
          ),
          const _HelpStep(
            number: 5,
            text: 'If the preview looks good, tap Save.',
          ),
          const SizedBox(height: 12),
          Text(
            'Tips',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '• Keep the file around 512 KB or smaller so it loads quickly.\n'
            '• A square crop works best for the circular avatar.\n'
            '• Direct image URLs (ending in .jpg / .png) also work if the file is publicly reachable.\n'
            '• If Test image fails, the link is usually still private — check “Anyone with the link”.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => launchUrlString('https://imagecompressor.com'),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Online image compressor'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTestImageClick() async {
    final sanitized = _sanitiseSrc();
    if (sanitized.isEmpty) return;

    setState(() {
      _testing = true;
      _previewSrc = sanitized;
      _imageValidated = false;
      _canSave = false;
      _validationMessage = null;
    });

    try {
      final imageUrl = NetworkImageHelper.getImageUrl(sanitized);
      // No custom headers: Flutter web CORS preflight fails if User-Agent is set.
      final response =
          await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final sizeKb = response.bodyBytes.length / 1024;
      if (sizeKb > 512) {
        if (!mounted) return;
        setState(() {
          _testing = false;
          _imageValidated = false;
          _canSave = false;
          _validationMessage =
              'File is ${sizeKb.toStringAsFixed(0)} KB (max 512 KB). Compress it, then try again.';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _testing = false;
        _imageValidated = true;
        _canSave = sanitized != _appContext.currentUser.imgSrc;
        _validationMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _imageValidated = false;
        _canSave = false;
        _validationMessage =
            'Could not load that image. Check the link is public (“Anyone with the link”) and try again.';
      });
    }
  }

  Future<void> _onSaveClick() async {
    final sanitized = _sanitiseSrc();
    if (!_imageValidated || sanitized.isEmpty) return;

    final saved = await DialogManager.runWithSteppedProgressDialog(
      context: context,
      title: 'Saving photo',
      initialMessage: 'Updating profile…',
      errorTitle: 'Could not save photo',
      action: (onProgress) async {
        const total = 2;
        onProgress(completed: 0, total: total, message: 'Updating profile…');
        await _userDBManager.updateUserImgSrc(_appContext.currentUser.id, sanitized);
        onProgress(completed: 1, total: total, message: 'Caching photo…');
        await _cacheLocalImage(sanitized);
        if (!mounted) return;
        _appContext.setNewUserImage(sanitized);
        _syncAllUsersImgSrc(sanitized);
        _appContext.rebuildPlease();
      },
    );

    if (!mounted || !saved) return;

    setState(() {
      _previewSrc = sanitized;
      _canSave = false;
      _imageValidated = true;
      _testing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile picture updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _isSaved = true;
    _popRouteAfterAllowing(result: true);
  }

  void _syncAllUsersImgSrc(String src) {
    final uid = _appContext.currentUser.id;
    final index = _appContext.allUsers.indexWhere((u) => u.id == uid);
    if (index == -1) return;
    final existing = _appContext.allUsers[index];
    existing.setImgSrc(src);
  }

  Future<void> _cacheLocalImage(String src) async {
    final localDataManager = LocalDataManager();
    final imageUrl = NetworkImageHelper.getImageUrl(src);
    final response = await http.get(Uri.parse(imageUrl));
    await localDataManager.writeUserImage(_appContext.currentUser.id, response.bodyBytes);
    debugPrint('Cached profile image for: ${_appContext.currentUser.id}');
  }

  String _sanitiseSrc() {
    final raw = _tecImgSrc.text.trim();
    final match = _driveRegExp.firstMatch(raw) ?? _driveRegExpLoose.firstMatch(raw);
    if (match != null) {
      return 'https://drive.google.com/uc?id=${match.group(1)!}';
    }
    return raw;
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text('$number', style: theme.textTheme.labelSmall),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
