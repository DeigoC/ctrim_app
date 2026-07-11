import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../models/user_role_assignment.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/user_schedule_service.dart';
import '../../utility/user_tag_helpers.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_tag_chip.dart';
import 'edit_user_page.dart';
import 'view_user_roles_page.dart';

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
  final UserScheduleService _scheduleService = UserScheduleService();
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _appContext = Provider.of<AppContext>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileData());
  }

  Future<void> _loadProfileData() async {
    if (widget.selectedUser.roles == null) {
      widget.selectedUser.setRoles(await _scheduleService.fetchRoles(widget.selectedUser.id));
    }
    await _scheduleService.pruneStaleRoles(
      user: widget.selectedUser,
      eventHeads: _appContext.eventHeads,
    );
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canEdit = _appContext.currentUser.isAreaAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedUser.fullname),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.userProfileEditUser,
              onPressed: _onEditUser,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, l10n, theme, colorScheme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final double webHorizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 16);
    final upcomingRoles = UserScheduleService.upcomingRoles(
      user: widget.selectedUser,
      eventHeads: _appContext.eventHeads,
      limit: 3,
    );
    final userTags = UserTagHelpers.tagsForUser(user: widget.selectedUser, allTags: _appContext.allTags);

    return ListView(
      padding: EdgeInsets.fromLTRB(webHorizontalPadding, 16, webHorizontalPadding, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                MyUserAvatar(widget.selectedUser, radius: 48),
                const SizedBox(height: 16),
                Text(
                  widget.selectedUser.fullname,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      widget.selectedUser.location,
                      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                if (widget.selectedUser.isLeader || widget.selectedUser.isAreaAdmin) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (widget.selectedUser.isLeader) _buildBadge(l10n.userProfileLeaderBadge, colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
                      if (widget.selectedUser.isAreaAdmin) _buildBadge(l10n.userProfileAdminBadge, colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
                    ],
                  ),
                ],
                if (userTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  UserTagChipRow(tags: userTags, alignment: WrapAlignment.center),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.userProfileUpcomingTasks, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (upcomingRoles.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.userProfileNoUpcomingTasks,
                style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < upcomingRoles.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
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
      ],
    );
  }

  Widget _buildBadge(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: 12),
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
    final dateLabel = eventHead?.eventDate != null ? _eventDateFormat.format(eventHead!.eventDate!) : null;
    final timeLabel = '${_timeFormat.format(role.start)} - ${_timeFormat.format(role.end)}';

    return ListTile(
      leading: Icon(Icons.event, color: colorScheme.primary),
      title: Text(role.title),
      subtitle: Text(dateLabel == null ? timeLabel : '$eventTitle · $dateLabel · $timeLabel'),
      isThreeLine: dateLabel != null,
    );
  }

  void _onViewFullSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewUserRolesPage(selectedUser: widget.selectedUser),
      ),
    );
  }

  void _onViewPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewUserRolesPage(
          selectedUser: widget.selectedUser,
          allowPostView: true,
          initialTab: 1,
        ),
      ),
    );
  }

  Future<void> _onEditUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditUserPage(user: widget.selectedUser)),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }
}
