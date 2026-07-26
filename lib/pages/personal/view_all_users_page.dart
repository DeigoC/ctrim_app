import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/models/user_tag.dart';
import 'package:ctrim_app/pages/personal/edit_user_page.dart';
import 'package:ctrim_app/pages/personal/register_user_page.dart';
import 'package:ctrim_app/pages/personal/view_user_profile_page.dart';
import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/user_tag_helpers.dart';
import 'package:ctrim_app/utility/volunteer_locations.dart';
import 'package:ctrim_app/widgets/app_search_bar.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:ctrim_app/widgets/user_tag_chip.dart';
import 'package:ctrim_app/widgets/user_tag_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utility/responsive_layout.dart';

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
    // Wide: modest insets so the grid can fill the viewport.
    // Narrow: flush with the screen edge (ListTiles provide their own padding).
    final double horizontalPadding = isWide ? 16 : 0;

    return Consumer<AppContext>(builder: (context, appContext, child) {
      final filteredUsers = _filteredUsers(appContext.allUsers, appContext.allTags);
      final canEdit = appContext.currentUser.isAreaAdmin;

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
                padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 8),
                child: Row(
                  children: VolunteerLocations.filterOptionsFrom(appContext.allLocations).map((location) {
                    final label = location == VolunteerLocations.all ? l10n.volunteersFilterAll : location;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: _locationFilter == location,
                        onSelected: (_) => setState(() => _locationFilter = location),
                      ),
                    );
                  }).toList(),
                ),
              ),
              UserTagFilterBar(
                tags: appContext.allTags,
                selectedTagIDs: _selectedTagIDs,
                horizontalPadding: horizontalPadding,
                onSelectionChanged: (selected) => setState(() => _selectedTagIDs = selected),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                      child: Text(
                        l10n.volunteersSortLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(l10n.volunteersSortSurname),
                        selected: _sortMode == _VolunteerSortMode.surname,
                        onSelected: (_) => setState(() => _sortMode = _VolunteerSortMode.surname),
                      ),
                    ),
                    FilterChip(
                      label: Text(l10n.volunteersSortTags),
                      selected: _sortMode == _VolunteerSortMode.tags,
                      onSelected: (_) => setState(() => _sortMode = _VolunteerSortMode.tags),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          _emptyMessage(l10n),
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : isWide
                        ? _buildWideUserGrid(
                            users: filteredUsers,
                            allTags: appContext.allTags,
                            canEdit: canEdit,
                            horizontalPadding: horizontalPadding,
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            itemCount: filteredUsers.length,
                            itemBuilder: (_, index) {
                              final user = filteredUsers[index];
                              final userTags =
                                  UserTagHelpers.tagsForUser(user: user, allTags: appContext.allTags);
                              return ListTile(
                                title: Text(user.fullname),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.location),
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
                                onLongPress: canEdit ? () => _navigateToEditUser(user) : null,
                              );
                            },
                          ),
              ),
            ],
          ));
    });
  }

  Widget _buildWideUserGrid({
    required List<User> users,
    required List<UserTag> allTags,
    required bool canEdit,
    required double horizontalPadding,
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
        final theme = Theme.of(context);
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _onUserTap(user),
            onLongPress: canEdit ? () => _navigateToEditUser(user) : null,
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
                          user.location,
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
    Iterable<User> users = allUsers;

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

  void _navigateToEditUser(final User selectedUser) async {
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
