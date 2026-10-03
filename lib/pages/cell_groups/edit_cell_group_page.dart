import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/db_managers/post_template_db_manager.dart';
import '../../models/cell_group.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/cell_group_meeting_setup.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../utility/event_context.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/uk_postcode_lookup.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/role_access_gate.dart';
import '../../widgets/user_avatar.dart';
import '../events/add_media_file_page.dart';
import '../events/select_period_parent_page.dart';
import '../personal/select_users_page.dart';
import 'select_meeting_template_page.dart';

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
  late final TextEditingController _postcodeController;
  late String _status;
  late String _location;
  int? _weekday;
  String? _postcodeLookupError;
  late List<String> _leaderUserIds;
  late List<Map<String, dynamic>> _media;
  String? _keyGraphicSrc;
  String? _meetingParentPostId;
  String? _meetingParentTitle;
  CellGroupMeetingParentIssue? _meetingParentIssue;
  String? _meetingTemplateId;
  String? _meetingTemplateTitle;
  bool _meetingTemplateMissing = false;
  bool _meetingParentLookupFailed = false;
  bool _meetingTemplateLookupFailed = false;
  bool _resolvingMeetingSetup = false;
  bool _saving = false;
  bool _isSaved = false;
  bool _allowPop = false;

  late final String _initialName;
  late final String _initialSummary;
  late final String _initialTime;
  late final String _initialStatus;
  late final String _initialLocation;
  late final String _initialPostcode;
  late final int? _initialWeekday;
  late final List<String> _initialLeaderUserIds;
  late final List<String> _initialMediaSrcs;
  late final String? _initialKeyGraphicSrc;
  late final String? _initialMeetingParentPostId;
  late final String? _initialMeetingTemplateId;

  bool get _isEditing => widget.existing != null;

  void _popRouteAfterAllowing({Object? result}) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final appContext = Provider.of<AppContext>(context, listen: false);
    final locationOptions =
        VolunteerLocations.assignableFrom(appContext.allLocations);
    _initialName = existing?.name ?? '';
    _initialSummary = existing?.summary ?? '';
    _initialTime = existing?.meetingTime ?? '';
    _initialStatus = existing?.status ?? CellGroupStatus.active;
    _initialLocation = existing?.location ??
        VolunteerLocations.defaultFilterForUser(
          appContext.currentUser.location,
          locationOptions,
        );
    _initialPostcode = existing?.postcode ?? '';
    _initialWeekday = existing?.meetingWeekday;
    _initialLeaderUserIds =
        List<String>.from(existing?.leaderUserIds ?? const []);
    _initialMediaSrcs = existing?.media
            .map((e) => (e['src'] as String?) ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    _initialKeyGraphicSrc = existing?.keyGraphicSrc;
    _initialMeetingParentPostId = existing?.meetingParentPostId;
    _initialMeetingTemplateId = existing?.meetingTemplateId;

    _nameController = TextEditingController(text: _initialName);
    _summaryController = TextEditingController(text: _initialSummary);
    _timeController = TextEditingController(text: _initialTime);
    _postcodeController = TextEditingController(text: _initialPostcode);
    _status = _initialStatus;
    _location = _initialLocation;
    _weekday = _initialWeekday;
    _leaderUserIds = List<String>.from(_initialLeaderUserIds);
    _media =
        existing?.media.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    _keyGraphicSrc = _initialKeyGraphicSrc;
    _meetingParentPostId = _initialMeetingParentPostId;
    _meetingTemplateId = _initialMeetingTemplateId;
    if (_meetingParentPostId != null || _meetingTemplateId != null) {
      _resolvingMeetingSetup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveMeetingLabels();
      });
    }
  }

  bool _hasUnsavedChanges() {
    if (_nameController.text.trim() != _initialName.trim()) return true;
    if (_summaryController.text.trim() != _initialSummary.trim()) return true;
    if (_timeController.text.trim() != _initialTime.trim()) return true;
    if (_location != _initialLocation) return true;
    if (_postcodeController.text.trim() != _initialPostcode.trim()) return true;
    if (_status != _initialStatus) return true;
    if (_weekday != _initialWeekday) return true;
    if (!_sameIdLists(_leaderUserIds, _initialLeaderUserIds)) return true;
    if (_keyGraphicSrc != _initialKeyGraphicSrc) return true;
    if (_meetingParentPostId != _initialMeetingParentPostId) return true;
    if (_meetingTemplateId != _initialMeetingTemplateId) return true;
    final currentSrcs = _media
        .map((e) => (e['src'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (!_sameIdLists(currentSrcs, _initialMediaSrcs)) return true;
    return false;
  }

  bool _sameIdLists(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    _timeController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return RoleAccessGate(
      allow: (user) => user.canManageCellGroups,
      deniedMessage: 'Only area admins can create or edit cell groups.',
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
          if (shouldPop && mounted) {
            _popRouteAfterAllowing();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title:
                Text(_isEditing ? l10n.cellGroupsEdit : l10n.cellGroupsCreate),
            actions: [
              TextButton(
                onPressed: _saving ? null : _save,
                child: Text(l10n.save),
              ),
            ],
          ),
          body: ResponsiveContent(
            narrowPadding: 16,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.cellGroupsNameLabel,
                      hintText: l10n.cellGroupsNameHint,
                      helperText: l10n.cellGroupsNameHelper,
                      helperMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.cellGroupsNameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _summaryController,
                    minLines: 6,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.cellGroupsSummaryLabel,
                      hintText: l10n.cellGroupsSummaryHint,
                      helperText: l10n.cellGroupsSummaryHelper,
                      helperMaxLines: 2,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.cellGroupsLocationLabel,
                      helperText: l10n.cellGroupsLocationHelper,
                      helperMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _locationDropdownValue(),
                        items: _locationOptions()
                            .map((location) => DropdownMenuItem<String>(
                                  value: location,
                                  child: Text(location),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _location = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _postcodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.cellGroupsPostcodeLabel,
                      hintText: l10n.cellGroupsPostcodeHint,
                      helperText: l10n.cellGroupsPostcodeHelper,
                      helperMaxLines: 3,
                      errorText: _postcodeLookupError,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      if (_postcodeLookupError != null) {
                        setState(() => _postcodeLookupError = null);
                      }
                    },
                    validator: (v) {
                      final raw = v?.trim() ?? '';
                      if (raw.isEmpty) return null;
                      if (UkPostcodeLookup.classify(raw) ==
                          UkPostcodeKind.none) {
                        return l10n.cellGroupsPostcodeInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.cellGroupsWeekdayLabel,
                      helperText: l10n.cellGroupsWeekdayHelper,
                      helperMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: _weekday,
                        items: [
                          DropdownMenuItem(
                              value: null,
                              child: Text(l10n.cellGroupsWeekdayNotSet)),
                          const DropdownMenuItem(
                              value: DateTime.monday, child: Text('Monday')),
                          const DropdownMenuItem(
                              value: DateTime.tuesday, child: Text('Tuesday')),
                          const DropdownMenuItem(
                              value: DateTime.wednesday,
                              child: Text('Wednesday')),
                          const DropdownMenuItem(
                              value: DateTime.thursday,
                              child: Text('Thursday')),
                          const DropdownMenuItem(
                              value: DateTime.friday, child: Text('Friday')),
                          const DropdownMenuItem(
                              value: DateTime.saturday,
                              child: Text('Saturday')),
                          const DropdownMenuItem(
                              value: DateTime.sunday, child: Text('Sunday')),
                        ],
                        onChanged: (v) => setState(() => _weekday = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: l10n.cellGroupsTimeLabel,
                      hintText: l10n.cellGroupsTimeHint,
                      helperText: l10n.cellGroupsTimeHelper,
                      helperMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.cellGroupsMeetingPostsTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.cellGroupsMeetingPostsHelper,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MeetingSetupField(
                    label: l10n.cellGroupsMeetingParentLabel,
                    helper: l10n.cellGroupsMeetingParentHelper,
                    value: _parentFieldValue(l10n),
                    valueIsError: _meetingParentIssue != null ||
                        _meetingParentLookupFailed,
                    onPick: _pickParent,
                    onClear: _meetingParentPostId == null
                        ? null
                        : () => setState(() {
                              _meetingParentPostId = null;
                              _meetingParentTitle = null;
                              _meetingParentIssue = null;
                              _meetingParentLookupFailed = false;
                            }),
                  ),
                  const SizedBox(height: 16),
                  _MeetingSetupField(
                    label: l10n.cellGroupsMeetingTemplateLabel,
                    helper: l10n.cellGroupsMeetingTemplateHelper,
                    value: _templateFieldValue(l10n),
                    valueIsError:
                        _meetingTemplateMissing || _meetingTemplateLookupFailed,
                    onPick: _pickTemplate,
                    onClear: _meetingTemplateId == null
                        ? null
                        : () => setState(() {
                              _meetingTemplateId = null;
                              _meetingTemplateTitle = null;
                              _meetingTemplateMissing = false;
                              _meetingTemplateLookupFailed = false;
                            }),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.cellGroupsStatusLabel,
                      helperText: l10n.cellGroupsStatusHelper,
                      helperMaxLines: 3,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _status,
                        items: [
                          DropdownMenuItem(
                              value: CellGroupStatus.active,
                              child: Text(l10n.cellGroupsStatusActive)),
                          DropdownMenuItem(
                              value: CellGroupStatus.paused,
                              child: Text(l10n.cellGroupsStatusPaused)),
                          DropdownMenuItem(
                              value: CellGroupStatus.archived,
                              child: Text(l10n.cellGroupsStatusArchived)),
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
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
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
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.cellGroupsLeadersHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickLeaders,
                    icon: const Icon(Icons.person_add_alt),
                    label: Text(l10n.cellGroupsChooseLeaders),
                  ),
                  ..._leaderUserIds.map(_buildLeaderTile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderTile(String uid) {
    final user = _userById(uid);
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: user != null
          ? MyUserAvatar(user, radius: 20)
          : CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child:
                  Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
            ),
      title: Text(user?.fullname ?? 'Unknown leader'),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() => _leaderUserIds.remove(uid)),
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
              : (isCover ? l10n.cellGroupsCoverPhoto : 'Image'),
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
            content:
                Text(AppLocalizations.of(context)!.cellGroupsPhotosImagesOnly)),
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

  String _parentFieldValue(AppLocalizations l10n) {
    if (_meetingParentIssue == CellGroupMeetingParentIssue.missing) {
      return l10n.cellGroupsMeetingParentMissing;
    }
    if (_meetingParentIssue == CellGroupMeetingParentIssue.notPeriodParent) {
      return l10n.cellGroupsMeetingParentNotPeriod;
    }
    if (_meetingParentLookupFailed) {
      return l10n.cellGroupsMeetingLookupFailed;
    }
    if (_meetingParentTitle != null && _meetingParentTitle!.isNotEmpty) {
      return _meetingParentTitle!;
    }
    if (_resolvingMeetingSetup && _meetingParentPostId != null) {
      return l10n.cellGroupsMeetingLookingUp;
    }
    return l10n.cellGroupsMeetingParentNotSet;
  }

  String _templateFieldValue(AppLocalizations l10n) {
    if (_meetingTemplateMissing) return l10n.cellGroupsMeetingTemplateInvalid;
    if (_meetingTemplateLookupFailed) {
      return l10n.cellGroupsMeetingLookupFailed;
    }
    if (_meetingTemplateTitle != null && _meetingTemplateTitle!.isNotEmpty) {
      return _meetingTemplateTitle!;
    }
    if (_resolvingMeetingSetup && _meetingTemplateId != null) {
      return l10n.cellGroupsMeetingLookingUp;
    }
    return l10n.cellGroupsMeetingTemplateNotSet;
  }

  Future<void> _resolveMeetingLabels() async {
    final parentId = _meetingParentPostId;
    final templateId = _meetingTemplateId;
    String? parentTitle;
    CellGroupMeetingParentIssue? parentIssue;
    String? templateTitle;
    var templateMissing = false;
    try {
      if (parentId != null) {
        final head = await EventHeadDBManager().fetchHeadIfExists(parentId);
        parentIssue = CellGroupMeetingSetup.parentIssue(
          exists: head != null,
          isPeriodParent: head?.isPeriodParent ?? false,
        );
        if (parentIssue == null) parentTitle = head!.title;
      }
      if (templateId != null) {
        final template =
            await PostTemplateDBManager().fetchTemplate(templateId);
        if (template == null) {
          templateMissing = true;
        } else {
          templateTitle = template.title;
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolvingMeetingSetup = false;
        _meetingParentLookupFailed = _meetingParentPostId != null;
        _meetingTemplateLookupFailed = _meetingTemplateId != null;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _meetingParentTitle = parentTitle;
      _meetingParentIssue = parentIssue;
      _meetingTemplateTitle = templateTitle;
      _meetingTemplateMissing = templateMissing;
      _meetingParentLookupFailed = false;
      _meetingTemplateLookupFailed = false;
      _resolvingMeetingSetup = false;
    });
  }

  Future<void> _pickParent() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectPeriodParentPage(
          currentParentID: _meetingParentPostId,
        ),
      ),
    );
    if (!mounted || result == null) return;
    if (result.isEmpty) {
      setState(() {
        _meetingParentPostId = null;
        _meetingParentTitle = null;
        _meetingParentIssue = null;
        _meetingParentLookupFailed = false;
      });
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    try {
      final head = await EventHeadDBManager().fetchHeadIfExists(result);
      if (!mounted) return;
      final issue = CellGroupMeetingSetup.parentIssue(
        exists: head != null,
        isPeriodParent: head?.isPeriodParent ?? false,
      );
      if (issue != null || head == null) {
        await DialogManager.showAlertDialog(
          context: context,
          title: l10n.cellGroupsMeetingParentInvalidTitle,
          content: issue == CellGroupMeetingParentIssue.notPeriodParent
              ? l10n.cellGroupsMeetingParentNotPeriod
              : l10n.cellGroupsMeetingParentMissing,
          isError: true,
        );
        return;
      }
      setState(() {
        _meetingParentPostId = head.id;
        _meetingParentTitle = head.title;
        _meetingParentIssue = null;
        _meetingParentLookupFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      await DialogManager.showAlertDialog(
        context: context,
        title: l10n.cellGroupsMeetingParentInvalidTitle,
        content: l10n.cellGroupsMeetingParentLookupFailed,
        isError: true,
      );
    }
  }

  Future<void> _pickTemplate() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectMeetingTemplatePage(
          currentTemplateId: _meetingTemplateId,
          cellGroupId: widget.existing?.id,
        ),
      ),
    );
    if (!mounted || result == null) return;
    if (result.isEmpty) {
      setState(() {
        _meetingTemplateId = null;
        _meetingTemplateTitle = null;
        _meetingTemplateMissing = false;
        _meetingTemplateLookupFailed = false;
      });
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    try {
      final template = await PostTemplateDBManager().fetchTemplate(result);
      if (!mounted) return;
      if (template == null) {
        await DialogManager.showAlertDialog(
          context: context,
          title: l10n.cellGroupsMeetingTemplateInvalidTitle,
          content: l10n.cellGroupsMeetingTemplateInvalid,
          isError: true,
        );
        return;
      }
      setState(() {
        _meetingTemplateId = template.id;
        _meetingTemplateTitle = template.title;
        _meetingTemplateMissing = false;
        _meetingTemplateLookupFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      await DialogManager.showAlertDialog(
        context: context,
        title: l10n.cellGroupsMeetingTemplateInvalidTitle,
        content: l10n.cellGroupsMeetingTemplateInvalid,
        isError: true,
      );
    }
  }

  /// Re-checks the stored ids and, when editing, asks before keeping a template
  /// that does not list this group. Returns false when save should stop.
  Future<bool> _confirmMeetingSetup(AppLocalizations l10n) async {
    final parentId = _meetingParentPostId;
    final templateId = _meetingTemplateId;
    if (parentId == null && templateId == null) return true;

    var parentOk = true;
    var templateOk = true;
    var templateLinksGroup = true;
    String? parentTitle;
    String? templateTitle;
    CellGroupMeetingParentIssue? parentIssue;
    try {
      if (parentId != null) {
        final head = await EventHeadDBManager().fetchHeadIfExists(parentId);
        parentIssue = CellGroupMeetingSetup.parentIssue(
          exists: head != null,
          isPeriodParent: head?.isPeriodParent ?? false,
        );
        parentOk = parentIssue == null;
        if (parentOk) parentTitle = head!.title;
      }
      if (templateId != null) {
        final template =
            await PostTemplateDBManager().fetchTemplate(templateId);
        if (template == null) {
          templateOk = false;
        } else {
          templateTitle = template.title;
          final groupId = widget.existing?.id ?? '';
          templateLinksGroup = groupId.isEmpty ||
              CellGroupMeetingSetup.templateIncludesGroup(
                template.cellGroupIDs,
                groupId,
              );
        }
      }
    } catch (_) {
      if (!mounted) return false;
      await DialogManager.showAlertDialog(
        context: context,
        title: l10n.cellGroupsMeetingParentInvalidTitle,
        content: l10n.cellGroupsMeetingParentLookupFailed,
        isError: true,
      );
      return false;
    }
    if (!mounted) return false;
    setState(() {
      _meetingParentTitle = parentTitle;
      _meetingParentIssue = parentIssue;
      _meetingTemplateTitle = templateTitle;
      _meetingTemplateMissing = !templateOk && templateId != null;
      _meetingParentLookupFailed = false;
      _meetingTemplateLookupFailed = false;
    });
    if (!parentOk) {
      await DialogManager.showAlertDialog(
        context: context,
        title: l10n.cellGroupsMeetingParentInvalidTitle,
        content: parentIssue == CellGroupMeetingParentIssue.notPeriodParent
            ? l10n.cellGroupsMeetingParentNotPeriod
            : l10n.cellGroupsMeetingParentMissing,
        isError: true,
      );
      return false;
    }
    if (!templateOk) {
      await DialogManager.showAlertDialog(
        context: context,
        title: l10n.cellGroupsMeetingTemplateInvalidTitle,
        content: l10n.cellGroupsMeetingTemplateInvalid,
        isError: true,
      );
      return false;
    }
    if (!templateLinksGroup) {
      final proceed = await DialogManager.showConfirmationDialog(
        context: context,
        title: l10n.cellGroupsMeetingTemplateUnlinkedTitle,
        content: l10n.cellGroupsMeetingTemplateUnlinkedBody,
        confirmText: l10n.save,
      );
      if (!proceed || !mounted) return false;
    }
    return true;
  }

  Future<void> _pickLeaders() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: List<String>.from(_leaderUserIds),
          includeCurrentUser: true,
          title: AppLocalizations.of(context)!.cellGroupsLeadersLabel,
          preferServing: true,
          allowCreatePlaceholder: canCreatePlaceholderUser(
            actor: Provider.of<AppContext>(context, listen: false).currentUser,
          ),
          cellGroupIdForPlaceholderCreate: widget.existing?.id,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _leaderUserIds = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final appContext = Provider.of<AppContext>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final summary = _summaryController.text.trim();
    final time = _timeController.text.trim();
    final location = _location;
    final authIds = _leaderUserIds
        .map((id) => _userById(id)?.authID ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final mediaCopy = _media.map((e) => Map<String, dynamic>.from(e)).toList();
    final keySrc = (_keyGraphicSrc != null &&
            mediaCopy.any((e) => e['src'] == _keyGraphicSrc))
        ? _keyGraphicSrc
        : null;

    String? postcode;
    double? latitude;
    double? longitude;
    final rawPostcode = _postcodeController.text.trim();
    if (rawPostcode.isNotEmpty) {
      final existing = widget.existing;
      final normalised = UkPostcodeLookup.normalize(rawPostcode);
      if (normalised == null) {
        setState(() => _postcodeLookupError = l10n.cellGroupsPostcodeInvalid);
        return;
      }
      if (existing != null &&
          existing.postcode == normalised &&
          existing.hasCoordinates) {
        postcode = existing.postcode;
        latitude = existing.latitude;
        longitude = existing.longitude;
      } else {
        setState(() => _saving = true);
        try {
          final geo = await UkPostcodeLookup().lookup(rawPostcode);
          postcode = geo.label;
          latitude = geo.latitude;
          longitude = geo.longitude;
        } on UkPostcodeLookupException catch (e) {
          if (!mounted) return;
          setState(() {
            _saving = false;
            _postcodeLookupError = e.isInvalid
                ? l10n.cellGroupsPostcodeInvalid
                : l10n.cellGroupsPostcodeLookupFailed;
          });
          return;
        }
        if (!mounted) return;
        setState(() => _saving = false);
      }
    }

    if (!await _confirmMeetingSetup(l10n) || !mounted) return;

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
          group.setLocation(location);
          group.setMeetingWeekday(_weekday);
          group.setMeetingTime(time);
          group.setStatus(_status);
          group.setLeaders(userIds: _leaderUserIds, authIds: authIds);
          group.setMedia(mediaCopy);
          group.setKeyGraphicSrc(keySrc);
          group.setMeetingParentPostId(_meetingParentPostId);
          group.setMeetingTemplateId(_meetingTemplateId);
          if (postcode == null) {
            group.clearPostcodeGeo();
          } else {
            group.setPostcodeGeo(
              postcode: postcode,
              latitude: latitude!,
              longitude: longitude!,
            );
          }
          await db.updateGroup(group);
          appContext.addOrUpdateCellGroup(group);
          await UserActivityRecorder().record(
            actorUserId: appContext.currentUser.id,
            log: UserActivityMessages.editedCellGroup,
            documentId: group.id,
          );
        } else {
          final created = await db.createGroup(
            name: name,
            summary: summary,
            location: location,
            leaderUserIds: _leaderUserIds,
            leaderAuthIds: authIds,
            media: mediaCopy,
            keyGraphicSrc: keySrc,
            status: _status,
            meetingWeekday: _weekday,
            meetingTime: time,
            postcode: postcode,
            latitude: latitude,
            longitude: longitude,
            meetingParentPostId: _meetingParentPostId,
            meetingTemplateId: _meetingTemplateId,
            createdByUserID: appContext.currentUser.id,
          );
          appContext.addOrUpdateCellGroup(created);
          await UserActivityRecorder().record(
            actorUserId: appContext.currentUser.id,
            log: UserActivityMessages.createdCellGroup,
            documentId: created.id,
          );
        }
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _isSaved = true;
      _popRouteAfterAllowing(result: true);
    }
  }

  User? _userById(String id) {
    final appContext = Provider.of<AppContext>(context, listen: false);
    for (final u in appContext.allUsers) {
      if (u.id == id) return u;
    }
    return null;
  }

  List<String> _locationOptions() {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final options = List<String>.from(
      VolunteerLocations.assignableFrom(appContext.allLocations),
    );
    if (_location.isNotEmpty && !options.contains(_location)) {
      options.insert(0, _location);
    }
    return options;
  }

  String _locationDropdownValue() {
    final options = _locationOptions();
    if (options.contains(_location)) return _location;
    return options.isNotEmpty ? options.first : _location;
  }
}

class _MeetingSetupField extends StatelessWidget {
  const _MeetingSetupField({
    required this.label,
    required this.helper,
    required this.value,
    required this.valueIsError,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final String helper;
  final String value;
  final bool valueIsError;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 4,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: valueIsError ? colorScheme.error : null,
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                tooltip: l10n.cellGroupsMeetingClear,
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
