import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../models/cell_group.dart';
import '../../models/cell_group_roster.dart';
import '../../models/event/event_head.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../widgets/load_progress_body.dart';
import '../../widgets/media/cached_image_widget.dart';
import '../../widgets/posts/post_head.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/user_avatar.dart';
import '../personal/select_users_page.dart';
import 'edit_cell_group_page.dart';

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

  /// Opens [SelectUsersPage] and persists the roster when membership changes.
  Future<void> _manageRoster(AppContext appContext, CellGroup group) async {
    final roster = await _ensureRosterLoaded();
    if (!mounted) return;

    final existingLinked = roster.members
        .where((m) => m.isLinkedUser)
        .map((m) => m.userId)
        .toList();
    final isLeader =
        group.isLeaderUser(appContext.currentUser.id) || appContext.currentUser.isAreaAdmin;

    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: existingLinked,
          includeCurrentUser: true,
          title: AppLocalizations.of(context)!.cellGroupsManageRoster,
          allowCreatePlaceholder: canCreatePlaceholderUser(
            actor: appContext.currentUser,
            isCellGroupLeader: isLeader,
          ),
          includePlaceholders: true,
          cellGroupIdForPlaceholderCreate: group.id,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final previous = existingLinked.toSet();
    final next = result.toSet();
    if (previous.length == next.length && previous.containsAll(next)) return;

    final freeText = roster.members.where((m) => m.isFreeText).toList();
    final now = DateTime.now();
    final existingById = {
      for (final m in roster.members.where((m) => m.isLinkedUser)) m.userId: m,
    };
    final linked = result
        .map((uid) =>
            existingById[uid] ?? CellGroupRosterMember(userId: uid, joinedAt: now))
        .toList();
    final updated = CellGroupRoster(members: [...linked, ...freeText]);

    await _persistRoster(group: group, roster: updated);
  }

  Future<void> _removeFreeTextMember({
    required CellGroup group,
    required CellGroupRosterMember member,
  }) async {
    final roster = _roster;
    if (roster == null) return;
    final next = List<CellGroupRosterMember>.from(roster.members)..remove(member);
    await _persistRoster(group: group, roster: CellGroupRoster(members: next));
  }

  Future<CellGroupRoster> _ensureRosterLoaded() async {
    final existing = _roster;
    if (existing != null) return existing;
    try {
      final roster =
          await CellGroupSupplementalDBManager(widget.groupId).fetchRoster();
      if (mounted) setState(() => _roster = roster);
      return roster;
    } catch (_) {
      final empty = CellGroupRoster();
      if (mounted) setState(() => _roster = empty);
      return empty;
    }
  }

  Future<void> _persistRoster({
    required CellGroup group,
    required CellGroupRoster roster,
  }) async {
    final ok = await DialogManager.runWithProgressDialog(
      context: context,
      title: 'Saving roster…',
      action: () async {
        await CellGroupSupplementalDBManager(group.id).setRoster(roster);
        final count = roster.activeCount;
        await CellGroupDBManager().updateMemberCount(id: group.id, memberCount: count);
        group.setMemberCount(count);
        if (!mounted) return;
        Provider.of<AppContext>(context, listen: false).addOrUpdateCellGroup(group);
      },
    );
    if (!mounted || !ok) return;
    setState(() => _roster = roster);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasKeyGraphic = group.hasKeyGraphic;
    final keySrc = group.keyGraphicSrc;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight:
                  hasKeyGraphic ? MediaQuery.sizeOf(context).height * 0.28 : null,
              title: Text(group.name),
              flexibleSpace: hasKeyGraphic && keySrc != null
                  ? FlexibleSpaceBar(
                      background: GestureDetector(
                        onTap: () => _openPhoto(keySrc),
                        child: CachedImageWidget(
                          imageUrl: keySrc,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    )
                  : null,
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
                    onPressed: () => _manageRoster(appContext, group),
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: ResponsiveContent(
                narrowPadding: 16,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (group.summary.isNotEmpty)
                        Text(group.summary, style: theme.textTheme.bodyLarge),
                      if (group.cadenceLabel.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 18, color: colorScheme.onSurfaceVariant),
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      if (group.media.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          l10n.cellGroupsPhotosTitle,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        _buildGallery(group),
                      ],
                      if (!isGuest) ...[
                        const SizedBox(height: 20),
                        Text(
                          l10n.cellGroupsLeadersLabel,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ..._buildLeaders(appContext, group),
                      ],
                      if (showRoster && _roster != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          l10n.cellGroupsRosterTitle,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ..._buildRosterPreview(
                          appContext: appContext,
                          group: group,
                          roster: _roster!,
                          canManage: canRoster,
                        ),
                        if (canRoster)
                          TextButton(
                            onPressed: () => _manageRoster(appContext, group),
                            child: Text(l10n.cellGroupsManageRoster),
                          ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        l10n.cellGroupsMeetingTrail,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (_trail.isEmpty)
                        Text(
                          l10n.cellGroupsMeetingTrailEmpty,
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        )
                      else
                        ..._trail.map((head) => _buildMeetingPostCard(head)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(CellGroup group) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: group.media.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final src = (group.media[index]['src'] as String?) ?? '';
          if (src.isEmpty) return const SizedBox.shrink();
          final isCover = src == group.keyGraphicSrc;
          return GestureDetector(
            onTap: () => _openPhoto(src),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedImageWidget(
                      imageUrl: src,
                      fit: BoxFit.cover,
                      heroTag: '${group.id}-$src',
                    ),
                  ),
                  if (isCover)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.cellGroupsCoverPhoto,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPhoto(String src) {
    final groupId = _group?.id ?? widget.groupId;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: PhotoView(
            imageProvider: NetworkImage(NetworkImageHelper.getImageUrl(src)),
            heroAttributes: PhotoViewHeroAttributes(tag: '$groupId-$src'),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingPostCard(EventHead head) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PostHead(
        thisHead: head,
        updatePost: () {
          if (mounted) setState(() {});
        },
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

  List<Widget> _buildRosterPreview({
    required AppContext appContext,
    required CellGroup group,
    required CellGroupRoster roster,
    required bool canManage,
  }) {
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
        // Linked members are edited via SelectUsersPage; free-text only here.
        trailing: canManage && m.isFreeText
            ? IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Remove',
                onPressed: () => _removeFreeTextMember(group: group, member: m),
              )
            : null,
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
