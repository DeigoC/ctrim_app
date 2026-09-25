import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/id_tracker.dart';
import '../../firebase/functions_manager.dart';
import '../../models/user.dart';
import '../../models/user_tag.dart';
import '../../pages/events/select_catalog_items_page.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/catalog/catalog_picker_helpers.dart';
import '../../utility/cell_group_roster_helpers.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/cache/persist_users_local_cache.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../utility/people_directory_query.dart';
import '../../utility/people_directory_sections.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/volunteer_role_helpers.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/common/app_dialog.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/catalog/user_tag_chip.dart';
import '../../widgets/common/action_sheet.dart';
import 'view_user_roles_page.dart';

/// Full-screen multi-select picker for people and placeholder profiles.
///
/// Returns the selected user IDs via [Navigator.pop] when the page is closed
/// (back gesture, app bar back, or system back). Intended as the shared entry
/// point for schedule assignees, contributors, and future user pickers.
class SelectUsersPage extends StatefulWidget {
  const SelectUsersPage({
    super.key,
    required this.selectedUIDs,
    this.excludedUIDs = const [],
    this.includeCurrentUser = false,
    this.allowTaskCheck = false,
    this.title,
    this.maxSelection,
    this.allowCreatePlaceholder = false,
    this.includePlaceholders = true,
    this.preferServing = false,
    this.postIdForPlaceholderCreate,
    this.cellGroupIdForPlaceholderCreate,
    this.allowCellGroupBulkSelect = false,
    this.lockedLocation,
  });

  final List<String> selectedUIDs;
  final List<String> excludedUIDs;
  final bool includeCurrentUser;
  final bool allowTaskCheck;
  final String? title;

  /// When set, selection is capped (e.g. `1` for lead speaker). Selecting
  /// beyond the limit replaces the oldest selection.
  final int? maxSelection;

  /// When true (and the signed-in user passes the create gate), a failed search
  /// offers "Create placeholder" in the empty state (no app-bar shortcut).
  final bool allowCreatePlaceholder;

  /// When false, hides `IsPlaceholder` users unless already selected.
  /// Defaults to true so programme, attendance, and roster pickers can assign
  /// temporary profiles.
  final bool includePlaceholders;

  /// When true, the list defaults to people who serve (leaders, team tags, or
  /// cell-group leaders). Turn Serving off to pick attendees too.
  final bool preferServing;

  /// Optional post id passed to `create_placeholder_user` for author-gate checks.
  final String? postIdForPlaceholderCreate;

  /// Optional cell group id passed to `create_placeholder_user` for leader-gate checks.
  final String? cellGroupIdForPlaceholderCreate;

  /// When true, offers "Add from cell group" to merge active roster members into
  /// the current selection (expected-attendee flows).
  final bool allowCellGroupBulkSelect;

  /// When set, the location chips are hidden and the list stays on this
  /// location name (for example choosing department heads for one church site).
  final String? lockedLocation;

  @override
  State<SelectUsersPage> createState() => _SelectUsersPageState();
}

class _SelectUsersPageState extends State<SelectUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  final CloudFunctionManager _cloudFunctionManager = CloudFunctionManager();
  late final Set<String> _selectedUIDs;
  late String _locationFilter;
  bool _placeholdersOnly = false;
  late bool _servingOnly;

  bool _isSearching = false;
  String _searchQuery = '';
  Set<String> _selectedTagIDs = {};

  @override
  void initState() {
    super.initState();
    _selectedUIDs = Set<String>.from(widget.selectedUIDs);
    final locked = widget.lockedLocation?.trim() ?? '';
    if (locked.isNotEmpty) {
      _locationFilter = locked;
    } else {
      final appContext = Provider.of<AppContext>(context, listen: false);
      final assignable =
          VolunteerLocations.assignableFrom(appContext.allLocations);
      _locationFilter = VolunteerLocations.defaultFilterForUser(
        appContext.currentUser.location,
        assignable,
      );
    }
    _servingOnly = widget.preferServing;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    // Keep filter chips inset from the screen edges on narrow layouts.
    final double filterHorizontalPadding =
        horizontalPadding > 0 ? horizontalPadding : 16.0;

    return Consumer<AppContext>(builder: (context, appContext, _) {
      final filteredUsers = _filteredUsers(appContext);
      final unfilteredSearchMatches = _unfilteredSearchMatches(appContext);
      final showingUnfilteredSearchFallback =
          filteredUsers.isEmpty && unfilteredSearchMatches.isNotEmpty;
      final listUsers = showingUnfilteredSearchFallback
          ? unfilteredSearchMatches
          : filteredUsers;
      final showCreate = widget.allowCreatePlaceholder &&
          _searchQuery.trim().isNotEmpty &&
          filteredUsers.isEmpty &&
          unfilteredSearchMatches.isEmpty;

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            Navigator.of(context).pop(_selectedUIDs.toList());
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? AppSearchBar(
                    controller: _searchController,
                    hintText: l10n.volunteersSearchHint,
                    inAppBar: true,
                    autofocus: true,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  )
                : Text(widget.title ?? l10n.selectUsersTitle),
            actions: [
              if (!_isSearching)
                IconButton(
                  tooltip: l10n.volunteersFilterTooltip,
                  onPressed: () => _showFilterSheet(appContext),
                  icon: Badge(
                    isLabelVisible: _activeFilterCount(appContext) > 0,
                    label: Text('${_activeFilterCount(appContext)}'),
                    child: const Icon(Icons.tune),
                  ),
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: filterHorizontalPadding, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.selectUsersSelected(_selectedUIDs.length),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (widget.allowCellGroupBulkSelect) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonalIcon(
                            onPressed: () => _onAddFromCellGroup(appContext),
                            icon: const Icon(Icons.groups_outlined, size: 18),
                            label: Text(l10n.selectUsersAddFromCellGroup),
                          ),
                        ),
                      ],
                      // Bulk select/unselect only when tagging filters the list,
                      // so the full directory cannot be selected in one tap.
                      if (_selectedTagIDs.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: filteredUsers.isEmpty
                                  ? null
                                  : () => _selectAllFiltered(
                                        filteredUsers,
                                        appContext,
                                      ),
                              icon: const Icon(Icons.select_all, size: 18),
                              label: Text(l10n.selectUsersSelectAll),
                            ),
                            FilledButton.tonalIcon(
                              onPressed:
                                  !_filteredSelectionHasAny(filteredUsers)
                                      ? null
                                      : () =>
                                          _unselectAllFiltered(filteredUsers),
                              icon: const Icon(Icons.deselect, size: 18),
                              label: Text(l10n.selectUsersUnselectAll),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _buildActiveFiltersBanner(
                l10n: l10n,
                appContext: appContext,
                horizontalPadding: filterHorizontalPadding,
              ),
              if (showingUnfilteredSearchFallback)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    filterHorizontalPadding,
                    0,
                    filterHorizontalPadding,
                    8,
                  ),
                  child: Material(
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.volunteersSearchWithoutFiltersBanner(
                              unfilteredSearchMatches.length,
                            ),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          TextButton(
                            onPressed: _widenSearchFilters,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(l10n.volunteersWidenSearch),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: listUsers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding + 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _emptyMessage(l10n),
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              if (showCreate) ...[
                                const SizedBox(height: 16),
                                FilledButton.tonalIcon(
                                  onPressed: () => _onCreatePlaceholder(
                                    appContext,
                                    seedFromSearch: true,
                                  ),
                                  icon: const Icon(Icons.person_add_alt),
                                  label:
                                      Text(l10n.selectUsersCreatePlaceholder),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : _buildSectionedUserList(
                        users: listUsers,
                        allTags: appContext.allTags,
                        horizontalPadding: horizontalPadding,
                        isWide: isWide,
                        l10n: l10n,
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildUserListTile({
    required User user,
    required List<UserTag> allTags,
    required AppLocalizations l10n,
  }) {
    final userTags = UserTagHelpers.tagsForUser(user: user, allTags: allTags);
    final isSelected = _selectedUIDs.contains(user.id);

    return ListTile(
      leading: Checkbox(
        value: isSelected,
        onChanged: (_) => _toggleUser(user.id),
      ),
      title: Text(user.fullname),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.isPlaceholder
              ? l10n.selectUsersPlaceholderSubtitle(user.location)
              : user.location),
          if (userTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: UserTagChipLine(tags: userTags),
            ),
        ],
      ),
      isThreeLine: userTags.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyUserAvatar(user),
          if (widget.allowTaskCheck)
            IconButton(
              onPressed: () => _openUserSchedule(user),
              icon: const Icon(Icons.checklist),
              tooltip: l10n.mySchedule,
            ),
        ],
      ),
      onTap: () => _toggleUser(user.id),
    );
  }

  bool get _useLetterSections => _searchQuery.isEmpty;

  Widget _buildSectionedUserList({
    required List<User> users,
    required List<UserTag> allTags,
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
                  mainAxisExtent: 108,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildWideUserCard(
                    user: section.users[index],
                    allTags: allTags,
                    l10n: l10n,
                  ),
                  childCount: section.users.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildUserListTile(
                    user: section.users[index],
                    allTags: allTags,
                    l10n: l10n,
                  ),
                  childCount: section.users.length,
                ),
              ),
            ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
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
      padding:
          EdgeInsets.fromLTRB(horizontalPadding + 4, 12, horizontalPadding, 4),
      child: Text(
        letter,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildWideUserCard({
    required User user,
    required List<UserTag> allTags,
    required AppLocalizations l10n,
  }) {
    final userTags = UserTagHelpers.tagsForUser(user: user, allTags: allTags);
    final isSelected = _selectedUIDs.contains(user.id);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: isSelected ? colorScheme.secondaryContainer : null,
      child: InkWell(
        onTap: () => _toggleUser(user.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleUser(user.id),
              ),
              MyUserAvatar(user, radius: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      user.isPlaceholder
                          ? l10n.selectUsersPlaceholderSubtitle(user.location)
                          : user.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (userTags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      UserTagChipLine(tags: userTags),
                    ],
                  ],
                ),
              ),
              if (widget.allowTaskCheck)
                IconButton(
                  onPressed: () => _openUserSchedule(user),
                  icon: const Icon(Icons.checklist),
                  tooltip: l10n.mySchedule,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<User> _filteredUsers(AppContext appContext) {
    Iterable<User> users = appContext.allUsers;
    final cellGroupLeaders =
        CellGroupLeaderIndex.fromGroups(appContext.allCellGroups);

    if (!widget.includeCurrentUser) {
      users = users.where((user) => user.id != appContext.currentUser.id);
    }

    if (widget.excludedUIDs.isNotEmpty) {
      final excluded = widget.excludedUIDs.toSet();
      users = users.where((user) => !excluded.contains(user.id));
    }

    users = users.where((user) =>
        isSelectableVolunteerProfile(user) || _selectedUIDs.contains(user.id));

    if (!widget.includePlaceholders) {
      users = users.where(
          (user) => !user.isPlaceholder || _selectedUIDs.contains(user.id));
    } else if (_placeholdersOnly) {
      users = users.where(
          (user) => user.isPlaceholder || _selectedUIDs.contains(user.id));
    }

    if (_servingOnly && !_placeholdersOnly) {
      users = users.where((user) =>
          _selectedUIDs.contains(user.id) ||
          VolunteerRoleHelpers.userServes(
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

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      users =
          users.where((user) => user.fullname.toLowerCase().contains(query));
    }

    final result = users.toList()..sort(UserTagHelpers.compareUsersBySurname);
    return result;
  }

  /// Name matches ignoring location / Serving / tags / placeholders-only,
  /// still respecting picker exclusions and whether placeholders are allowed.
  List<User> _unfilteredSearchMatches(AppContext appContext) {
    if (_searchQuery.trim().isEmpty) return const [];

    var matches = PeopleDirectoryQuery.searchWithoutRefineFilters(
      allUsers: appContext.allUsers,
      viewer: appContext.currentUser,
      searchQuery: _searchQuery,
    );

    if (!widget.includeCurrentUser) {
      matches = matches
          .where((user) => user.id != appContext.currentUser.id)
          .toList();
    }
    if (widget.excludedUIDs.isNotEmpty) {
      final excluded = widget.excludedUIDs.toSet();
      matches = matches.where((user) => !excluded.contains(user.id)).toList();
    }

    matches = matches
        .where((user) =>
            isSelectableVolunteerProfile(user) ||
            _selectedUIDs.contains(user.id) ||
            (widget.includePlaceholders && user.isPlaceholder))
        .toList();

    if (!widget.includePlaceholders) {
      matches = matches
          .where(
              (user) => !user.isPlaceholder || _selectedUIDs.contains(user.id))
          .toList();
    }

    return matches;
  }

  bool get _locationIsLocked =>
      (widget.lockedLocation?.trim() ?? '').isNotEmpty;

  String _defaultLocationFilter(AppContext appContext) {
    if (_locationIsLocked) return widget.lockedLocation!.trim();
    return VolunteerLocations.defaultFilterForUser(
      appContext.currentUser.location,
      VolunteerLocations.assignableFrom(appContext.allLocations),
    );
  }

  int _activeFilterCount(AppContext appContext) {
    var count = 0;
    if (!_locationIsLocked &&
        _locationFilter != _defaultLocationFilter(appContext)) {
      count++;
    }
    if (widget.preferServing && !_servingOnly) count++;
    if (widget.includePlaceholders && _placeholdersOnly) count++;
    count += _selectedTagIDs.length;
    return count;
  }

  List<String> _scopeSummaryParts(AppLocalizations l10n) {
    final parts = <String>[];
    if (_locationFilter != VolunteerLocations.all) {
      parts.add(_locationFilter);
    }
    if (_servingOnly) parts.add(l10n.volunteersFilterServing);
    if (_placeholdersOnly) parts.add(l10n.volunteersShowPlaceholders);
    if (_selectedTagIDs.isNotEmpty) {
      parts.add(l10n.volunteersFilterTagsCount(_selectedTagIDs.length));
    }
    return parts;
  }

  void _clearFilters(AppContext appContext) {
    setState(() {
      _locationFilter = _defaultLocationFilter(appContext);
      _servingOnly = widget.preferServing;
      _placeholdersOnly = false;
      _selectedTagIDs = {};
    });
  }

  Widget _buildActiveFiltersBanner({
    required AppLocalizations l10n,
    required AppContext appContext,
    required double horizontalPadding,
  }) {
    final parts = _scopeSummaryParts(l10n);
    if (parts.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    final canClear = _activeFilterCount(appContext) > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 0),
      child: Material(
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
                  onTap: () => _showFilterSheet(appContext),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
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
                      ],
                    ),
                  ),
                ),
              ),
              if (canClear)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.volunteersClearFilters,
                  onPressed: () => _clearFilters(appContext),
                  icon: Icon(Icons.close, size: 16, color: accent),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
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

  void _showFilterSheet(AppContext appContext) {
    final l10n = AppLocalizations.of(context)!;
    final activeTags =
        appContext.allTags.where((tag) => tag.isActive).toList();
    final showShowSection =
        widget.preferServing || widget.includePlaceholders;

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
            }

            return ActionSheetShell(
              icon: Icons.tune,
              title: l10n.volunteersFilterSheetTitle,
              subtitle: l10n.selectUsersFilterSheetSubtitle,
              children: [
                if (!_locationIsLocked) ...[
                  _filterSectionLabel(l10n.volunteersFilterLocationSection),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: VolunteerLocations.filterOptionsFrom(
                              appContext.allLocations)
                          .map((location) {
                        final label = location == VolunteerLocations.all
                            ? l10n.volunteersFilterAll
                            : location;
                        return FilterChip(
                          label: Text(label),
                          selected: _locationFilter == location,
                          onSelected: (selected) {
                            if (!selected) return;
                            refreshSheet(() => _locationFilter = location);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (showShowSection)
                  _filterSectionLabel(l10n.volunteersFilterShowSection),
                if (widget.preferServing)
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: Text(l10n.volunteersFilterServing),
                    subtitle: Text(l10n.volunteersFilterServingSubtitle),
                    value: _servingOnly,
                    onChanged: (value) =>
                        refreshSheet(() => _servingOnly = value),
                  ),
                if (widget.includePlaceholders)
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: Text(l10n.volunteersShowPlaceholders),
                    value: _placeholdersOnly,
                    onChanged: (value) =>
                        refreshSheet(() => _placeholdersOnly = value),
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
                if (_activeFilterCount(appContext) > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => refreshSheet(() {
                          _locationFilter = _defaultLocationFilter(appContext);
                          _servingOnly = widget.preferServing;
                          _placeholdersOnly = false;
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

  void _widenSearchFilters() {
    final locked = widget.lockedLocation?.trim() ?? '';
    setState(() {
      _locationFilter = locked.isEmpty ? VolunteerLocations.all : locked;
      _servingOnly = false;
      _placeholdersOnly = false;
      _selectedTagIDs = {};
    });
  }

  String _emptyMessage(AppLocalizations l10n) {
    if (_searchQuery.isNotEmpty) {
      return l10n.volunteersEmptySearch(_searchQuery);
    }
    if (_placeholdersOnly) {
      return l10n.volunteersEmptyPlaceholders;
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

  void _toggleUser(String uid) {
    setState(() {
      if (_selectedUIDs.contains(uid)) {
        _selectedUIDs.remove(uid);
        return;
      }
      final max = widget.maxSelection;
      if (max != null && _selectedUIDs.length >= max) {
        _selectedUIDs.clear();
      }
      _selectedUIDs.add(uid);
    });
  }

  bool _filteredSelectionHasAny(List<User> filteredUsers) {
    for (final user in filteredUsers) {
      if (_selectedUIDs.contains(user.id)) return true;
    }
    return false;
  }

  void _selectAllFiltered(List<User> filteredUsers, AppContext appContext) {
    setState(() {
      _mergeUserIdsIntoSelection(
        filteredUsers.map((user) => user.id).toSet(),
        appContext,
      );
    });
  }

  void _unselectAllFiltered(List<User> filteredUsers) {
    setState(() {
      final ids = filteredUsers.map((user) => user.id).toSet();
      _selectedUIDs.removeWhere(ids.contains);
    });
  }

  Future<void> _onAddFromCellGroup(AppContext appContext) async {
    final l10n = AppLocalizations.of(context)!;
    final activeGroups =
        appContext.allCellGroups.where((group) => group.isActive).toList();
    if (activeGroups.isEmpty) {
      await DialogManager.showAlertDialog(
        context: context,
        title: l10n.cellGroupsSectionTitle,
        content: l10n.cellGroupsNoneAvailable,
      );
      return;
    }

    final picked = await SelectCatalogItemsPage.open(
      context: context,
      page: SelectCatalogItemsPage(
        title: l10n.cellGroupsSelectTitle,
        searchHint: l10n.cellGroupsSearchHint,
        emptyMessage: l10n.cellGroupsNoneAvailable,
        noResultsMessage: l10n.selectCatalogNoResults,
        allEntries:
            CatalogPickerHelpers.fromCellGroups(appContext.allCellGroups),
        selectedIds: const {},
        showLocationFilter: true,
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) return;

    Set<String>? fetchedIds;
    final ok = await DialogManager.runWithProgressDialog(
      context: context,
      title: l10n.selectUsersAddingFromCellGroup,
      action: () async {
        fetchedIds =
            await CellGroupRosterHelpers.fetchActiveLinkedUserIds(picked);
      },
    );
    if (!ok || fetchedIds == null || !mounted) return;

    setState(() => _mergeUserIdsIntoSelection(fetchedIds!, appContext));
  }

  void _mergeUserIdsIntoSelection(Set<String> userIds, AppContext appContext) {
    var ids = userIds;
    if (!widget.includeCurrentUser) {
      ids = ids.where((id) => id != appContext.currentUser.id).toSet();
    }
    if (widget.excludedUIDs.isNotEmpty) {
      final excluded = widget.excludedUIDs.toSet();
      ids = ids.where((id) => !excluded.contains(id)).toSet();
    }
    if (!widget.includePlaceholders) {
      final userMap = {for (final user in appContext.allUsers) user.id: user};
      ids = ids.where((id) {
        final user = userMap[id];
        return user != null &&
            isSelectableVolunteerProfile(user) &&
            (!user.isPlaceholder || _selectedUIDs.contains(id));
      }).toSet();
    } else {
      ids = ids.where((id) {
        final user = appContext.userById(id);
        return user == null || isSelectableVolunteerProfile(user);
      }).toSet();
    }

    final max = widget.maxSelection;
    if (max != null) {
      for (final id in ids) {
        if (_selectedUIDs.length >= max) break;
        _selectedUIDs.add(id);
      }
      return;
    }

    _selectedUIDs.addAll(ids);
  }

  Future<void> _onCreatePlaceholder(
    AppContext appContext, {
    required bool seedFromSearch,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final parts = seedFromSearch
        ? _searchQuery.trim().split(RegExp(r'\s+'))
        : const <String>[];
    final forename = parts.isNotEmpty ? parts.first : '';
    final surname = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final forenameController = TextEditingController(text: forename);
    final surnameController = TextEditingController(text: surname);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: Icons.person_add_alt_1_outlined,
        title: l10n.selectUsersCreatePlaceholderTitle,
        message: l10n.selectUsersCreatePlaceholderBody,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: forenameController,
              autofocus: true,
              decoration: AppDialog.inputDecoration(
                label: l10n.selectUsersForename,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: surnameController,
              decoration: AppDialog.inputDecoration(
                label: l10n.selectUsersSurname,
              ),
            ),
          ],
        ),
        actions: AppDialogActions(
          onCancel: () => Navigator.of(ctx).pop(false),
          cancelLabel: l10n.cancel,
          onConfirm: () => Navigator.of(ctx).pop(true),
          confirmLabel: l10n.selectUsersCreate,
        ),
      ),
    );

    if (!mounted || confirmed != true) return;

    final newForename = forenameController.text.trim();
    final newSurname = surnameController.text.trim();
    if (newForename.isEmpty || newSurname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectUsersNameRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final location = _locationFilter == VolunteerLocations.all
        ? appContext.currentUser.location
        : _locationFilter;

    final created = await DialogManager.runWithProgressDialog(
      context: context,
      title: l10n.selectUsersCreatingPlaceholder,
      subtitle: l10n.selectUsersCreatingPlaceholderSubtitle,
      errorTitle: l10n.selectUsersCreatePlaceholderFailed,
      action: () async {
        final raw = await _cloudFunctionManager.createPlaceholderUser(
          forename: newForename,
          surname: newSurname,
          location: location,
          postId: widget.postIdForPlaceholderCreate,
          cellGroupId: widget.cellGroupIdForPlaceholderCreate,
        );
        final id = raw['Id'] as String?;
        if (id == null || id.isEmpty) {
          throw StateError('Missing user id from create_placeholder_user');
        }
        final user = User.fromMap(id, raw);
        if (!mounted) return;
        appContext.addOrUpdateUser(user);
        await IDTrackerDBManager()
            .tryTouchLastUpdate(IDTrackerDBManager.usersDoc);
        await persistUsersLocalCache(appContext.allUsers);
        await UserActivityRecorder().record(
          actorUserId: appContext.currentUser.id,
          log: UserActivityMessages.registeredVolunteer,
          documentId: user.id,
        );
        setState(() {
          final max = widget.maxSelection;
          if (max != null && _selectedUIDs.length >= max) {
            _selectedUIDs.clear();
          }
          _selectedUIDs.add(user.id);
          _searchQuery = '';
          _searchController.clear();
          _isSearching = false;
        });
      },
    );

    if (!mounted || !created) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.selectUsersPlaceholderCreated),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openUserSchedule(User user) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ViewUserRolesPage(selectedUser: user)));
  }
}
