import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/event/event_program.dart';
import '../../models/user.dart';
import '../../models/user_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/app_links.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/team_rota.dart';
import '../../widgets/catalog/colored_chip.dart';
import '../../widgets/catalog/user_tag_chip.dart';
import '../../widgets/common/action_sheet.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/paired_row_list.dart';
import '../../widgets/personal/team_rota_post_card.dart';
import '../../widgets/posts/schedule_role_detail_sheet.dart';
import '../../widgets/user_avatar.dart';
import 'select_users_page.dart';

/// Signed-in serving view: tagged programme slots over the next few months.
class ViewTeamRotaPage extends StatefulWidget {
  const ViewTeamRotaPage({super.key});

  @override
  State<ViewTeamRotaPage> createState() => _ViewTeamRotaPageState();
}

class _ViewTeamRotaPageState extends State<ViewTeamRotaPage> {
  static const int _horizonMonths = TeamRotaQuery.defaultHorizonMonths;

  late final AppContext _appContext;
  final EventHeadDBManager _headsDb = EventHeadDBManager();
  late String _locationFilter;
  late Set<String> _selectedTagIDs;
  bool _needsPeople = false;
  final Set<String> _expandedPostIds = {};

  List<EventHead> _rangeHeads = [];
  final Map<String, EventProgram?> _programs = {};

  bool _loading = true;
  Object? _error;
  String _statusMessage = '';
  int _completedSteps = 0;
  int _totalSteps = 2;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    _appContext.analytics.logTeamRota();
    _locationFilter = VolunteerLocations.defaultFilterForUser(
      _appContext.currentUser.location,
      VolunteerLocations.assignableFrom(_appContext.allLocations),
    );
    _selectedTagIDs = TeamRotaQuery.openingMinistryIds(
      user: _appContext.currentUser,
      allTags: _appContext.allTags,
      locationId: VolunteerLocations.idForName(
            locations: _appContext.allLocations,
            name: _locationFilter,
          ) ??
          '',
    );
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
      _completedSteps = 0;
      _totalSteps = 2;
      _statusMessage = l10n.teamRotaLoadingHeads;
    });

    try {
      final now = DateTime.now();
      final heads = await _headsDb.fetchHeadsWithEventDateInRange(
        startInclusive: TeamRotaQuery.rangeStart(now),
        endExclusive: TeamRotaQuery.rangeEndExclusive(now),
      );
      if (!mounted) return;

      setState(() {
        _rangeHeads = heads;
        _completedSteps = 1;
        _statusMessage = l10n.teamRotaLoadingProgrammes;
      });

      await _ensureProgramsForFilter();
      if (!mounted) return;

      setState(() {
        _loading = false;
        _completedSteps = 2;
      });
    } catch (e, st) {
      debugPrint('Could not load team rota: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _ensureProgramsForFilter() async {
    final needed = _rangeHeads.where((head) {
      if (!TeamRotaQuery.headMatchesLocation(
        head: head,
        locationFilter: _locationFilter,
      )) {
        return false;
      }
      return !_programs.containsKey(head.id);
    }).toList();
    if (needed.isEmpty) return;

    final fetched = await Future.wait(
      needed.map(
        (head) => EventSupplementalDBManager(head.id).fetchProgramIfExists(),
      ),
    );
    for (var i = 0; i < needed.length; i++) {
      _programs[needed[i].id] = fetched[i];
    }
  }

  List<TeamRotaPost> _matchingPosts() {
    final posts = <({EventHead head, EventProgram program})>[];
    for (final head in _rangeHeads) {
      final program = _programs[head.id];
      if (program == null) continue;
      posts.add((head: head, program: program));
    }
    return TeamRotaQuery.matchingPosts(
      posts: posts,
      selectedTagIDs: _selectedTagIDs,
      locationFilter: _locationFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => (c.catalogsEpoch, c.usersEpoch));
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;
    final filtersReady = !_loading && _error == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamRota),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          if (filtersReady)
            IconButton(
              onPressed: _showFilterSheet,
              tooltip: l10n.teamRotaFilterTooltip,
              style: IconButton.styleFrom(
                backgroundColor:
                    colorScheme.primaryContainer.withValues(alpha: 0.3),
                foregroundColor: colorScheme.primary,
              ),
              icon: Badge(
                isLabelVisible: _showsFilterBanner,
                child: const Icon(Icons.tune),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading || _error != null
          ? LoadProgressBody(
              message: _statusMessage,
              completedSteps: _completedSteps,
              totalSteps: _totalSteps,
              error: _error,
              errorTitle: l10n.teamRotaCouldNotLoad,
              onRetry: _load,
            )
          : _buildLoadedBody(l10n),
    );
  }

  Widget _buildLoadedBody(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final matching = _matchingPosts();
    final gapCount = TeamRotaQuery.unassignedRoleCount(matching);
    final visible =
        _needsPeople ? TeamRotaQuery.postsNeedingPeople(matching) : matching;
    final groups = TeamRotaQuery.groupByMonth(visible);
    final isWide = ResponsiveLayout.isWideScreenOf(context);
    final headsStrip = _buildHeadsStrip(l10n);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;
        final horizontalPadding = isWide
            ? ((contentWidth - ResponsiveLayout.maxContentWidth(contentWidth)) /
                    2)
                .clamp(16.0, double.infinity)
            : 16.0;

        return ListView(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 32),
          children: [
            Text(
              l10n.teamRotaHorizon(_horizonMonths),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (gapCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.teamRotaGaps(gapCount),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _showsFilterBanner
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildFilterBanner(l10n),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            if (headsStrip != null) ...[
              headsStrip,
              const SizedBox(height: 16),
            ],
            if (groups.isEmpty)
              _buildEmptyState(
                theme,
                l10n: l10n,
                icon: Icons.event_note,
                title: l10n.teamRotaEmptyTitle,
                body: l10n.teamRotaEmptyBody,
              )
            else
              for (var i = 0; i < groups.length; i++) ...[
                if (i > 0) const SizedBox(height: 28),
                _buildMonthHeader(theme, groups[i]),
                const SizedBox(height: 8),
                _buildPostGrid(groups[i].posts, isWide: isWide),
              ],
          ],
        );
      },
    );
  }

  bool get _showsFilterBanner =>
      _needsPeople ||
      _locationFilter != VolunteerLocations.all ||
      _selectedTagIDs.isNotEmpty;

  List<String> _filterSummaryParts(AppLocalizations l10n) {
    final parts = <String>[];
    if (_locationFilter != VolunteerLocations.all) {
      parts.add(_locationFilter);
    }
    if (_selectedTagIDs.isNotEmpty) {
      final tags = UserTagHelpers.resolveTags(
        tagIDs: _selectedTagIDs.toList(),
        allTags: _appContext.allTags,
      );
      parts.add(
        tags.isEmpty
            ? l10n.volunteersFilterTagsCount(_selectedTagIDs.length)
            : tags.map((tag) => tag.name).join(', '),
      );
    }
    if (_needsPeople) parts.add(l10n.teamRotaNeedsPeople);
    return parts;
  }

  Widget _buildFilterBanner(AppLocalizations l10n) {
    final parts = _filterSummaryParts(l10n);
    if (parts.isEmpty) return const SizedBox.shrink();

    final accent = Theme.of(context).colorScheme.primary;
    final canClearMinistries = _selectedTagIDs.isNotEmpty;

    return Material(
      color: accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _showFilterSheet,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      key: ValueKey<String>(parts.join(' · ')),
                      children: [
                        Icon(Icons.tune, size: 16, color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.bulletinShowing(parts.join(' · ')),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (canClearMinistries)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.teamRotaClearMinistries,
                onPressed: _clearMinistries,
                icon: Icon(Icons.close, size: 16, color: accent),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final l10n = AppLocalizations.of(context)!;
    final locationOptions = VolunteerLocations.filterOptionsFrom(
      _appContext.allLocations,
    );
    final tags = _appContext.activeTags;

    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      constraints: ResponsiveLayout.bottomSheetConstraintsOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void refreshSheet(VoidCallback update) {
              update();
              setSheetState(() {});
              setState(() {});
            }

            return ActionSheetShell(
              icon: Icons.tune,
              title: l10n.teamRotaFilterSheetTitle,
              subtitle: l10n.teamRotaFilterSheetSubtitle,
              children: [
                _filterSectionLabel(l10n.teamRotaFilterLocation),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final location in locationOptions)
                        ColoredChip(
                          label: location == VolunteerLocations.all
                              ? l10n.volunteersFilterAll
                              : location,
                          selected: _locationFilter == location,
                          onTap: () => _onLocationSelected(
                            location,
                            refreshSheet: refreshSheet,
                          ),
                        ),
                    ],
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  _filterSectionLabel(l10n.teamRotaFilterTeams),
                  if (_selectedTagIDs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 20, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            refreshSheet(_selectedTagIDs.clear);
                          },
                          icon: const Icon(Icons.filter_alt_off, size: 18),
                          label: Text(l10n.teamRotaClearMinistries),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in tags)
                          UserTagChip(
                            tag: tag,
                            selected: _selectedTagIDs.contains(tag.id),
                            onTap: () => _toggleTag(
                              tag,
                              refreshSheet: refreshSheet,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                _filterSectionLabel(l10n.teamRotaFilterShow),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(l10n.teamRotaNeedsPeople),
                  subtitle: Text(l10n.teamRotaNeedsPeopleSubtitle),
                  value: _needsPeople,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    refreshSheet(() => _needsPeople = value);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _filterSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Future<void> _onLocationSelected(
    final String location, {
    void Function(VoidCallback update)? refreshSheet,
  }) async {
    if (_locationFilter == location) return;
    HapticFeedback.selectionClick();
    void apply() => _locationFilter = location;
    if (refreshSheet != null) {
      refreshSheet(apply);
    } else {
      setState(apply);
    }
    await _ensureProgramsForFilter();
    if (mounted) setState(() {});
  }

  void _toggleTag(
    final UserTag tag, {
    void Function(VoidCallback update)? refreshSheet,
  }) {
    HapticFeedback.selectionClick();
    void apply() {
      if (_selectedTagIDs.contains(tag.id)) {
        _selectedTagIDs.remove(tag.id);
      } else {
        _selectedTagIDs.add(tag.id);
      }
    }

    if (refreshSheet != null) {
      refreshSheet(apply);
    } else {
      setState(apply);
    }
  }

  void _clearMinistries() {
    if (_selectedTagIDs.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(_selectedTagIDs.clear);
  }

  Widget _buildMonthHeader(ThemeData theme, TeamRotaMonthGroup group) {
    final locale = Localizations.localeOf(context).toString();
    final label = DateFormat.yMMMM(locale).format(group.monthDate);
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget? _buildHeadsStrip(AppLocalizations l10n) {
    if (_selectedTagIDs.length != 1 ||
        _locationFilter == VolunteerLocations.all) {
      return null;
    }
    final locationId = VolunteerLocations.idForName(
      locations: _appContext.allLocations,
      name: _locationFilter,
    );
    if (locationId == null) return null;
    UserTag? tag;
    for (final candidate in _appContext.allTags) {
      if (candidate.id == _selectedTagIDs.single) {
        tag = candidate;
        break;
      }
    }
    if (tag == null) return null;
    final heads = UserTagHelpers.visibleHeadsAtLocation(
      tag: tag,
      locationId: locationId,
      users: _appContext.allUsers,
    );
    if (heads.isEmpty) return null;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.teamRotaMinistryHeads(tag.name),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final user in heads)
              Material(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => DialogManager.showUserProfile(
                    selectedUser: user,
                    context: context,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyUserAvatar(user, radius: 14),
                        const SizedBox(width: 8),
                        Text(
                          user.nameForViewer(guest: false),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostGrid(
    List<TeamRotaPost> posts, {
    required bool isWide,
  }) {
    Widget card(TeamRotaPost post) {
      return TeamRotaPostCard(
        post: post,
        expanded: _expandedPostIds.contains(post.head.id),
        onToggleExpanded: () => _togglePostRoles(post.head.id),
        onOpenPost: () => _openPost(post.head),
        onRoleTap: (role) => _onRoleTap(post, role),
      );
    }

    if (!isWide) {
      return Column(
        children: [
          for (var i = 0; i < posts.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            card(posts[i]),
          ],
        ],
      );
    }
    return PairedRowList(
      itemCount: posts.length,
      runSpacing: 12,
      itemBuilder: (_, i) => card(posts[i]),
    );
  }

  void _togglePostRoles(String postId) {
    setState(() {
      if (_expandedPostIds.contains(postId)) {
        _expandedPostIds.remove(postId);
      } else {
        _expandedPostIds.add(postId);
      }
    });
  }

  Future<void> _onRoleTap(TeamRotaPost post, Map<String, dynamic> role) async {
    final l10n = AppLocalizations.of(context)!;
    final canAssign = TeamRotaQuery.canAssignRole(
      actor: _appContext.currentUser,
      role: role,
      eventDate: post.head.eventDate,
      locationId: VolunteerLocations.idForName(
        locations: _appContext.allLocations,
        name: post.head.location,
      ),
      allTags: _appContext.allTags,
      now: DateTime.now(),
    );
    if (!mounted) return;
    await showScheduleRoleDetailSheet(
      context: context,
      role: role,
      assignedUsers: _assignedUsers(role),
      canEdit: canAssign,
      editLabel: l10n.teamRotaAssignPeople,
      onEdit: () {
        Navigator.of(context).pop();
        _assignPeople(post, role);
      },
    );
  }

  Future<void> _assignPeople(
    TeamRotaPost post,
    Map<String, dynamic> role,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final tagIds = EventProgram.tagIDsOf(role);
    if (tagIds.length > 1) {
      final names = UserTagHelpers.resolveTags(
        tagIDs: tagIds,
        allTags: _appContext.allTags,
      ).map((tag) => tag.name).join(', ');
      final confirmed = await DialogManager.showConfirmationDialog(
        context: context,
        title: l10n.teamRotaSharedSlotTitle,
        content: names.isEmpty
            ? l10n.teamRotaSharedSlotBodyGeneric
            : l10n.teamRotaSharedSlotBody(names),
        confirmText: l10n.teamRotaAssignPeople,
      );
      if (!confirmed || !mounted) return;
    }

    final location =
        VolunteerLocations.normalizePostLocation(post.head.location);
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: TeamRotaQuery.uidsOf(role),
          includeCurrentUser: true,
          preferServing: true,
          title: l10n.teamRotaAssignPeople,
          allowCreatePlaceholder: canCreatePlaceholderUser(
            actor: _appContext.currentUser,
          ),
          initialLocation: location.isEmpty ? null : location,
          initialTagIDs: tagIds,
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (TeamRotaQuery.sameAssigneeIds(TeamRotaQuery.uidsOf(role), result)) {
      return;
    }
    final roleId = role['id'];
    if (roleId is! int) return;

    final saved = await DialogManager.runWithProgressDialog(
      context: context,
      title: l10n.teamRotaSavingAssignees,
      errorTitle: l10n.teamRotaCouldNotSave,
      action: () async {
        final program = await EventSupplementalDBManager(post.head.id)
            .updateRoleAssignees(roleId: roleId, uids: result);
        if (program == null) {
          throw Exception(l10n.teamRotaRoleMissing);
        }
        _programs[post.head.id] = program;
      },
    );
    if (saved && mounted) setState(() {});
  }

  List<User> _assignedUsers(Map<String, dynamic> role) {
    final users = <User>[];
    for (final id in TeamRotaQuery.uidsOf(role)) {
      final user = _appContext.userById(id);
      if (user != null) users.add(user);
    }
    return users;
  }

  Widget _buildEmptyState(
    ThemeData theme, {
    required AppLocalizations l10n,
    required IconData icon,
    required String title,
    required String body,
  }) {
    final colorScheme = theme.colorScheme;
    final canClearMinistries = _selectedTagIDs.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (canClearMinistries || _showsFilterBanner) ...[
            const SizedBox(height: 24),
            if (canClearMinistries) ...[
              FilledButton.tonalIcon(
                onPressed: _clearMinistries,
                icon: const Icon(Icons.filter_alt_off, size: 20),
                label: Text(l10n.teamRotaClearMinistries),
              ),
              const SizedBox(height: 8),
            ],
            TextButton(
              onPressed: _showFilterSheet,
              child: Text(l10n.teamRotaChangeFilter),
            ),
          ],
        ],
      ),
    );
  }

  void _openPost(EventHead head) {
    AppLinks.openPost(context, id: head.id, extra: head);
  }
}
