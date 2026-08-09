import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../models/cell_group.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/role_access_gate.dart';
import '../events/add_media_file_page.dart';
import '../personal/select_users_page.dart';

/// Area-admin create / edit for a cell group profile + leadership.
class EditCellGroupPage extends StatefulWidget {
  const EditCellGroupPage({super.key, this.existing});

  final CellGroup? existing;

  @override
  State<EditCellGroupPage> createState() => _EditCellGroupPageState();
}

class _EditCellGroupPageState extends State<EditCellGroupPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _summaryController;
  late final TextEditingController _timeController;
  late String _status;
  int? _weekday;
  late List<String> _leaderUserIds;
  late List<Map<String, dynamic>> _media;
  String? _keyGraphicSrc;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _summaryController = TextEditingController(text: existing?.summary ?? '');
    _timeController = TextEditingController(text: existing?.meetingTime ?? '');
    _status = existing?.status ?? CellGroupStatus.active;
    _weekday = existing?.meetingWeekday;
    _leaderUserIds = List<String>.from(existing?.leaderUserIds ?? const []);
    _media = existing?.media.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    _keyGraphicSrc = existing?.keyGraphicSrc;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final gutter = ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width);

    return RoleAccessGate(
      allow: (user) => user.canManageCellGroups,
      deniedMessage: 'Only area admins can create or edit cell groups.',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? l10n.cellGroupsEdit : l10n.cellGroupsCreate),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 32),
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summaryController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Summary',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Meeting weekday',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    isExpanded: true,
                    value: _weekday,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Not set')),
                      DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
                      DropdownMenuItem(value: DateTime.tuesday, child: Text('Tuesday')),
                      DropdownMenuItem(value: DateTime.wednesday, child: Text('Wednesday')),
                      DropdownMenuItem(value: DateTime.thursday, child: Text('Thursday')),
                      DropdownMenuItem(value: DateTime.friday, child: Text('Friday')),
                      DropdownMenuItem(value: DateTime.saturday, child: Text('Saturday')),
                      DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
                    ],
                    onChanged: (v) => setState(() => _weekday = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Meeting time',
                  hintText: 'e.g. 19:30',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _status,
                    items: [
                      DropdownMenuItem(value: CellGroupStatus.active, child: Text(l10n.cellGroupsStatusActive)),
                      DropdownMenuItem(value: CellGroupStatus.paused, child: Text(l10n.cellGroupsStatusPaused)),
                      DropdownMenuItem(value: CellGroupStatus.archived, child: Text(l10n.cellGroupsStatusArchived)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.cellGroupsPhotosTitle,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.cellGroupsPhotosHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              if (_media.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.cellGroupsPhotosEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ..._media.map(_buildMediaTile),
              if (_media.length < CellGroup.maxMediaItems)
                OutlinedButton.icon(
                  onPressed: _addPhoto,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.cellGroupsAddPhoto),
                ),
              const SizedBox(height: 16),
              Text(
                l10n.cellGroupsLeadersLabel,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickLeaders,
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Choose leaders'),
              ),
              ..._leaderUserIds.map((uid) {
                final user = _userById(uid);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(user?.fullname ?? uid),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _leaderUserIds.remove(uid)),
                  ),
                );
              }),
            ],
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
                    child: Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant),
                  )
                : Image.network(
                    NetworkImageHelper.getImageUrl(src),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: colorScheme.surfaceContainerHigh,
                      child: Icon(Icons.broken_image_outlined, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
          ),
        ),
        title: Text(
          (title != null && title.isNotEmpty) ? title : (isCover ? l10n.cellGroupsCoverPhoto : 'Image'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          isCover ? l10n.cellGroupsCoverPhoto : l10n.cellGroupsSetAsCover,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isCover ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: isCover ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: src.isEmpty
            ? null
            : () => setState(() {
                  _keyGraphicSrc = isCover ? null : src;
                }),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: colorScheme.error,
          tooltip: 'Remove',
          onPressed: () => setState(() {
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
          eventContext: EventContext.adding(currentUserID: appContext.currentUser.id),
          returnResultOnly: true,
        ),
      ),
    );
    if (!mounted || result == null) return;

    final type = (result['type'] as String?) ?? 'img';
    if (type != 'img') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cellGroupsPhotosImagesOnly)),
      );
      return;
    }

    final src = (result['src'] as String?) ?? '';
    if (src.isEmpty) return;
    if (_media.any((e) => e['src'] == src)) return;
    if (_media.length >= CellGroup.maxMediaItems) return;

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

  Future<void> _pickLeaders() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: List<String>.from(_leaderUserIds),
          includeCurrentUser: true,
          title: AppLocalizations.of(context)!.cellGroupsLeadersLabel,
          includePlaceholders: true,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _leaderUserIds = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final appContext = Provider.of<AppContext>(context, listen: false);
    final name = _nameController.text.trim();
    final summary = _summaryController.text.trim();
    final time = _timeController.text.trim();
    final authIds = _leaderUserIds
        .map((id) => _userById(id)?.authID ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final mediaCopy = _media.map((e) => Map<String, dynamic>.from(e)).toList();
    final keySrc = (_keyGraphicSrc != null && mediaCopy.any((e) => e['src'] == _keyGraphicSrc))
        ? _keyGraphicSrc
        : null;

    setState(() => _saving = true);
    final ok = await DialogManager.runWithProgressDialog(
      context: context,
      title: _isEditing ? 'Saving group…' : 'Creating group…',
      action: () async {
        final db = CellGroupDBManager();
        if (_isEditing) {
          final group = widget.existing!;
          group.setName(name);
          group.setSummary(summary);
          group.setMeetingWeekday(_weekday);
          group.setMeetingTime(time);
          group.setStatus(_status);
          group.setLeaders(userIds: _leaderUserIds, authIds: authIds);
          group.setMedia(mediaCopy);
          group.setKeyGraphicSrc(keySrc);
          await db.updateGroup(group);
          appContext.addOrUpdateCellGroup(group);
        } else {
          final created = await db.createGroup(
            name: name,
            summary: summary,
            location: 'Belfast',
            leaderUserIds: _leaderUserIds,
            leaderAuthIds: authIds,
            media: mediaCopy,
            keyGraphicSrc: keySrc,
            status: _status,
            meetingWeekday: _weekday,
            meetingTime: time,
            createdByUserID: appContext.currentUser.id,
          );
          appContext.addOrUpdateCellGroup(created);
        }
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  User? _userById(String id) {
    final appContext = Provider.of<AppContext>(context, listen: false);
    for (final u in appContext.allUsers) {
      if (u.id == id) return u;
    }
    return null;
  }
}
