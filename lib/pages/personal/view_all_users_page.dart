import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/models/user_tag.dart';
import 'package:ctrim_app/pages/personal/edit_user_page.dart';
import 'package:ctrim_app/pages/personal/register_user_page.dart';
import 'package:ctrim_app/pages/personal/view_user_profile_page.dart';
import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/placeholder_user_permissions.dart';
import 'package:ctrim_app/utility/responsive_layout.dart';
import 'package:ctrim_app/utility/user_tag_helpers.dart';
import 'package:ctrim_app/utility/volunteer_locations.dart';
import 'package:ctrim_app/widgets/action_sheet.dart';
import 'package:ctrim_app/widgets/app_search_bar.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:ctrim_app/widgets/user_tag_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _VolunteerSortMode { surname, tags }

class ViewAllUsersPage extends StatefulWidget {
  const ViewAllUsersPage({super.key});

  @override
  State<ViewAllUsersPage> createState() => _ViewAllUsersPageState();
}

class _ViewAllUsersPageState extends State<ViewAllUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  late String _locationFilter;
  Set<String> _selectedTagIDs = {};
  _VolunteerSortMode _sortMode = _VolunteerSortMode.surname;
  bool _showPlaceholders = false;

  @override
  void initState() {
    super.initState();
    final appContext = Provider.of<AppContext>(context, listen: false);
    final assignable = VolunteerLocations.assignableFrom(appContext.allLocations);
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
    final double filterHorizontalPadding =
        horizontalPadding > 0 ? horizontalPadding : 16.0;

    return Consumer<AppContext>(builder: (context, appContext, child) {
      final filteredUsers = _filteredUsers(appContext.allUsers, appContext.allTags);
      final canEdit = appContext.currentUser.canManageVolunteers;
      final activeTags = appContext.allTags.where((tag) => tag.isActive).toList();

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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(
                    filterHorizontalPadding, 8, filterHorizontalPadding, 8),
                child: Row(
                  children: [
                    ...VolunteerLocations.filterOptionsFrom(appContext.allLocations).map((location) {
                      final label = location == VolunteerLocations.all ? l10n.volunteersFilterAll : location;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(label),
                          selected: _locationFilter == location,
                          onSelected: (_) => setState(() => _locationFilter = location),
                        ),
                      );
                    }),
                    if (activeTags.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      FilterChip(
                        avatar: Icon(
                          Icons.label_outline,
                          size: 18,
                          color: _selectedTagIDs.isNotEmpty
                              ? Theme.of(context).colorScheme.onSecondaryContainer
                              : null,
                        ),
                        label: Text(
                          _selectedTagIDs.isEmpty
                              ? l10n.volunteersFilterTags
                              : l10n.volunteersFilterTagsCount(_selectedTagIDs.length),
                        ),
                        selected: _selectedTagIDs.isNotEmpty,
                        onSelected: (_) => _showTagFilterSheet(activeTags),
                      ),
                    ],
                    if (canEdit ||
                        appContext.allUsers.any((u) =>
                            u.isPlaceholder && u.createdByUserID == appContext.currentUser.id)) ...[
                      const SizedBox(width: 4),
                      FilterChip(
                        avatar: const Icon(Icons.person_outline, size: 18),
                        label: Text(l10n.volunteersShowPlaceholders),
                        selected: _showPlaceholders,
                        onSelected: (selected) => setState(() => _showPlaceholders = selected),
                      ),
                    ],
                  ],
                ),
              ),
              if (_selectedTagIDs.isNotEmpty)
                _buildSelectedTagsSummary(activeTags, filterHorizontalPadding, l10n),
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding + 16),
                          child: Text(
                            _emptyMessage(l10n),
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : isWide
                        ? _buildWideUserGrid(
                            users: filteredUsers,
                            allTags: appContext.allTags,
                            appContext: appContext,
                            horizontalPadding: horizontalPadding,
                            l10n: l10n,
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            itemCount: filteredUsers.length,
                            itemBuilder: (_, index) {
                              final user = filteredUsers[index];
                              final userTags =
                                  UserTagHelpers.tagsForUser(user: user, allTags: appContext.allTags);
                              final canEditUser = canEditPlaceholderProfile(
                                actor: appContext.currentUser,
                                target: user,
                              );
                              return ListTile(
                                title: Text(user.fullname),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.isPlaceholder
                                        ? '${l10n.volunteersPlaceholderBadge} · ${user.location}'
                                        : user.location),
                                    if (userTags.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: UserTagChipRow(tags: userTags, dense: true),
                                      ),
                                  ],
                                ),
                                isThreeLine: userTags.isNotEmpty,
                                leading: MyUserAvatar(user),
                                onTap: () => _onUserTap(user),
                                onLongPress: canEditUser ? () => _navigateToEditUser(user) : null,
                              );
                            },
                          ),
              ),
            ],
          ));
    });
  }

  Widget _buildSelectedTagsSummary(
    List<UserTag> activeTags,
    double horizontalPadding,
    AppLocalizations l10n,
  ) {
    final selected = activeTags.where((tag) => _selectedTagIDs.contains(tag.id)).toList();
    if (selected.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...selected.map(
            (tag) => UserTagChip(
              tag: tag,
              selected: true,
              onTap: () {
                setState(() {
                  _selectedTagIDs = Set<String>.from(_selectedTagIDs)..remove(tag.id);
                });
              },
            ),
          ),
          ActionChip(
            label: Text(l10n.userTagsFilterClear),
            onPressed: () => setState(() => _selectedTagIDs = {}),
          ),
        ],
      ),
    );
  }

  void _showTagFilterSheet(List<UserTag> activeTags) {
    final l10n = AppLocalizations.of(context)!;
    var draft = Set<String>.from(_selectedTagIDs);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ActionSheetShell(
              icon: Icons.label_outline,
              title: l10n.volunteersFilterTagsSheetTitle,
              subtitle: l10n.volunteersFilterTagsSheetSubtitle,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: activeTags.map((tag) {
                      final selected = draft.contains(tag.id);
                      return UserTagChip(
                        tag: tag,
                        selected: selected,
                        onTap: () {
                          setSheetState(() {
                            draft = Set<String>.from(draft);
                            if (selected) {
                              draft.remove(tag.id);
                            } else {
                              draft.add(tag.id);
                            }
                          });
                          setState(() => _selectedTagIDs = Set<String>.from(draft));
                        },
                      );
                    }).toList(),
                  ),
                ),
                if (draft.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          setSheetState(() => draft = {});
                          setState(() => _selectedTagIDs = {});
                        },
                        child: Text(l10n.userTagsFilterClear),
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

  Widget _buildWideUserGrid({
    required List<User> users,
    required List<UserTag> allTags,
    required AppContext appContext,
    required double horizontalPadding,
    required AppLocalizations l10n,
  }) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 88),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 108,
        crossAxisSpacing: 12,
        mainAxisSpacing: 8,
      ),
      itemCount: users.length,
      itemBuilder: (_, index) {
        final user = users[index];
        final userTags = UserTagHelpers.tagsForUser(user: user, allTags: allTags);
        final canEditUser = canEditPlaceholderProfile(
          actor: appContext.currentUser,
          target: user,
        );
        final theme = Theme.of(context);
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
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.isPlaceholder
                              ? '${l10n.volunteersPlaceholderBadge} · ${user.location}'
                              : user.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (userTags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          UserTagChipRow(tags: userTags, dense: true),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<User> _filteredUsers(List<User> allUsers, List<UserTag> allTags) {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final currentUser = appContext.currentUser;
    Iterable<User> users = allUsers;

    users = users.where((user) {
      if (!user.isPlaceholder) return true;
      if (!_showPlaceholders) return false;
      if (currentUser.isAreaAdmin) return true;
      return user.createdByUserID == currentUser.id;
    });

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
      users = users.where((user) => user.fullname.toLowerCase().contains(query));
    }

    final result = users.toList()
      ..sort((a, b) {
        return switch (_sortMode) {
          _VolunteerSortMode.surname => UserTagHelpers.compareUsersBySurname(a, b),
          _VolunteerSortMode.tags => UserTagHelpers.compareUsersByPrimaryTag(a, b, allTags),
        };
      });
    return result;
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
    if (_selectedTagIDs.isNotEmpty) {
      return l10n.volunteersEmptyTags;
    }
    if (_locationFilter != VolunteerLocations.all) {
      return l10n.volunteersEmptyLocation(_locationFilter);
    }
    return l10n.volunteersEmpty;
  }

  void _addUserClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterUserPage())).then((_) {
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
