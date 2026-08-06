import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../models/cell_group.dart';
import '../../models/cell_group_roster.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/load_progress_body.dart';
import '../../widgets/user_avatar.dart';
import '../personal/select_users_page.dart';

/// Leader / area-admin roster editor (registered + placeholder users).
///
/// Legacy free-text rows may still appear and can be removed; new adds go through
/// [SelectUsersPage] (search → Create placeholder when needed).
class EditCellGroupRosterPage extends StatefulWidget {
  const EditCellGroupRosterPage({super.key, required this.group});

  final CellGroup group;

  @override
  State<EditCellGroupRosterPage> createState() => _EditCellGroupRosterPageState();
}

class _EditCellGroupRosterPageState extends State<EditCellGroupRosterPage> {
  bool _loading = true;
  Object? _error;
  late CellGroupRoster _roster;

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
      final roster = await CellGroupSupplementalDBManager(widget.group.id).fetchRoster();
      if (!mounted) return;
      setState(() {
        _roster = roster;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gutter = ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width);
    final appContext = Provider.of<AppContext>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cellGroupsRosterTitle),
        actions: [
          TextButton(
            onPressed: _loading || _error != null ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const LoadProgressBody(
              message: 'Loading roster…',
              completedSteps: 0,
              totalSteps: 1,
            )
          : _error != null
              ? LoadProgressBody(
                  message: 'Loading roster…',
                  completedSteps: 0,
                  totalSteps: 1,
                  error: _error,
                  onRetry: _load,
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 32),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _addUsers(appContext),
                        icon: const Icon(Icons.person_add),
                        label: Text(l10n.cellGroupsAddMembers),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.cellGroupsRosterAddHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (_roster.members.isEmpty)
                      Text(
                        'No members yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      )
                    else
                      ...List.generate(_roster.members.length, (index) {
                        final member = _roster.members[index];
                        final user =
                            member.isLinkedUser ? _userById(appContext, member.userId) : null;
                        final name = user?.fullname ??
                            (member.displayName.isNotEmpty ? member.displayName : member.userId);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: user != null
                              ? MyUserAvatar(user, radius: 20)
                              : CircleAvatar(
                                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                                ),
                          title: Text(name),
                          subtitle: Text(
                            [
                              if (member.isFreeText) 'Name only (legacy)',
                              if (user?.isPlaceholder == true) 'Placeholder',
                              member.role,
                            ].where((e) => e.isNotEmpty).join(' · '),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                final next = List<CellGroupRosterMember>.from(_roster.members)
                                  ..removeAt(index);
                                _roster.setMembers(next);
                              });
                            },
                          ),
                        );
                      }),
                  ],
                ),
    );
  }

  Future<void> _addUsers(AppContext appContext) async {
    final isLeader = widget.group.isLeaderUser(appContext.currentUser.id) ||
        appContext.currentUser.isAreaAdmin;
    final existingLinked = _roster.members
        .where((m) => m.isLinkedUser)
        .map((m) => m.userId)
        .toList();

    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: existingLinked,
          includeCurrentUser: true,
          title: AppLocalizations.of(context)!.cellGroupsAddMembers,
          allowCreatePlaceholder: canCreatePlaceholderUser(
            actor: appContext.currentUser,
            isCellGroupLeader: isLeader,
          ),
          includePlaceholders: true,
          cellGroupIdForPlaceholderCreate: widget.group.id,
        ),
      ),
    );
    if (result == null || !mounted) return;

    // Preserve any legacy free-text rows until an editor removes them.
    final freeText = _roster.members.where((m) => m.isFreeText).toList();
    final now = DateTime.now();
    final existingById = {
      for (final m in _roster.members.where((m) => m.isLinkedUser)) m.userId: m,
    };
    final linked = result
        .map((uid) => existingById[uid] ?? CellGroupRosterMember(userId: uid, joinedAt: now))
        .toList();

    setState(() {
      _roster.setMembers([...linked, ...freeText]);
    });
  }

  Future<void> _save() async {
    final ok = await DialogManager.runWithProgressDialog(
      context: context,
      title: 'Saving roster…',
      action: () async {
        await CellGroupSupplementalDBManager(widget.group.id).setRoster(_roster);
        final count = _roster.activeCount;
        await CellGroupDBManager().updateMemberCount(id: widget.group.id, memberCount: count);
        widget.group.setMemberCount(count);
        if (!mounted) return;
        Provider.of<AppContext>(context, listen: false).addOrUpdateCellGroup(widget.group);
      },
    );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  User? _userById(AppContext appContext, String id) {
    for (final u in appContext.allUsers) {
      if (u.id == id) return u;
    }
    return null;
  }
}
