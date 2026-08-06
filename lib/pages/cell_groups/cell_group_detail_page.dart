import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../models/cell_group.dart';
import '../../models/cell_group_roster.dart';
import '../../models/event/event_head.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/load_progress_body.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/user_avatar.dart';
import '../events/view_event_page.dart';
import 'edit_cell_group_page.dart';
import 'edit_cell_group_roster_page.dart';

class CellGroupDetailPage extends StatefulWidget {
  const CellGroupDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<CellGroupDetailPage> createState() => _CellGroupDetailPageState();
}

class _CellGroupDetailPageState extends State<CellGroupDetailPage> {
  final CellGroupDBManager _db = CellGroupDBManager();
  bool _loading = true;
  Object? _error;
  CellGroup? _group;
  CellGroupRoster? _roster;
  List<EventHead> _trail = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appContext = Provider.of<AppContext>(context, listen: false);
      final group = await _db.fetchGroup(widget.groupId);
      if (group == null) throw StateError('Cell group not found');

      final trail = await _db.fetchMeetingTrail(cellGroupId: widget.groupId, limit: 4);

      CellGroupRoster? roster;
      if (!appContext.isCurrentUserGuest) {
        try {
          roster = await CellGroupSupplementalDBManager(widget.groupId).fetchRoster();
        } catch (_) {
          roster = null;
        }
      }

      if (!mounted) return;
      appContext.addOrUpdateCellGroup(group);
      setState(() {
        _group = group;
        _roster = roster;
        _trail = trail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  bool _canManageRoster(AppContext appContext, CellGroup group) {
    if (appContext.currentUser.isAreaAdmin) return true;
    if (appContext.isCurrentUserGuest) return false;
    if (group.isLeaderUser(appContext.currentUser.id)) return true;
    final authId = AuthManager().currentAuthUID;
    return group.isLeaderAuth(authId);
  }

  bool _canViewRoster(AppContext appContext, CellGroup group, CellGroupRoster? roster) {
    if (appContext.isCurrentUserGuest) return false;
    if (_canManageRoster(appContext, group)) return true;
    return roster != null && roster.containsUserId(appContext.currentUser.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appContext = Provider.of<AppContext>(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.cellGroupsSectionTitle)),
        body: const LoadProgressBody(
          message: 'Loading group…',
          completedSteps: 0,
          totalSteps: 1,
        ),
      );
    }
    if (_error != null || _group == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.cellGroupsSectionTitle)),
        body: LoadProgressBody(
          message: 'Loading group…',
          completedSteps: 0,
          totalSteps: 1,
          error: _error ?? 'Not found',
          onRetry: _load,
        ),
      );
    }

    final group = _group!;
    final isGuest = appContext.isCurrentUserGuest;
    final canEdit = appContext.currentUser.canManageCellGroups;
    final canRoster = _canManageRoster(appContext, group);
    final showRoster = _canViewRoster(appContext, group, _roster);
    final gutter = ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.cellGroupsEdit,
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditCellGroupPage(existing: group),
                  ),
                );
                if (updated == true && mounted) _load();
              },
            ),
          if (canRoster)
            IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: l10n.cellGroupsManageRoster,
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditCellGroupRosterPage(group: group),
                  ),
                );
                if (updated == true && mounted) _load();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ResponsiveContent(
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 32),
            children: [
              if (group.summary.isNotEmpty)
                Text(group.summary, style: Theme.of(context).textTheme.bodyLarge),
              if (group.cadenceLabel.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(group.cadenceLabel),
                  ],
                ),
              ],
              if (!isGuest) ...[
                const SizedBox(height: 8),
                Text(l10n.cellGroupsMemberCount(group.memberCount)),
              ],
              if (isGuest) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.cellGroupsGuestSignInHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              if (!isGuest) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.cellGroupsLeadersLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ..._buildLeaders(appContext, group),
              ],
              if (showRoster && _roster != null) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.cellGroupsRosterTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ..._buildRosterPreview(appContext, _roster!),
                if (canRoster)
                  TextButton(
                    onPressed: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditCellGroupRosterPage(group: group),
                        ),
                      );
                      if (updated == true && mounted) _load();
                    },
                    child: Text(l10n.cellGroupsManageRoster),
                  ),
              ],
              const SizedBox(height: 20),
              Text(
                l10n.cellGroupsMeetingTrail,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_trail.isEmpty)
                Text(
                  l10n.cellGroupsMeetingTrailEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              else
                ..._trail.map((head) => _MeetingTrailTile(head: head)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLeaders(AppContext appContext, CellGroup group) {
    if (group.leaderUserIds.isEmpty) {
      return [
        Text(
          'No leaders assigned yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ];
    }
    return group.leaderUserIds.map((uid) {
      final user = _userById(appContext, uid);
      final name = user?.fullname ?? uid;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: user != null
            ? MyUserAvatar(user, radius: 20)
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name),
      );
    }).toList();
  }

  List<Widget> _buildRosterPreview(AppContext appContext, CellGroupRoster roster) {
    final members = roster.activeMembers.take(8).toList();
    if (members.isEmpty) {
      return [
        Text(
          'No members yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ];
    }
    return members.map((m) {
      final user = m.isLinkedUser ? _userById(appContext, m.userId) : null;
      final name = user?.fullname ?? (m.displayName.isNotEmpty ? m.displayName : m.userId);
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: user != null
            ? MyUserAvatar(user, radius: 16)
            : CircleAvatar(
                radius: 16,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
              ),
        title: Text(name),
        subtitle: m.isFreeText ? const Text('Name only (legacy)') : null,
      );
    }).toList();
  }

  User? _userById(AppContext appContext, String id) {
    for (final u in appContext.allUsers) {
      if (u.id == id) return u;
    }
    return null;
  }
}

class _MeetingTrailTile extends StatelessWidget {
  const _MeetingTrailTile({required this.head});

  final EventHead head;

  @override
  Widget build(BuildContext context) {
    final date = head.eventDate ?? head.recentDate;
    final formatted = DateFormat.yMMMd().format(date);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.article_outlined),
      title: Text(head.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(formatted),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ViewEventPage(eventHead: head)),
        );
      },
    );
  }
}
