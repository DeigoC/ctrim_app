import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../models/user_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../utility/cache/refresh_cooldown.dart';
import '../../utility/people_directory_sections.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/users_repository.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/volunteer_role_helpers.dart';
import '../../widgets/common/action_sheet.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/catalog/user_tag_chip.dart';
import '../../widgets/volunteer_role_badge.dart';
import 'edit_user_page.dart';
import 'register_user_page.dart';
import 'view_user_profile_page.dart';

enum _VolunteerSortMode { surname, tags }

class ViewAllUsersPage extends StatefulWidget {
  const ViewAllUsersPage({super.key});

  @override
  State<ViewAllUsersPage> createState() => _ViewAllUsersPageState();
}

class _ViewAllUsersPageState extends State<ViewAllUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  final UsersRepository _usersRepository = UsersRepository();
  bool _isSearching = false;
  String _searchQuery = '';
  late String _locationFilter;
  Set<String> _selectedTagIDs = {};
  Set<VolunteerRoleKind> _selectedRoles = {};
  _VolunteerSortMode _sortMode = _VolunteerSortMode.surname;
  bool _placeholdersOnly = false;
  bool _showInactive = false;
  bool _servingOnly = true;
  bool _refreshing = false;
  String? _refreshError;

  @override
  void initState() {
    super.initState();
    final appContext = Provider.of<AppContext>(context, listen: false);
    final assignable =
        VolunteerLocations.assignableFrom(appContext.allLocations);
    _locationFilter = VolunteerLocations.defaultFilterForUser(
      appContext.currentUser.location,
      assignable,
    );
    // Cache-aware refresh: skips Firestore when lastUpdate matches.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _refreshUsersFromServer(ignoreCooldown: true),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshUsersFromServer({
    bool forceRefresh = false,
    bool ignoreCooldown = false,
  }) async {
    if (!mounted || _refreshing) return;
    final pref = Provider.of<AppContext>(context, listen: false).sharedPref;
    if (!forceRefresh && !ignoreCooldown && !pref.canRefreshUsers) {
      await Future.delayed(kRefreshCooldownBusyWait);
      return;
    }

    setState(() {
      _refreshing = true;
      _refreshError = null;
    });

    try {
      final users =
          await _usersRepository.fetchUsers(forceRefresh: forceRefresh);
      if (!mounted) return;

      final appContext = Provider.of<AppContext>(context, listen: false);
      final currentId = appContext.currentUser.id;
      appContext.setAllUsers(users);

      final refreshedCurrent = users.where((u) => u.id == currentId);
      if (refreshedCurrent.isNotEmpty) {
        appContext.setCurrentUser(refreshedCurrent.first);
      }

      pref.setUsersRefreshTime();
      if (!mounted) return;

      _logDirectorySnapshot(
        allUsers: users,
        filtered: _filteredUsers(
          users,
          appContext.allTags,
          CellGroupLeaderIndex.fromGroups(appContext.allCellGroups),
        ),
        source: 'firestore-refresh',
      );
    } catch (e, st) {
      debugPrint('[PeopleDirectory] refresh failed: $e\n$st');
      if (mounted) {
        setState(() => _refreshError = e.toString());
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _logDirectorySnapshot({
    required List<User> allUsers,
    required List<User> filtered,
    required String source,
  }) {
    if (!kDebugMode) return;

    var linked = 0;
    var placeholder = 0;
    var emptyAuthNotPlaceholder = 0;
    final locationCounts = <String, int>{};

    for (final u in allUsers) {
      final hasAuth = u.authID.trim().isNotEmpty;
      if (hasAuth) linked++;
      if (u.isPlaceholder) {
        placeholder++;
      } else if (!hasAuth) {
        emptyAuthNotPlaceholder++;
      }
      locationCounts.update(
          u.location.isEmpty ? '(empty)' : u.location, (c) => c + 1,
          ifAbsent: () => 1);
    }

    final filteredLocations = <String, int>{};
    for (final u in filtered) {
      filteredLocations.update(
        u.location.isEmpty ? '(empty)' : u.location,
        (c) => c + 1,
        ifAbsent: () => 1,
      );
    }

    final sample = filtered
        .take(20)
        .map((u) =>
            '${u.fullname}[id=${u.id} auth=${u.authID.isEmpty ? 'no' : 'yes'} ph=${u.isPlaceholder} loc=${u.location}]')
        .join(' | ');

    debugPrint(
      '[PeopleDirectory] source=$source '
      'all=${allUsers.length} filtered=${filtered.length} '
      'linked=$linked placeholder=$placeholder emptyAuthNotPh=$emptyAuthNotPlaceholder '
      'showPh=$_placeholdersOnly servingOnly=$_servingOnly locationFilter=$_locationFilter '
      'tags=${_selectedTagIDs.length} roles=${_selectedRoles.length} '
      'allByLoc=$locationCounts filteredByLoc=$filteredLocations',
    );
    if (sample.isNotEmpty) {
      debugPrint('[PeopleDirectory] sample: $sample');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveLayout.isWideScreen(screenWidth);
    final double horizontalPadding = isWide
        ? ((screenWidth - ResponsiveLayout.maxContentWidth(screenWidth)) / 2)
            .clamp(16.0, double.infinity)
        : 0.0;
    final double filterHorizontalPadding =
        horizontalPadding > 0 ? horizontalPadding : 16.0;

    return Consumer<AppContext>(builder: (context, appContext, child) {
      final cellGroupLeaders =
          CellGroupLeaderIndex.fromGroups(appContext.allCellGroups);
      final filteredUsers = _filteredUsers(
        appContext.allUsers,
        appContext.allTags,
        cellGroupLeaders,
      );
      final canEdit = appContext.currentUser.canManageVolunteers;
      final activeTags =
          appContext.allTags.where((tag) => tag.isActive).toList();

      return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? AppSearchBar(
                    controller: _searchController,
                    hintText: l10n.volunteersSearchHint,
                    inAppBar: true,
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  )
                : Text(_pageTitle(l10n)),
            actions: [
              if (!_isSearching)
                IconButton(
                  icon: _refreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Refresh people',
                  onPressed:
                      _refreshing ? null : () => _refreshUsersFromServer(),
                ),
              if (!_isSearching)
                IconButton(
                  tooltip: l10n.volunteersFilterTooltip,
                  onPressed: () => _showFilterSheet(
                    activeTags: activeTags,
                    canEdit: canEdit,
                    appContext: appContext,
                    cellGroupLeaders: cellGroupLeaders,
                  ),
                  icon: Badge(
                    isLabelVisible: _activeFilterCount > 0,
                    label: Text('${_activeFilterCount}'),
                    child: const Icon(Icons.tune),
                  ),
                ),
              if (!_isSearching)
                PopupMenuButton<_VolunteerSortMode>(
                  icon: const Icon(Icons.sort),
                  tooltip: l10n.volunteersSortTooltip,
                  initialValue: _sortMode,
                  onSelected: (mode) => setState(() => _sortMode = mode),
                  itemBuilder: (context) => [
                    CheckedPopupMenuItem(
                      value: _VolunteerSortMode.surname,
                      checked: _sortMode == _VolunteerSortMode.surname,
                      child: Text(l10n.volunteersSortSurname),
                    ),
                    CheckedPopupMenuItem(
                      value: _VolunteerSortMode.tags,
                      checked: _sortMode == _VolunteerSortMode.tags,
                      child: Text(l10n.volunteersSortTags),
                    ),
                  ],
                ),
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    } else {
                      _isSearching = true;
                    }
                  });
                },
              ),
            ],
          ),
          floatingActionButton: canEdit
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.person_add),
                  onPressed: _addUserClick,
                  label: Text(l10n.registerUser),
                )
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_refreshError != null)
                ColoredBox(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Could not refresh people. Tap retry to download again.',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              _refreshUsersFromServer(forceRefresh: true),
                          child: const Text('Retry'),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _refreshError = null),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
              _buildLocationChips(
                appContext: appContext,
                cellGroupLeaders: cellGroupLeaders,
                horizontalPadding: filterHorizontalPadding,
                l10n: l10n,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  filterHorizontalPadding,
                  0,
                  filterHorizontalPadding,
                  4,
                ),
                child: Text(
                  l10n.volunteersDirectoryIntro,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              _buildListHeader(
                l10n: l10n,
                count: filteredUsers.length,
                horizontalPadding: filterHorizontalPadding,
              ),
              if (_filterSummaryParts(l10n).isNotEmpty)
                _buildActiveFiltersBanner(
                  l10n: l10n,
                  horizontalPadding: filterHorizontalPadding,
                ),
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding + 16),
                          child: Text(
                            _emptyMessage(l10n),
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _buildSectionedUserList(
                        users: filteredUsers,
                        allTags: appContext.allTags,
                        cellGroupLeaders: cellGroupLeaders,
                        appContext: appContext,
                        horizontalPadding: horizontalPadding,
                        isWide: isWide,
                        l10n: l10n,
                      ),
              ),
            ],
          ));
    });
  }

  int get _activeFilterCount {
    var count = 0;
    if (!_servingOnly) count++;
    if (_placeholdersOnly) count++;
    if (_showInactive) count++;
    count += _selectedRoles.length;
    count += _selectedTagIDs.length;
    return count;
  }

  bool get _hasNonDefaultFilters => _activeFilterCount > 0;

  List<String> _filterSummaryParts(AppLocalizations l10n) {
    final parts = <String>[];
    if (_servingOnly) parts.add(l10n.volunteersFilterServing);
    if (_placeholdersOnly) parts.add(l10n.volunteersShowPlaceholders);
    if (_showInactive) parts.add(l10n.volunteersShowInactive);
    if (_selectedRoles.contains(VolunteerRoleKind.leader)) {
      parts.add(l10n.volunteersFilterLeaders);
    }
    if (_selectedRoles.contains(VolunteerRoleKind.areaAdmin)) {
      parts.add(l10n.volunteersFilterAdmins);
    }
    if (_selectedRoles.contains(VolunteerRoleKind.cellGroupLeader)) {
      parts.add(l10n.volunteersFilterCellGroupLeaders);
    }
    if (_selectedTagIDs.isNotEmpty) {
      parts.add(l10n.volunteersFilterTagsCount(_selectedTagIDs.length));
    }
    return parts;
  }

  void _clearFilters() {
    HapticFeedback.selectionClick();
    setState(() {
      _servingOnly = true;
      _placeholdersOnly = false;
      _showInactive = false;
      _selectedRoles = {};
      _selectedTagIDs = {};
    });
  }

  Widget _buildLocationChips({
    required AppContext appContext,
    required CellGroupLeaderIndex cellGroupLeaders,
    required double horizontalPadding,
    required AppLocalizations l10n,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 8),
      child: Row(
        children: VolunteerLocations.filterOptionsFrom(appContext.allLocations)
            .map((location) {
          final label = location == VolunteerLocations.all
              ? l10n.volunteersFilterAll
              : location;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: _locationFilter == location,
              onSelected: (_) {
                setState(() => _locationFilter = location);
                _logDirectorySnapshot(
                  allUsers: appContext.allUsers,
                  filtered: _filteredUsers(
                    appContext.allUsers,
                    appContext.allTags,
                    cellGroupLeaders,
                  ),
                  source: 'location-$location',
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListHeader({
    required AppLocalizations l10n,
    required int count,
    required double horizontalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
      child: Row(
        children: [
          Text(
            l10n.volunteersShowingCount(count),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          if (_hasNonDefaultFilters)
            TextButton(
              onPressed: _clearFilters,
              child: Text(l10n.volunteersClearFilters),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersBanner({
    required AppLocalizations l10n,
    required double horizontalPadding,
  }) {
    final parts = _filterSummaryParts(l10n);
    if (parts.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
      child: Material(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _clearFilters,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, size: 16, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.volunteersShowing(parts.join(' · ')),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
                  ),
                ),
                Icon(Icons.close, size: 16, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _useLetterSections =>
      _sortMode == _VolunteerSortMode.surname && _searchQuery.isEmpty;

  Widget _buildSectionedUserList({
    required List<User> users,
    required List<UserTag> allTags,
    required CellGroupLeaderIndex cellGroupLeaders,
    required AppContext appContext,
    required double horizontalPadding,
    required bool isWide,
    required AppLocalizations l10n,
  }) {
    final sections = _useLetterSections
        ? PeopleDirectorySections.bySurnameLetter(users)
        : [
            PeopleDirectorySection(letter: '', users: users),
          ];

    return CustomScrollView(
      slivers: [
        for (final section in sections) ...[
          if (_useLetterSections)
            SliverToBoxAdapter(
              child: _buildLetterHeader(
                section.letter,
                horizontalPadding: horizontalPadding,
              ),
            ),
          if (isWide)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                0,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 420,
                  mainAxisExtent: 92,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildUserGridCard(
                    user: section.users[index],
                    allTags: allTags,
                    cellGroupLeaders: cellGroupLeaders,
                    appContext: appContext,
                    l10n: l10n,
                  ),
                  childCount: section.users.length,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildUserListTile(
                  user: section.users[index],
                  allTags: allTags,
                  cellGroupLeaders: cellGroupLeaders,
                  appContext: appContext,
                  l10n: l10n,
                ),
                childCount: section.users.length,
              ),
            ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
      ],
    );
  }

  Widget _buildLetterHeader(
    String letter, {
    required double horizontalPadding,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding + 4, 12, horizontalPadding, 4),
      child: Text(
        letter,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildUserListTile({
    required User user,
    required List<UserTag> allTags,
    required CellGroupLeaderIndex cellGroupLeaders,
    required AppContext appContext,
    required AppLocalizations l10n,
  }) {
    final userTags =
        UserTagHelpers.tagsForUser(user: user, allTags: allTags);
    final roles = VolunteerRoleHelpers.rolesFor(
      user: user,
      cellGroupLeaders: cellGroupLeaders,
    );
    final canEditUser = canEditPlaceholderProfile(
      actor: appContext.currentUser,
      target: user,
    );
    final meta = _compactPersonMeta(roles: roles, tags: userTags);

    return ListTile(
      title: Text(user.fullname),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _personLocationLine(user, l10n),
          ),
          if (meta != null) meta,
        ],
      ),
      isThreeLine: meta != null,
      leading: MyUserAvatar(user),
      onTap: () => _onUserTap(user),
      onLongPress: canEditUser ? () => _navigateToEditUser(user) : null,
    );
  }

  Widget _buildUserGridCard({
    required User user,
    required List<UserTag> allTags,
    required CellGroupLeaderIndex cellGroupLeaders,
    required AppContext appContext,
    required AppLocalizations l10n,
  }) {
    final userTags =
        UserTagHelpers.tagsForUser(user: user, allTags: allTags);
    final roles = VolunteerRoleHelpers.rolesFor(
      user: user,
      cellGroupLeaders: cellGroupLeaders,
    );
    final canEditUser = canEditPlaceholderProfile(
      actor: appContext.currentUser,
      target: user,
    );
    final theme = Theme.of(context);
    final meta = _compactPersonMeta(roles: roles, tags: userTags);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onUserTap(user),
        onLongPress: canEditUser ? () => _navigateToEditUser(user) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              MyUserAvatar(user, radius: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.fullname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _personLocationLine(user, l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (meta != null) meta,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// At most two chips: leadership roles first, then one team tag.
  Widget? _compactPersonMeta({
    required Set<VolunteerRoleKind> roles,
    required List<UserTag> tags,
  }) {
    final chips = <Widget>[];
    final roleBadges = VolunteerRoleBadgeRow.ordered(roles);
    for (final role in roleBadges.take(1)) {
      chips.add(VolunteerRoleBadge(role: role, dense: true));
    }
    if (chips.length < 2 && tags.isNotEmpty) {
      chips.add(UserTagChip(tag: tags.first, dense: true));
    }
    if (chips.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips,
      ),
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

  void _showFilterSheet({
    required List<UserTag> activeTags,
    required bool canEdit,
    required AppContext appContext,
    required CellGroupLeaderIndex cellGroupLeaders,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final showPlaceholdersOption = canEdit ||
        appContext.allUsers.any((u) =>
            isTransientVolunteerPlaceholder(u) &&
            u.createdByUserID == appContext.currentUser.id);

    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void refreshSheet(VoidCallback update) {
              setSheetState(update);
              setState(update);
              _logDirectorySnapshot(
                allUsers: appContext.allUsers,
                filtered: _filteredUsers(
                  appContext.allUsers,
                  appContext.allTags,
                  cellGroupLeaders,
                ),
                source: 'filter-sheet',
              );
            }

            return ActionSheetShell(
              icon: Icons.tune,
              title: l10n.volunteersFilterSheetTitle,
              subtitle: l10n.volunteersFilterSheetSubtitle,
              children: [
                _filterSectionLabel(l10n.volunteersFilterShowSection),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(l10n.volunteersFilterServing),
                  subtitle: Text(l10n.volunteersFilterServingSubtitle),
                  value: _servingOnly,
                  onChanged: (value) => refreshSheet(() => _servingOnly = value),
                ),
                if (showPlaceholdersOption)
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: Text(l10n.volunteersShowPlaceholders),
                    value: _placeholdersOnly,
                    onChanged: (value) =>
                        refreshSheet(() => _placeholdersOnly = value),
                  ),
                if (canEdit)
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: Text(l10n.volunteersShowInactive),
                    subtitle: Text(l10n.volunteersStatusHelper),
                    value: _showInactive,
                    onChanged: (value) =>
                        refreshSheet(() => _showInactive = value),
                  ),
                _filterSectionLabel(l10n.volunteersFilterRolesSection),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(l10n.volunteersFilterLeaders),
                        selected:
                            _selectedRoles.contains(VolunteerRoleKind.leader),
                        onSelected: (_) => refreshSheet(() {
                          _selectedRoles = VolunteerRoleHelpers.toggleRole(
                            current: _selectedRoles,
                            role: VolunteerRoleKind.leader,
                          );
                        }),
                      ),
                      FilterChip(
                        label: Text(l10n.volunteersFilterAdmins),
                        selected: _selectedRoles
                            .contains(VolunteerRoleKind.areaAdmin),
                        onSelected: (_) => refreshSheet(() {
                          _selectedRoles = VolunteerRoleHelpers.toggleRole(
                            current: _selectedRoles,
                            role: VolunteerRoleKind.areaAdmin,
                          );
                        }),
                      ),
                      FilterChip(
                        label: Text(l10n.volunteersFilterCellGroupLeaders),
                        selected: _selectedRoles
                            .contains(VolunteerRoleKind.cellGroupLeader),
                        onSelected: (_) => refreshSheet(() {
                          _selectedRoles = VolunteerRoleHelpers.toggleRole(
                            current: _selectedRoles,
                            role: VolunteerRoleKind.cellGroupLeader,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                if (activeTags.isNotEmpty) ...[
                  _filterSectionLabel(l10n.volunteersFilterTeamsSection),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activeTags.map((tag) {
                        final selected = _selectedTagIDs.contains(tag.id);
                        return UserTagChip(
                          tag: tag,
                          selected: selected,
                          onTap: () => refreshSheet(() {
                            _selectedTagIDs = Set<String>.from(_selectedTagIDs);
                            if (selected) {
                              _selectedTagIDs.remove(tag.id);
                            } else {
                              _selectedTagIDs.add(tag.id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (_hasNonDefaultFilters)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => refreshSheet(() {
                          _servingOnly = true;
                          _placeholdersOnly = false;
                          _showInactive = false;
                          _selectedRoles = {};
                          _selectedTagIDs = {};
                        }),
                        child: Text(l10n.volunteersClearFilters),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  List<User> _filteredUsers(
    List<User> allUsers,
    List<UserTag> allTags,
    CellGroupLeaderIndex cellGroupLeaders,
  ) {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final currentUser = appContext.currentUser;
    Iterable<User> users = allUsers;

    users = users.where((user) => isVisibleInVolunteerDirectory(
          user: user,
          viewer: currentUser,
          placeholdersOnly: _placeholdersOnly,
          showInactive: _showInactive,
        ));

    if (!_placeholdersOnly && _servingOnly) {
      users = users.where((user) => VolunteerRoleHelpers.userServes(
            user: user,
            cellGroupLeaders: cellGroupLeaders,
          ));
    }

    if (_locationFilter != VolunteerLocations.all) {
      users = users.where((user) => user.location == _locationFilter);
    }

    if (_selectedTagIDs.isNotEmpty) {
      users = users.where((user) => UserTagHelpers.userMatchesTagFilter(
            user: user,
            selectedTagIDs: _selectedTagIDs,
          ));
    }

    if (_selectedRoles.isNotEmpty) {
      users = users.where((user) => VolunteerRoleHelpers.userMatchesRoleFilter(
            user: user,
            selected: _selectedRoles,
            cellGroupLeaders: cellGroupLeaders,
          ));
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      users =
          users.where((user) => user.fullname.toLowerCase().contains(query));
    }

    final result = users.toList()
      ..sort((a, b) {
        return switch (_sortMode) {
          _VolunteerSortMode.surname =>
            UserTagHelpers.compareUsersBySurname(a, b),
          _VolunteerSortMode.tags =>
            UserTagHelpers.compareUsersByPrimaryTag(a, b, allTags),
        };
      });
    return result;
  }

  String _personLocationLine(User user, AppLocalizations l10n) {
    if (user.isProfileArchived) {
      return '${l10n.volunteersStatusArchived} · ${user.location}';
    }
    if (user.isProfileHidden) {
      return '${l10n.volunteersStatusHidden} · ${user.location}';
    }
    if (user.isPlaceholder) {
      return '${l10n.volunteersPlaceholderBadge} · ${user.location}';
    }
    return user.location;
  }

  String _pageTitle(AppLocalizations l10n) {
    if (_locationFilter == VolunteerLocations.all) {
      return l10n.volunteersTitle;
    }
    return l10n.volunteersTitleLocation(_locationFilter);
  }

  String _emptyMessage(AppLocalizations l10n) {
    if (_searchQuery.isNotEmpty) {
      return l10n.volunteersEmptySearch(_searchQuery);
    }
    if (_placeholdersOnly) {
      return l10n.volunteersEmptyPlaceholders;
    }
    if (_selectedRoles.isNotEmpty) {
      return l10n.volunteersEmptyRoles;
    }
    if (_selectedTagIDs.isNotEmpty) {
      return l10n.volunteersEmptyTags;
    }
    if (_servingOnly && _locationFilter != VolunteerLocations.all) {
      return l10n.volunteersEmptyServingLocation(_locationFilter);
    }
    if (_servingOnly) {
      return l10n.volunteersEmptyServing;
    }
    if (_locationFilter != VolunteerLocations.all) {
      return l10n.volunteersEmptyLocation(_locationFilter);
    }
    return l10n.volunteersEmpty;
  }

  void _addUserClick() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const RegisterUserPage())).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _onUserTap(final User selectedUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewUserProfilePage(
          selectedUser: selectedUser,
          showPostsLink: true,
        ),
      ),
    );
  }

  Future<void> _navigateToEditUser(final User selectedUser) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditUserPage(user: selectedUser),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }
}
