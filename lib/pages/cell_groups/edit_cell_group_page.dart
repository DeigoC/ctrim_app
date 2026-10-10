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
import '../../utility/responsive_layout.dart';
import '../../utility/uk_postcode_lookup.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../widgets/information/info_section_card.dart';
import '../../widgets/media/cached_image_widget.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/role_access_gate.dart';
import '../../widgets/two_column_masonry.dart';
import '../../widgets/user_avatar.dart';
import '../events/add_media_file_page.dart';
import '../events/select_period_parent_page.dart';
import '../personal/select_users_page.dart';
import 'select_meeting_template_page.dart';

part 'edit_cell_group_form.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final wide = ResponsiveLayout.isWideScreenOf(context);
    final sections = <Widget>[
      _whenWhereCard(l10n),
      _meetingCard(l10n),
      _statusCard(l10n),
      _photosCard(l10n),
      _leadersCard(l10n),
    ];

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
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            title:
                Text(_isEditing ? l10n.cellGroupsEdit : l10n.cellGroupsCreate),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: FilledButton.tonal(
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.save),
                  ),
                ),
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
                  _aboutCard(l10n),
                  const SizedBox(height: 16),
                  if (wide)
                    TwoColumnMasonry(children: sections)
                  else
                    for (var i = 0; i < sections.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      sections[i],
                    ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editorCard({
    required IconData icon,
    required String title,
    String subtitle = '',
    required List<Widget> children,
  }) {
    return InfoSectionCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _aboutCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final nameField = TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: _cellGroupFieldDecoration(
        colorScheme,
        label: l10n.cellGroupsNameLabel,
        hintText: l10n.cellGroupsNameHint,
        helperText: l10n.cellGroupsNameHelper,
        prefixIcon: Icons.badge_outlined,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? l10n.cellGroupsNameRequired : null,
    );
    final summaryField = TextFormField(
      controller: _summaryController,
      minLines: 4,
      maxLines: null,
      textCapitalization: TextCapitalization.sentences,
      decoration: _cellGroupFieldDecoration(
        colorScheme,
        label: l10n.cellGroupsSummaryLabel,
        hintText: l10n.cellGroupsSummaryHint,
        helperText: l10n.cellGroupsSummaryHelper,
        alignLabelWithHint: true,
        prefixIcon: Icons.notes_outlined,
      ),
    );

    return _editorCard(
      icon: Icons.info_outline,
      title: l10n.cellGroupsAboutTitle,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = constraints.maxWidth >= 640;
            if (!sideBySide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nameField,
                  const SizedBox(height: 12),
                  summaryField,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: nameField),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: summaryField),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _whenWhereCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return _editorCard(
      icon: Icons.place_outlined,
      title: l10n.cellGroupsEditorWhenWhereTitle,
      children: [
        _pairWhenWide(
          _locationField(l10n, colorScheme),
          _postcodeField(l10n, colorScheme),
        ),
        const SizedBox(height: 12),
        _pairWhenWide(
          _weekdayField(l10n, colorScheme),
          _timeField(l10n, colorScheme),
        ),
      ],
    );
  }

  Widget _locationField(AppLocalizations l10n, ColorScheme colorScheme) {
    return InputDecorator(
      decoration: _cellGroupFieldDecoration(
        colorScheme,
        label: l10n.cellGroupsLocationLabel,
        helperText: l10n.cellGroupsLocationHelper,
        prefixIcon: Icons.location_on_outlined,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
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
    );
  }

  Widget _postcodeField(AppLocalizations l10n, ColorScheme colorScheme) {
    return TextFormField(
      controller: _postcodeController,
      textCapitalization: TextCapitalization.characters,
      decoration: _cellGroupFieldDecoration(
        colorScheme,
        label: l10n.cellGroupsPostcodeLabel,
        hintText: l10n.cellGroupsPostcodeHint,
        helperText: l10n.cellGroupsPostcodeHelper,
        helperMaxLines: 3,
        errorText: _postcodeLookupError,
        prefixIcon: Icons.markunread_mailbox_outlined,
      ),
      onChanged: (_) {
        if (_postcodeLookupError != null) {
          setState(() => _postcodeLookupError = null);
        }
      },
      validator: (v) {
        final raw = v?.trim() ?? '';
        if (raw.isEmpty) return null;
        if (UkPostcodeLookup.classify(raw) == UkPostcodeKind.none) {
          return l10n.cellGroupsPostcodeInvalid;
        }
        return null;
      },
    );
  }

  Widget _weekdayField(AppLocalizations l10n, ColorScheme colorScheme) {
    return InputDecorator(
      decoration: _cellGroupFieldDecoration(
        colorScheme,
        label: l10n.cellGroupsWeekdayLabel,
        helperText: l10n.cellGroupsWeekdayHelper,
        prefixIcon: Icons.calendar_today_outlined,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          value: _weekday,
          items: [
            DropdownMenuItem(
                value: null, child: Text(l10n.cellGroupsWeekdayNotSet)),
            const DropdownMenuItem(
                value: DateTime.monday, child: Text('Monday')),
            const DropdownMenuItem(
                value: DateTime.tuesday, child: Text('Tuesday')),
            const DropdownMenuItem(
                value: DateTime.wednesday, child: Text('Wednesday')),
            const DropdownMenuItem(
                value: DateTime.thursday, child: Text('Thursday')),
            const DropdownMenuItem(
                value: DateTime.friday, child: Text('Friday')),
            const DropdownMenuItem(
                value: DateTime.saturday, child: Text('Saturday')),
            const DropdownMenuItem(
                value: DateTime.sunday, child: Text('Sunday')),
          ],
          onChanged: (v) => setState(() => _weekday = v),
        ),
      ),
    );
  }

  Widget _timeField(AppLocalizations l10n, ColorScheme colorScheme) {
    return TextFormField(
      controller: _timeController,
      decoration: _cellGroupFieldDecoration(
        colorScheme,
        label: l10n.cellGroupsTimeLabel,
        hintText: l10n.cellGroupsTimeHint,
        helperText: l10n.cellGroupsTimeHelper,
        prefixIcon: Icons.schedule_outlined,
      ),
    );
  }

  Widget _meetingCard(AppLocalizations l10n) {
    return _editorCard(
      icon: Icons.post_add_outlined,
      title: l10n.cellGroupsMeetingPostsTitle,
      subtitle: l10n.cellGroupsMeetingPostsHelper,
      children: [
        _MeetingSetupField(
          label: l10n.cellGroupsMeetingParentLabel,
          helper: l10n.cellGroupsMeetingParentHelper,
          prefixIcon: Icons.account_tree_outlined,
          value: _parentFieldValue(l10n),
          valueIsError:
              _meetingParentIssue != null || _meetingParentLookupFailed,
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
        const SizedBox(height: 12),
        _MeetingSetupField(
          label: l10n.cellGroupsMeetingTemplateLabel,
          helper: l10n.cellGroupsMeetingTemplateHelper,
          prefixIcon: Icons.article_outlined,
          value: _templateFieldValue(l10n),
          valueIsError: _meetingTemplateMissing || _meetingTemplateLookupFailed,
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
      ],
    );
  }

  Widget _statusCard(AppLocalizations l10n) {
    return _editorCard(
      icon: Icons.flag_outlined,
      title: l10n.cellGroupsStatusLabel,
      subtitle: l10n.cellGroupsStatusHelper,
      children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: [
            ButtonSegment(
              value: CellGroupStatus.active,
              label: Text(l10n.cellGroupsStatusActive),
            ),
            ButtonSegment(
              value: CellGroupStatus.paused,
              label: Text(l10n.cellGroupsStatusPaused),
            ),
            ButtonSegment(
              value: CellGroupStatus.archived,
              label: Text(l10n.cellGroupsStatusArchived),
            ),
          ],
          selected: {_status},
          onSelectionChanged: (next) {
            if (next.isEmpty) return;
            setState(() => _status = next.first);
          },
        ),
      ],
    );
  }

  Widget _photosCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return _editorCard(
      icon: Icons.photo_library_outlined,
      title: l10n.cellGroupsPhotosTitle,
      subtitle: l10n.cellGroupsPhotosHint,
      children: [
        if (_media.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.cellGroupsPhotosEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        _CellGroupPhotoGrid(
          media: _media,
          keyGraphicSrc: _keyGraphicSrc,
          canAdd: _media.length < CellGroup.maxMediaItems,
          onAdd: _addPhoto,
          onToggleCover: (src) => setState(() {
            _keyGraphicSrc = _keyGraphicSrc == src ? null : src;
          }),
          onRemove: (src) => setState(() {
            _media.removeWhere((e) => e['src'] == src);
            if (_keyGraphicSrc == src) _keyGraphicSrc = null;
          }),
        ),
      ],
    );
  }

  Widget _leadersCard(AppLocalizations l10n) {
    return _editorCard(
      icon: Icons.groups_outlined,
      title: l10n.cellGroupsLeadersLabel,
      subtitle: l10n.cellGroupsLeadersHint,
      children: [
        OutlinedButton.icon(
          onPressed: _pickLeaders,
          icon: const Icon(Icons.person_add_alt),
          label: Text(l10n.cellGroupsChooseLeaders),
        ),
        if (_leaderUserIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CellGroupLeaderWrap(
            userIds: _leaderUserIds,
            userById: _userById,
            onRemove: (uid) => setState(() => _leaderUserIds.remove(uid)),
          ),
        ],
      ],
    );
  }

  /// Puts [leading] and [trailing] on one row once the card is wide enough
  /// for two fields. Narrow cards keep them stacked.
  Widget _pairWhenWide(Widget leading, Widget trailing) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leading,
              const SizedBox(height: 12),
              trailing,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leading),
            const SizedBox(width: 12),
            Expanded(child: trailing),
          ],
        );
      },
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
            title: group.name,
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
            title: created.name,
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
    return Provider.of<AppContext>(context, listen: false).userById(id);
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
