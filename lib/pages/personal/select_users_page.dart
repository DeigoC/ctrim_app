import 'package:ctrim_app/firebase/db_managers/id_tracker.dart';
import 'package:ctrim_app/firebase/functions_manager.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/models/user_tag.dart';
import 'package:ctrim_app/pages/personal/view_user_roles_page.dart';
import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/utility/persist_users_local_cache.dart';
import 'package:ctrim_app/utility/responsive_layout.dart';
import 'package:ctrim_app/utility/user_activity_messages.dart';
import 'package:ctrim_app/utility/user_activity_recorder.dart';
import 'package:ctrim_app/utility/user_tag_helpers.dart';
import 'package:ctrim_app/utility/volunteer_locations.dart';
import 'package:ctrim_app/widgets/app_search_bar.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:ctrim_app/widgets/user_tag_chip.dart';
import 'package:ctrim_app/widgets/user_tag_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-screen multi-select picker for volunteers and placeholder profiles.
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
    this.postIdForPlaceholderCreate,
    this.cellGroupIdForPlaceholderCreate,
  });

  final List<String> selectedUIDs;
  final List<String> excludedUIDs;
  final bool includeCurrentUser;
  final bool allowTaskCheck;
  final String? title;

  /// When set, selection is capped (e.g. `1` for lead speaker). Selecting
  /// beyond the limit replaces the oldest selection.
  final int? maxSelection;

  /// When true (and the signed-in user passes the create gate), empty search
  /// offers "Create placeholder".
  final bool allowCreatePlaceholder;

  /// When false, hides `IsPlaceholder` users unless already selected.
  /// Defaults to true so programme, attendance, and roster pickers can assign
  /// temporary profiles.
  final bool includePlaceholders;

  /// Optional post id passed to `create_placeholder_user` for author-gate checks.
  final String? postIdForPlaceholderCreate;

  /// Optional cell group id passed to `create_placeholder_user` for leader-gate checks.
  final String? cellGroupIdForPlaceholderCreate;

  @override
  State<SelectUsersPage> createState() => _SelectUsersPageState();
}

class _SelectUsersPageState extends State<SelectUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  final CloudFunctionManager _cloudFunctionManager = CloudFunctionManager();
  late final Set<String> _selectedUIDs;
  late String _locationFilter;
  bool _placeholdersOnly = false;

  bool _isSearching = false;
  String _searchQuery = '';
  Set<String> _selectedTagIDs = {};

  @override
  void initState() {
    super.initState();
    _selectedUIDs = Set<String>.from(widget.selectedUIDs);
    final appContext = Provider.of<AppContext>(context, listen: false);
    final assignable =
        VolunteerLocations.assignableFrom(appContext.allLocations);
    _locationFilter = VolunteerLocations.defaultFilterForUser(
      appContext.currentUser.location,
      assignable,
    );
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
      final showCreate = widget.allowCreatePlaceholder &&
          _searchQuery.trim().isNotEmpty &&
          filteredUsers.isEmpty;

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
              if (widget.allowCreatePlaceholder)
                IconButton(
                  icon: const Icon(Icons.person_add_alt),
                  tooltip: l10n.selectUsersCreatePlaceholder,
                  onPressed: () => _onCreatePlaceholder(
                    appContext,
                    seedFromSearch:
                        _isSearching && _searchQuery.trim().isNotEmpty,
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
                  child: Text(
                    l10n.selectUsersSelected(_selectedUIDs.length),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(
                    filterHorizontalPadding, 8, filterHorizontalPadding, 8),
                child: Row(
                  children: [
                    ...VolunteerLocations.filterOptionsFrom(
                            appContext.allLocations)
                        .map((location) {
                      final label = location == VolunteerLocations.all
                          ? l10n.volunteersFilterAll
                          : location;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(label),
                          selected: _locationFilter == location,
                          onSelected: (_) =>
                              setState(() => _locationFilter = location),
                        ),
                      );
                    }),
                    if (widget.includePlaceholders)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: const Icon(Icons.person_outline, size: 18),
                          label: Text(l10n.volunteersShowPlaceholders),
                          selected: _placeholdersOnly,
                          onSelected: (selected) =>
                              setState(() => _placeholdersOnly = selected),
                        ),
                      ),
                  ],
                ),
              ),
              UserTagFilterBar(
                tags: appContext.allTags,
                selectedTagIDs: _selectedTagIDs,
                horizontalPadding: filterHorizontalPadding,
                onSelectionChanged: (selected) =>
                    setState(() => _selectedTagIDs = selected),
              ),
              Expanded(
                child: filteredUsers.isEmpty
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
                    : isWide
                        ? _buildWideUserGrid(
                            users: filteredUsers,
                            allTags: appContext.allTags,
                            horizontalPadding: horizontalPadding,
                            l10n: l10n,
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            itemCount: filteredUsers.length,
                            itemBuilder: (_, index) => _buildUserListTile(
                              user: filteredUsers[index],
                              allTags: appContext.allTags,
                              l10n: l10n,
                            ),
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
              child: UserTagChipRow(tags: userTags, dense: true),
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

  Widget _buildWideUserGrid({
    required List<User> users,
    required List<UserTag> allTags,
    required double horizontalPadding,
    required AppLocalizations l10n,
  }) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 108,
        crossAxisSpacing: 12,
        mainAxisSpacing: 8,
      ),
      itemCount: users.length,
      itemBuilder: (_, index) {
        final user = users[index];
        final userTags =
            UserTagHelpers.tagsForUser(user: user, allTags: allTags);
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
                          user.isPlaceholder
                              ? l10n
                                  .selectUsersPlaceholderSubtitle(user.location)
                              : user.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (userTags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          UserTagChipRow(tags: userTags, dense: true),
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
      },
    );
  }

  List<User> _filteredUsers(AppContext appContext) {
    Iterable<User> users = appContext.allUsers;

    if (!widget.includeCurrentUser) {
      users = users.where((user) => user.id != appContext.currentUser.id);
    }

    if (widget.excludedUIDs.isNotEmpty) {
      final excluded = widget.excludedUIDs.toSet();
      users = users.where((user) => !excluded.contains(user.id));
    }

    if (!widget.includePlaceholders) {
      users = users.where(
          (user) => !user.isPlaceholder || _selectedUIDs.contains(user.id));
    } else if (_placeholdersOnly) {
      users = users.where(
          (user) => user.isPlaceholder || _selectedUIDs.contains(user.id));
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

    final result = users.toList()
      ..sort((a, b) {
        final aSelected = _selectedUIDs.contains(a.id);
        final bSelected = _selectedUIDs.contains(b.id);
        if (aSelected != bSelected) {
          return aSelected ? -1 : 1;
        }
        return a.fullname.compareTo(b.fullname);
      });
    return result;
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
      builder: (ctx) => AlertDialog(
        title: Text(l10n.selectUsersCreatePlaceholderTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.selectUsersCreatePlaceholderBody),
            const SizedBox(height: 16),
            TextField(
              controller: forenameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.selectUsersForename,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: surnameController,
              decoration: InputDecoration(
                labelText: l10n.selectUsersSurname,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.selectUsersCreate)),
        ],
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
        appContext.allUsers.add(user);
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
