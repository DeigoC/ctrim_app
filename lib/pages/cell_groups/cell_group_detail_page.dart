import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../models/cell_group.dart';
import '../../models/cell_group_roster.dart';
import '../../models/event/event_head.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../utility/cache/refresh_cooldown.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../widgets/common/load_progress_body.dart';
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
  final UserDBManager _userDb = UserDBManager();
  bool _loading = true;
  Object? _error;
  CellGroup? _group;
  CellGroupRoster? _roster;
  List<EventHead> _trail = const [];

  /// Resolved profiles for leaders + roster (avoids showing raw numeric user ids).
  Map<String, User> _usersById = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _onPullRefresh() async {
    final pref = Provider.of<AppContext>(context, listen: false).sharedPref;
    if (!pref.canRefreshCellGroups) {
      await Future.delayed(kRefreshCooldownBusyWait);
      return;
    }
    await _load();
    if (mounted && _error == null) {
      pref.setCellGroupsRefreshTime();
    }
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

      final trail =
          await _db.fetchMeetingTrail(cellGroupId: widget.groupId, limit: 4);

      CellGroupRoster? roster;
      if (!appContext.isCurrentUserGuest) {
        try {
          roster = await CellGroupSupplementalDBManager(widget.groupId)
              .fetchRoster();
        } catch (_) {
          roster = null;
        }
      }

      final usersById = await _resolveUsers(
        appContext: appContext,
        leaderIds: group.leaderUserIds,
        roster: roster,
      );

      if (!mounted) return;
      appContext.addOrUpdateCellGroup(group);
      setState(() {
        _group = group;
        _roster = roster;
        _trail = trail;
        _usersById = usersById;
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

  /// Look up leaders/members in [AppContext.allUsers], then fetch any gaps.
  Future<Map<String, User>> _resolveUsers({
    required AppContext appContext,
    required Iterable<String> leaderIds,
    required CellGroupRoster? roster,
  }) async {
    final ids = <String>{
      ...leaderIds.where((id) => id.isNotEmpty),
      if (roster != null)
        ...roster.activeMembers
            .where((m) => m.isLinkedUser)
            .map((m) => m.userId),
    };
    if (ids.isEmpty) return const {};

    final resolved = <String, User>{};
    final missing = <String>[];
    for (final id in ids) {
      final local = appContext.userById(id);
      if (local != null) {
        resolved[id] = local;
      } else {
        missing.add(id);
      }
    }

    if (missing.isNotEmpty) {
      final fetched = await Future.wait(missing.map((id) async {
        try {
          return await _userDb.fetchUserByID(id);
        } catch (_) {
          return null;
        }
      }));
      for (final user in fetched) {
        if (user == null) continue;
        resolved[user.id] = user;
        if (appContext.userById(user.id) == null) {
          appContext.addOrUpdateUser(user);
        }
      }
    }

    return resolved;
  }

  User? _userForId(String id) =>
      _usersById[id] ??
      Provider.of<AppContext>(context, listen: false).userById(id);

  String _displayNameFor({User? user, String displayName = ''}) {
    if (user != null) return user.fullname;
    if (displayName.trim().isNotEmpty) return displayName.trim();
    return 'Unknown member';
  }

  bool _canManageRoster(AppContext appContext, CellGroup group) {
    if (appContext.currentUser.isAreaAdmin) return true;
    if (appContext.isCurrentUserGuest) return false;
    if (group.isLeaderUser(appContext.currentUser.id)) return true;
    final authId = AuthManager().currentAuthUID;
    return group.isLeaderAuth(authId);
  }

  bool _canViewRoster(
      AppContext appContext, CellGroup group, CellGroupRoster? roster) {
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
    final isLeader = group.isLeaderUser(appContext.currentUser.id) ||
        appContext.currentUser.isAreaAdmin;

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
    final linked = result.map((uid) {
      final existing = existingById[uid];
      final user = _userForId(uid) ?? appContext.userById(uid);
      final name = user?.fullname ?? existing?.displayName ?? '';
      if (existing != null) {
        if (name.isNotEmpty) existing.setDisplayName(name);
        return existing;
      }
      return CellGroupRosterMember(
        userId: uid,
        displayName: name,
        joinedAt: now,
      );
    }).toList();
    final updated = CellGroupRoster(members: [...linked, ...freeText]);

    await _persistRoster(group: group, roster: updated);
  }

  Future<void> _removeFreeTextMember({
    required CellGroup group,
    required CellGroupRosterMember member,
  }) async {
    final roster = _roster;
    if (roster == null) return;
    final next = List<CellGroupRosterMember>.from(roster.members)
      ..remove(member);
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
      title: 'Saving members…',
      action: () async {
        await CellGroupSupplementalDBManager(group.id).setRoster(roster);
        final count = roster.activeCount;
        await CellGroupDBManager()
            .updateMemberCount(id: group.id, memberCount: count);
        group.setMemberCount(count);
        if (!mounted) return;
        final appContext = Provider.of<AppContext>(context, listen: false);
        appContext.addOrUpdateCellGroup(group);
        await UserActivityRecorder().record(
          actorUserId: appContext.currentUser.id,
          log: UserActivityMessages.updatedCellMembers,
          documentId: group.id,
        );
      },
    );
    if (!mounted || !ok) return;

    final appContext = Provider.of<AppContext>(context, listen: false);
    final usersById = await _resolveUsers(
      appContext: appContext,
      leaderIds: group.leaderUserIds,
      roster: roster,
    );
    if (!mounted) return;
    setState(() {
      _roster = roster;
      _usersById = usersById;
    });
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveLayout.isWideScreen(screenWidth);
    final hasKeyGraphic = group.hasKeyGraphic;
    final keySrc = group.keyGraphicSrc;
    final heroHeight =
        MediaQuery.sizeOf(context).height * (isWide ? 0.32 : 0.28);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onPullRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: (!isWide && hasKeyGraphic) ? heroHeight : null,
              title: Text(group.name),
              flexibleSpace: (!isWide && hasKeyGraphic && keySrc != null)
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
              actions: _buildAppBarActions(
                l10n: l10n,
                group: group,
                canEdit: canEdit,
              ),
            ),
            if (isWide && hasKeyGraphic && keySrc != null)
              SliverToBoxAdapter(
                child: _buildWideHero(
                  keySrc: keySrc,
                  height: heroHeight,
                  screenWidth: screenWidth,
                ),
              ),
            SliverToBoxAdapter(
              child: ResponsiveContent(
                narrowPadding: 16,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, isWide ? 20 : 16, 0, 32),
                  child: _buildDetailSections(
                    l10n: l10n,
                    appContext: appContext,
                    theme: theme,
                    colorScheme: colorScheme,
                    group: group,
                    isGuest: isGuest,
                    canRoster: canRoster,
                    showRoster: showRoster,
                    isWide: isWide,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions({
    required AppLocalizations l10n,
    required CellGroup group,
    required bool canEdit,
  }) {
    return [
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
    ];
  }

  Widget _buildWideHero({
    required String keySrc,
    required double height,
    required double screenWidth,
  }) {
    final gutter =
        ResponsiveLayout.horizontalGutter(screenWidth, narrowPadding: 16);
    final maxWidth = ResponsiveLayout.maxContentWidth(screenWidth);
    final sidePad =
        screenWidth > maxWidth ? (screenWidth - maxWidth) / 2 : gutter;

    return Padding(
      padding: EdgeInsets.fromLTRB(sidePad, 8, sidePad, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: GestureDetector(
            onTap: () => _openPhoto(keySrc),
            child: CachedImageWidget(
              imageUrl: keySrc,
              fit: BoxFit.cover,
              width: double.infinity,
              height: height,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSections({
    required AppLocalizations l10n,
    required AppContext appContext,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required CellGroup group,
    required bool isGuest,
    required bool canRoster,
    required bool showRoster,
    required bool isWide,
  }) {
    final aboutCard = _CgSectionCard(
      title: l10n.cellGroupsAboutTitle,
      child: _buildAboutBody(
        l10n: l10n,
        theme: theme,
        colorScheme: colorScheme,
        group: group,
        isGuest: isGuest,
      ),
    );
    final photosCard = group.media.isEmpty
        ? null
        : _CgSectionCard(
            title: l10n.cellGroupsPhotosTitle,
            child: _buildGallery(group, isWide: isWide),
          );
    final leadersCard = isGuest
        ? null
        : _CgSectionCard(
            title: l10n.cellGroupsLeadersLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildLeaders(appContext, group),
            ),
          );
    final membersCard = (showRoster && _roster != null)
        ? _CgSectionCard(
            title: l10n.cellGroupsRosterTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._buildRosterPreview(
                  appContext: appContext,
                  group: group,
                  roster: _roster!,
                  canManage: canRoster,
                ),
                if (canRoster) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _manageRoster(appContext, group),
                      icon: const Icon(Icons.group_outlined, size: 18),
                      label: Text(l10n.cellGroupsManageRoster),
                    ),
                  ),
                ],
              ],
            ),
          )
        : null;
    final meetingsBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.cellGroupsMeetingTrail,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_trail.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.cellGroupsMeetingTrailEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ..._trail.map((head) => _buildMeetingPostCard(head)),
      ],
    );

    final peopleColumn = <Widget>[
      if (leadersCard != null) leadersCard,
      if (leadersCard != null && membersCard != null)
        const SizedBox(height: 12),
      if (membersCard != null) membersCard,
    ];

    if (!isWide || peopleColumn.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          aboutCard,
          if (photosCard != null) ...[
            const SizedBox(height: 12),
            photosCard,
          ],
          if (leadersCard != null) ...[
            const SizedBox(height: 12),
            leadersCard,
          ],
          if (membersCard != null) ...[
            const SizedBox(height: 12),
            membersCard,
          ],
          const SizedBox(height: 20),
          meetingsBlock,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  aboutCard,
                  if (photosCard != null) ...[
                    const SizedBox(height: 12),
                    photosCard,
                  ],
                  const SizedBox(height: 20),
                  meetingsBlock,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: peopleColumn,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutBody({
    required AppLocalizations l10n,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required CellGroup group,
    required bool isGuest,
  }) {
    final location = group.location.trim();
    final cadence = group.cadenceLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group.summary.isNotEmpty) ...[
          Text(group.summary, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (location.isNotEmpty)
              _CgMetaChip(
                icon: Icons.location_on_outlined,
                label: location,
              ),
            if (cadence.isNotEmpty)
              _CgMetaChip(
                icon: Icons.schedule,
                label: cadence,
              ),
            if (!isGuest)
              _CgMetaChip(
                icon: Icons.people_outline,
                label: l10n.cellGroupsMemberCount(group.memberCount),
              ),
          ],
        ),
        if (isGuest) ...[
          const SizedBox(height: 12),
          Text(
            l10n.cellGroupsGuestSignInHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGallery(CellGroup group, {required bool isWide}) {
    return SizedBox(
      height: isWide ? 148 : 112,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
      final user = _userForId(uid);
      final name = _displayNameFor(user: user);
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
      final user = m.isLinkedUser ? _userForId(m.userId) : null;
      final name = _displayNameFor(
        user: user,
        displayName: m.displayName,
      );
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
}

class _CgSectionCard extends StatelessWidget {
  const _CgSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CgMetaChip extends StatelessWidget {
  const _CgMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
