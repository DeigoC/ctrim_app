import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/user_location_db_manager.dart';
import '../../models/user_location.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/role_access_gate.dart';
import '../events/add_media_file_page.dart';

/// Area-admin editor for a location's photo gallery and cover.
class EditUserLocationMediaPage extends StatefulWidget {
  const EditUserLocationMediaPage({super.key, required this.location});

  final UserLocation location;

  @override
  State<EditUserLocationMediaPage> createState() =>
      _EditUserLocationMediaPageState();
}

class _EditUserLocationMediaPageState extends State<EditUserLocationMediaPage> {
  final UserLocationDBManager _locationDBManager = UserLocationDBManager();
  late final List<Map<String, dynamic>> _media;
  late final List<String> _initialSrcs;
  String? _keyGraphicSrc;
  late final String? _initialKeyGraphicSrc;
  bool _saving = false;
  bool _allowPop = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _media =
        widget.location.media.map((e) => Map<String, dynamic>.from(e)).toList();
    _initialSrcs =
        _media.map((e) => (e['src'] as String?) ?? '').toList(growable: false);
    _keyGraphicSrc = widget.location.keyGraphicSrc;
    _initialKeyGraphicSrc = _keyGraphicSrc;
  }

  bool _hasUnsavedChanges() {
    if (_keyGraphicSrc != _initialKeyGraphicSrc) return true;
    final currentSrcs = _media.map((e) => (e['src'] as String?) ?? '').toList();
    if (currentSrcs.length != _initialSrcs.length) return true;
    for (var i = 0; i < currentSrcs.length; i++) {
      if (currentSrcs[i] != _initialSrcs[i]) return true;
    }
    return false;
  }

  void _popRouteAfterAllowing() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return RoleAccessGate(
      allow: (user) => user.canManageVolunteers,
      deniedMessage: 'Only area admins can manage user locations.',
      child: PopScope(
        canPop: _allowPop || _isSaved,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop || _allowPop || _isSaved) return;
          if (!_hasUnsavedChanges()) {
            _popRouteAfterAllowing();
            return;
          }
          final shouldPop =
              await DialogManager.discardChanges(context: context);
          if (shouldPop && mounted) _popRouteAfterAllowing();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.location.name),
            actions: [
              TextButton(
                onPressed: _saving ? null : _save,
                child: Text(l10n.save),
              ),
            ],
          ),
          body: ResponsiveContent(
            narrowPadding: 16,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Text(
                  l10n.manageUserLocationsPhotos,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.manageUserLocationsPhotosHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (_media.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.manageUserLocationsPhotosEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ..._media.map(_buildMediaTile),
                if (_media.length < UserLocation.maxMediaItems)
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _addPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(l10n.manageUserLocationsAddPhoto),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaTile(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final src = (item['src'] as String?) ?? '';
    final isCover = src.isNotEmpty && src == _keyGraphicSrc;
    final title = (item['title'] as String?)?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 56,
            height: 56,
            child: src.isEmpty
                ? ColoredBox(
                    color: colorScheme.surfaceContainerHigh,
                    child: Icon(Icons.image_outlined,
                        color: colorScheme.onSurfaceVariant),
                  )
                : Image.network(
                    NetworkImageHelper.getImageUrl(src),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: colorScheme.surfaceContainerHigh,
                      child: Icon(Icons.broken_image_outlined,
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ),
          ),
        ),
        title: Text(
          (title != null && title.isNotEmpty)
              ? title
              : l10n.manageUserLocationsPhotoFallback,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          isCover
              ? l10n.manageUserLocationsCoverPhoto
              : l10n.manageUserLocationsSetAsCover,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isCover ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: isCover ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: src.isEmpty || _saving
            ? null
            : () => setState(() {
                  _keyGraphicSrc = isCover ? null : src;
                }),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: colorScheme.error,
          tooltip: l10n.manageUserLocationsRemovePhoto,
          onPressed: _saving
              ? null
              : () => setState(() {
                    _media.removeWhere((e) => e['src'] == src);
                    if (_keyGraphicSrc == src) _keyGraphicSrc = null;
                  }),
        ),
      ),
    );
  }

  Future<void> _addPhoto() async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMediaFilePage(
          eventContext:
              EventContext.adding(currentUserID: appContext.currentUser.id),
          returnResultOnly: true,
        ),
      ),
    );
    if (!mounted || result == null) return;

    final type = (result['type'] as String?) ?? 'img';
    if (type != 'img') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .manageUserLocationsPhotosImagesOnly)),
      );
      return;
    }

    final src = (result['src'] as String?) ?? '';
    if (src.isEmpty) return;
    if (_media.any((e) => e['src'] == src)) return;
    if (_media.length >= UserLocation.maxMediaItems) return;

    setState(() {
      _media.add({
        'src': src,
        'type': 'img',
        'title': result['title'] ?? '',
        'thumbnailSrc': result['thumbnailSrc'],
      });
      _keyGraphicSrc ??= src;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final location = widget.location;
      location.setMedia(_media);
      location.setKeyGraphicSrc(_keyGraphicSrc);
      await _locationDBManager.updateLocation(location);
      if (!mounted) return;
      final appContext = Provider.of<AppContext>(context, listen: false);
      appContext.addOrUpdateLocation(location);
      await UserActivityRecorder().record(
        actorUserId: appContext.currentUser.id,
        log: UserActivityMessages.editedLocation,
        documentId: location.id,
      );
      _isSaved = true;
      _popRouteAfterAllowing();
    } finally {
      if (mounted && !_isSaved) setState(() => _saving = false);
    }
  }
}
