import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/user_db_manager.dart';
import '../../models/cell_group.dart';
import '../../models/event/event_head.dart';
import '../../models/user.dart';
import '../../models/user_activity_record.dart';
import '../../models/user_role_assignment.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/user_schedule_service.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/cell_group_roster_cache.dart';
import '../../utility/user_cell_group_attendance.dart';
import '../../utility/volunteer_role_helpers.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/my_avatar_stack.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/catalog/user_tag_chip.dart';
import '../../widgets/volunteer_role_badge.dart';
import 'edit_user_page.dart';
import 'view_user_activity_page.dart';
import 'view_user_roles_page.dart';
import '../cell_groups/cell_group_detail_page.dart';
import '../events/view_event_page.dart';

class ViewUserProfilePage extends StatefulWidget {
  const ViewUserProfilePage({
    super.key,
    required this.selectedUser,
    this.showPostsLink = true,
  });

  final User selectedUser;
  final bool showPostsLink;

  @override
  State<ViewUserProfilePage> createState() => _ViewUserProfilePageState();
}

class _ViewUserProfilePageState extends State<ViewUserProfilePage> {
  late final AppContext _appContext;
  late User _user;
  final UserScheduleService _scheduleService = UserScheduleService();
  final UserDBManager _userDBManager = UserDBManager();
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _activityDateFormat = DateFormat('d MMM yyyy. HH:mm');
  static final DateFormat _cellGroupAttendanceDateFormat = DateFormat('d MMM');

  bool _loading = true;
  Object? _loadError;
  String _statusMessage = 'Loading profile…';
  int _completedSteps = 0;
  int _totalSteps = 2;
  List<CellGroup> _cellGroups = const [];
  UserCellGroupAttendanceSummary? _cellGroupAttendance;

  @override
  void initState() {
    super.initState();
    _appContext = Provider.of<AppContext>(context, listen: false);
    _user = _resolveUser(widget.selectedUser);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileData());
  }

  User _resolveUser(User fallback) {
    return _appContext.userById(fallback.id) ?? fallback;
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _statusMessage = 'Fetching schedule…';
      _completedSteps = 0;
      _totalSteps = 4;
    });

    try {
      if (_user.roles == null) {
        _user.setRoles(await _scheduleService.fetchRoles(_user.id));
      }
      if (!mounted) return;

      setState(() {
        _completedSteps = 1;
        _statusMessage = 'Updating schedule…';
      });

      await _scheduleService.pruneStaleRoles(
        user: _user,
        eventHeads: _appContext.eventHeads,
      );
      if (!mounted) return;

      setState(() {
        _completedSteps = 2;
        _statusMessage = 'Fetching activity…';
      });

      _user.setActivity(await _userDBManager.fetchActivity(_user.id));
      if (!mounted) return;

      setState(() {
        _completedSteps = 3;
        _statusMessage = 'Fetching cell groups…';
      });

      final cellGroups = await _loadCellGroups();
      if (!mounted) return;

      UserCellGroupAttendanceSummary? attendance;
      if (!_appContext.isCurrentUserGuest && cellGroups.isNotEmpty) {
        setState(() {
          _completedSteps = 4;
          _statusMessage = 'Checking cell group attendance…';
        });
        attendance = await UserCellGroupAttendance.load(
          user: _user,
          memberGroups: cellGroups,
        );
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _completedSteps = _totalSteps;
        _statusMessage = 'Done';
        _cellGroups = cellGroups;
        _cellGroupAttendance = attendance;
      });
    } catch (e, st) {
      debugPrint('Error loading profile: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e;
      });
    }
  }

  Future<List<CellGroup>> _loadCellGroups() async {
    if (!_appContext.isCurrentUserGuest) {
      final activeIds = _appContext.allCellGroups
          .where((g) => !g.isArchived)
          .map((g) => g.id);
      await CellGroupRosterCache.ensureLoaded(activeIds);
    }
    return CellGroupRosterCache.groupsForUser(
      user: _user,
      catalogue: _appContext.allCellGroups,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canEdit = canEditPlaceholderProfile(
      actor: _appContext.currentUser,
      target: _user,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_user.fullname),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.userProfileEditUser,
              onPressed: _onEditUser,
            ),
        ],
      ),
      body: (_loading || _loadError != null)
          ? LoadProgressBody(
              message: _statusMessage,
              completedSteps: _completedSteps,
              totalSteps: _totalSteps,
              error: _loadError,
              errorTitle: 'Could not load profile',
              onRetry: _loadProfileData,
            )
          : _buildBody(context, l10n, theme, colorScheme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final double webHorizontalPadding = ResponsiveLayout.horizontalGutter(
        MediaQuery.sizeOf(context).width,
        narrowPadding: 16);
    final upcomingRoles = UserScheduleService.upcomingRoles(
      user: _user,
      eventHeads: _appContext.eventHeads,
      limit: 3,
    );
    final userTags =
        UserTagHelpers.tagsForUser(user: _user, allTags: _appContext.allTags);
    final volunteerRoles = VolunteerRoleHelpers.rolesFor(
      user: _user,
      cellGroupLeaders:
          CellGroupLeaderIndex.fromGroups(_appContext.allCellGroups),
    );

    final isWide = ResponsiveLayout.isWideScreenOf(context);

    final profileCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            MyUserAvatar(_user, radius: isWide ? 56 : 48),
            const SizedBox(height: 16),
            Text(
              _user.fullname,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  _user.location,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            if (volunteerRoles.isNotEmpty) ...[
              const SizedBox(height: 12),
              VolunteerRoleBadgeRow(
                roles: volunteerRoles,
                alignment: WrapAlignment.center,
              ),
            ],
            if (userTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              UserTagChipRow(tags: userTags, alignment: WrapAlignment.center),
            ],
          ],
        ),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.userProfileCellGroups,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_cellGroupAttendance != null) ...[
          _buildCellGroupAttendanceBanner(
            l10n,
            theme,
            colorScheme,
            _cellGroupAttendance!,
          ),
          const SizedBox(height: 8),
        ],
        _buildCellGroupsCard(l10n, theme, colorScheme),
        const SizedBox(height: 16),
        Text(l10n.userProfileUpcomingTasks,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (upcomingRoles.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.userProfileNoUpcomingTasks,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < upcomingRoles.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildPreviewTile(upcomingRoles[i], l10n, theme, colorScheme),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _onViewFullSchedule,
          icon: const Icon(Icons.checklist_rounded),
          label: Text(l10n.userProfileViewFullSchedule),
        ),
        if (widget.showPostsLink) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _onViewPosts,
            icon: const Icon(Icons.article_outlined),
            label: Text(l10n.userProfileViewPosts),
          ),
        ],
        const SizedBox(height: 16),
        Text(l10n.userProfileRecentActivity,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildActivityCard(l10n, theme, colorScheme),
        if (_appContext.currentUser.canManageVolunteers) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _onViewAllActivity,
            icon: const Icon(Icons.history),
            label: Text(l10n.userProfileViewAllActivity),
          ),
        ],
      ],
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
          webHorizontalPadding, 16, webHorizontalPadding, 24),
      children: [
        if (_user.isProfileInactive &&
            _appContext.currentUser.canManageVolunteers)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: MaterialBanner(
              leading: Icon(
                Icons.visibility_off_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
              content: Text(
                _user.isProfileArchived
                    ? l10n.volunteersArchivedProfileBanner
                    : l10n.volunteersInactiveProfileBanner,
              ),
              backgroundColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              actions: const [SizedBox.shrink()],
            ),
          ),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: profileCard),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: details),
            ],
          )
        else ...[
          profileCard,
          const SizedBox(height: 16),
          details,
        ],
      ],
    );
  }

  Widget _buildCellGroupAttendanceBanner(
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
    UserCellGroupAttendanceSummary summary,
  ) {
    final attended = summary.attendedInPastWindow;
    final icon = attended
        ? Icons.check_circle_outline
        : Icons.event_busy_outlined;
    final iconColor =
        attended ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final lastMeeting = summary.lastAttendedMeeting;
    final lastDate = summary.lastAttendedDate;

    String title;
    if (attended) {
      title = l10n.userProfileCellGroupMeetingsAttendedCount(
        summary.meetingsAttended,
      );
      if (summary.distinctGroupsAttended > 1) {
        title =
            '$title ${l10n.userProfileCellGroupGroupsAttendedSuffix(summary.distinctGroupsAttended)}';
      }
    } else {
      title = l10n.userProfileCellGroupNoAttendanceRecent;
    }

    String? meetingLinkLabel;
    if (lastMeeting != null) {
      final meetingTitle = lastMeeting.title.trim();
      meetingLinkLabel = meetingTitle.isEmpty
          ? l10n.userProfileCellGroupViewRecentMeeting
          : l10n.userProfileCellGroupViewRecentMeetingNamed(meetingTitle);
    }

    return Card(
      color: attended
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: attended
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (lastDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.userProfileCellGroupLastAttended(
                        _cellGroupAttendanceDateFormat.format(lastDate),
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (lastMeeting != null && meetingLinkLabel != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _openCellGroupMeeting(lastMeeting),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(meetingLinkLabel),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCellGroupMeeting(EventHead head) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewEventPage(eventHead: head)),
    );
  }

  List<User> _leadersForGroup(CellGroup group) {
    final leaders = <User>[];
    for (final uid in group.leaderUserIds) {
      final user = _appContext.userById(uid);
      if (user != null) leaders.add(user);
    }
    return leaders;
  }

  Widget _buildCellGroupsCard(
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (_cellGroups.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.userProfileNoCellGroups,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < _cellGroups.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            _buildCellGroupTile(_cellGroups[i], theme, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildCellGroupTile(
    CellGroup group,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final cadence = group.cadenceLabel;
    final leaders = _leadersForGroup(group);
    return ListTile(
      leading: leaders.isEmpty
          ? Icon(Icons.groups_outlined, color: colorScheme.primary)
          : SizedBox(
              width: 48,
              height: 40,
              child: MyAvatarStack(
                users: leaders,
                appDir: _appContext.appDir,
                height: 40,
                width: 48,
              ),
            ),
      title: Text(group.name),
      subtitle: cadence.isEmpty ? null : Text(cadence),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CellGroupDetailPage(groupId: group.id),
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final preview = _user.activity?.preview ?? const <UserActivityRecord>[];
    if (preview.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.userProfileNoRecentActivity,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < preview.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(Icons.history, color: colorScheme.primary),
              title: Text(preview[i].log),
              subtitle: Text(_activityDateFormat.format(preview[i].ts)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewTile(
    UserRoleAssignment role,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final eventHead = UserScheduleService.eventHeadForRole(
      postID: role.postID,
      eventHeads: _appContext.eventHeads,
    );
    final eventTitle = eventHead?.title ?? l10n.userProfileUntitledEvent;
    final dateLabel = eventHead?.eventDate != null
        ? _eventDateFormat.format(eventHead!.eventDate!)
        : null;
    final timeLabel =
        '${_timeFormat.format(role.start)} - ${_timeFormat.format(role.end)}';

    return ListTile(
      leading: Icon(Icons.event, color: colorScheme.primary),
      title: Text(role.title),
      subtitle: Text(dateLabel == null
          ? timeLabel
          : '$eventTitle · $dateLabel · $timeLabel'),
      isThreeLine: dateLabel != null,
    );
  }

  void _onViewFullSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewUserRolesPage(
          selectedUser: _user,
          allowPostView: true,
        ),
      ),
    );
  }

  void _onViewPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewUserRolesPage(
          selectedUser: _user,
          allowPostView: true,
          initialTab: 1,
        ),
      ),
    );
  }

  void _onViewAllActivity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewUserActivityPage(selectedUser: _user),
      ),
    );
  }

  Future<void> _onEditUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditUserPage(user: _user)),
    );
    if (!mounted) return;
    if (result == true) {
      setState(() {
        _user = _resolveUser(_user);
      });
    }
  }
}
