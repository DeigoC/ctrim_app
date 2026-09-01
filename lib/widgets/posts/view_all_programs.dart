import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/user.dart';
import '../../pages/events/arrange_schedule_page.dart';
import '../../pages/events/edit_event_date_location_page.dart';
import '../../pages/events/edit_program_role_page.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/schedule_timeline_layout.dart';
import '../common/action_sheet.dart';
import 'schedule_role_detail_sheet.dart';
import 'schedule_timeline.dart';

class ViewAllPrograms extends StatefulWidget {
  const ViewAllPrograms({
    super.key,
    required this.eventContext,
    required this.onProgramChanged,
    this.isAddingPost = false,
    this.timeOnlySchedule = false,
  });
  final EventContext eventContext;
  final Function onProgramChanged;
  final bool isAddingPost;

  /// Post templates: show typical time only; calendar date is set when creating posts.
  final bool timeOnlySchedule;

  @override
  State<ViewAllPrograms> createState() => _ViewAllProgramsPageState();
}

class _ViewAllProgramsPageState extends State<ViewAllPrograms> {
  static final DateFormat _startFormat = DateFormat('EEEE d MMM yyyy');
  static final DateFormat _startFormatAllDay = DateFormat('EEEE d MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static const double _detailPaneWidth = 320;
  late final AppContext _appContext;

  /// Role shown in the wide-screen detail pane; phones use a modal sheet.
  int? _selectedRoleId;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget.eventContext.program.orderProgramsByStartTime();
    if (widget.eventContext.head.eventDate != null) {
      return _buildBodyWithEventDate();
    }
    return SingleChildScrollView(child: _buildEventDateSelector());
  }

  Widget _buildBodyWithEventDate() {
    final List<Map<String, dynamic>> programRoles = _visibleRoles();
    final isWide = ResponsiveLayout.isWideScreenOf(context);
    final layout = ScheduleTimelineLayout.build(
      roles: programRoles,
      laneCap: isWide
          ? ScheduleTimelineLayout.wideLaneCap
          : ScheduleTimelineLayout.phoneLaneCap,
      finishTime: widget.eventContext.program.finishTime,
    );

    return SafeArea(
      top: false,
      child: Column(children: [
        Expanded(
            child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildEventDateSelector()),
          SliverToBoxAdapter(child: _buildScheduleBody(layout, isWide)),
          const SliverToBoxAdapter(child: SizedBox(height: 88)),
        ]))
      ]),
    );
  }

  List<Map<String, dynamic>> _visibleRoles() {
    return List<Map<String, dynamic>>.from(_appContext.isCurrentUserGuest
        ? widget.eventContext.program.roles.where((e) => e['for_guests'])
        : widget.eventContext.program.roles);
  }

  Widget _buildScheduleBody(
      final ScheduleTimelineLayout layout, final bool isWide) {
    if (layout.isEmpty && layout.untimedRoles.isEmpty) {
      return _buildEmptySchedule();
    }

    final timeline = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: ScheduleTimeline(
        layout: layout,
        selectedRoleId: isWide ? _selectedRoleId : null,
        usersForRole: _usersForRole,
        onRoleTap: (role) => _onRoleTap(role, isWide),
        onOverflowTap: _showOverflowRoles,
      ),
    );

    final selectedRole = isWide ? _roleById(_selectedRoleId) : null;
    final Widget body = selectedRole == null
        ? timeline
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: timeline),
              SizedBox(
                width: _detailPaneWidth,
                child: _buildDetailPane(selectedRole),
              ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_canEditPostProgram() && layout.placements.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: _openArrangeSchedulePage,
                icon: const Icon(Icons.swap_vert, size: 18),
                label: Text(AppLocalizations.of(context)!.scheduleArrangeTitle),
              ),
            ),
          ),
        body,
        if (layout.untimedRoles.isNotEmpty)
          _buildUntimedRoles(layout.untimedRoles),
      ],
    );
  }

  void _openArrangeSchedulePage() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ArrangeSchedulePage(eventContext: widget.eventContext),
      ),
    ).then((changed) {
      if (!mounted) return;
      setState(() {});
      if (changed == true) widget.onProgramChanged();
    });
  }

  Widget _buildDetailPane(final Map<String, dynamic> role) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(0, 8, 12, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ScheduleRoleDetailSheet(
        role: role,
        assignedUsers: _usersForRole(role),
        canEdit: _canEditRole(role),
        onEdit: () => _openEditProgramPage(role),
        onClose: () => setState(() => _selectedRoleId = null),
      ),
    );
  }

  Widget _buildEmptySchedule() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule,
              size: 56,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.scheduleEmptyTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _canEditPostProgram()
                ? l10n.scheduleEmptyBodyEditor
                : l10n.scheduleEmptyBodyViewer,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Roles missing a start or end cannot sit on the time axis.
  Widget _buildUntimedRoles(final List<Map<String, dynamic>> roles) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            AppLocalizations.of(context)!.scheduleUntimedSectionTitle,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        for (final role in roles)
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(role['title'] as String),
            onTap: () => _onRoleTap(role, false),
          ),
      ],
    );
  }

  List<User> _usersForRole(final Map<String, dynamic> role) {
    return (role['uids'] as List<String>)
        .map((e) => _appContext.userById(e))
        .whereType<User>()
        .toList();
  }

  Map<String, dynamic>? _roleById(final int? roleId) {
    if (roleId == null) return null;
    for (final role in _visibleRoles()) {
      if (role['id'] == roleId) return role;
    }
    return null;
  }

  bool _canEditRole(final Map<String, dynamic> role) {
    if (_canEditPostProgram()) return true;
    final start = role['start'] as DateTime?;
    if (start == null) return false;
    return (widget.eventContext.isUserAuthor(_appContext.currentUser.id) ||
            widget.eventContext.isUserContributor(_appContext.currentUser.id)) &&
        DateTime.now().isBefore(start);
  }

  Widget _buildEventDateSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String dateStr =
        widget.timeOnlySchedule ? 'No start time set' : 'No Date Selected';
    String timeStr = '';
    if (widget.eventContext.head.eventDate != null) {
      if (widget.timeOnlySchedule) {
        if (widget.eventContext.program.allDay) {
          dateStr = 'All day';
          timeStr = 'Calendar date is chosen when creating a post';
        } else {
          dateStr = 'Typical time';
          final finish = widget.eventContext.program.finishTime;
          timeStr = finish == null
              ? _timeFormat.format(widget.eventContext.head.eventDate!)
              : 'From ${_timeFormat.format(widget.eventContext.head.eventDate!)} to ${_timeFormat.format(finish)}';
        }
      } else if (widget.eventContext.program.allDay) {
        dateStr =
            "${_startFormatAllDay.format(widget.eventContext.head.eventDate!)} (All Day)";
      } else {
        dateStr = _startFormat.format(widget.eventContext.head.eventDate!);
        timeStr =
            'From ${_timeFormat.format(widget.eventContext.head.eventDate!)} to ${_timeFormat.format(widget.eventContext.program.finishTime!)}';
      }
    } else if (widget.timeOnlySchedule) {
      timeStr = 'Tap to set typical time & location';
    }

    final List<Widget> children = [
      Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            ListTile(
                title: Text(dateStr,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: timeStr.isNotEmpty ? Text(timeStr) : null,
                leading: Icon(
                  widget.timeOnlySchedule
                      ? Icons.schedule
                      : Icons.calendar_month,
                  color: colorScheme.primary,
                )),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
                title: Text(widget.eventContext.head.location,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  widget.eventContext.program.address,
                  maxLines: null,
                ),
                trailing: _buildLocationTrailingIcon(),
                leading: Icon(Icons.map, color: colorScheme.primary)),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ];

    children.add(const SizedBox(height: 8));
    children.add(const Divider(thickness: 1));

    return InkWell(
        onTap: _canEditPostProgram() ? _onEditPostProgram : null,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children));
  }

  void _onRoleTap(final Map<String, dynamic> role, final bool isWide) {
    final int roleId = role['id'] as int;
    if (isWide) {
      setState(() {
        _selectedRoleId = _selectedRoleId == roleId ? null : roleId;
      });
      return;
    }

    showScheduleRoleDetailSheet(
      context: context,
      role: role,
      assignedUsers: _usersForRole(role),
      canEdit: _canEditRole(role),
      onEdit: () {
        Navigator.of(context).pop();
        _openEditProgramPage(role);
      },
    );
  }

  void _showOverflowRoles(final ScheduleTimelineOverflow overflow) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      constraints: ResponsiveLayout.bottomSheetConstraintsOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ActionSheetShell(
          icon: Icons.layers_outlined,
          title: l10n.scheduleParallelSheetTitle,
          subtitle: l10n.scheduleParallelSheetSubtitle,
          children: [
            for (final role in overflow.roles)
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(role['title'] as String),
                subtitle: Text(_roleTimeRange(role)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _onRoleTap(role, false);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _roleTimeRange(final Map<String, dynamic> role) {
    final start = role['start'] as DateTime?;
    final end = role['end'] as DateTime?;
    if (start == null || end == null) {
      return AppLocalizations.of(context)!.scheduleNoTimeSet;
    }
    return '${_timeFormat.format(start)} - ${_timeFormat.format(end)}';
  }

  Widget? _buildLocationTrailingIcon() {
    if (!widget.eventContext.program.hasLocationLaunchUrl) {
      return null;
    }
    if (widget.eventContext.program.online) {
      return FilledButton.tonal(
        onPressed: _onClickLocationTrailingIcon,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam, size: 16),
            SizedBox(width: 4),
            Text('Join'),
          ],
        ),
      );
    }
    return FilledButton.tonal(
      onPressed: _onClickLocationTrailingIcon,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map, size: 16),
          SizedBox(width: 4),
          Text('Maps'),
        ],
      ),
    );
  }

  // * LOGIC
  bool _canEditPostProgram() {
    if (widget.isAddingPost ||
        widget.eventContext.isUserAuthor(_appContext.currentUser.id) ||
        widget.eventContext.isUserContributor(_appContext.currentUser.id)) {
      return true;
    }
    return DateTime.now().isBefore(widget.eventContext.head.eventDate ??
            DateTime.now().subtract(const Duration(days: 1))) &&
        (widget.eventContext.isUserAuthor(_appContext.currentUser.id) ||
            widget.eventContext.isUserContributor(_appContext.currentUser.id));
  }

  void _openEditProgramPage(final Map<String, dynamic> programEntry) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EditEventProgramPage(
                  eventContext: widget.eventContext,
                  programEntry: programEntry,
                ))).then((_) {
      setState(() {
        // rebuild in case of update
      });
      if (widget.eventContext.canSaveTheEditing) {
        widget.onProgramChanged();
      }
    });
  }

  void _onClickLocationTrailingIcon() {
    final String link = widget.eventContext.program.locationLaunchUrl.trim();
    if (link.isEmpty) return;
    launchUrlString(link, mode: LaunchMode.externalApplication)
        .onError((error, stackTrace) async {
      debugPrint('error with link: $link');
      if (!mounted) return false;
      DialogManager.showAlertDialog(
          context: context,
          title: 'Error!',
          content:
              'Attempted to open the following link:\n\n$link. \n\nError message: $error');
      return false; // ???
    }).then((success) {
      if (!success && mounted) {
        DialogManager.showAlertDialog(
            context: context,
            title: 'Error!',
            content: 'Attempted to open the following link:\n\n$link');
      }
    });
  }

  void _onEditPostProgram() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditEventDateLocationPage(
          eventContext: widget.eventContext,
          timeOnly: widget.timeOnlySchedule,
        ),
      ),
    ).then((_) {
      widget.eventContext.program.orderProgramsByStartTime();
      setState(() {});
      if (widget.eventContext.canSaveTheEditing) {
        widget.onProgramChanged();
      }
    });
  }
}
