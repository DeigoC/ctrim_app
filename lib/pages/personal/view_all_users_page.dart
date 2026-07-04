import 'package:ctrim_app/models/user.dart';
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

  @override
  void initState() {
    super.initState();
    final appContext = Provider.of<AppContext>(context, listen: false);
    _locationFilter = VolunteerLocations.defaultFilterForUser(appContext.currentUser.location);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double webHorizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 0);

    return Consumer<AppContext>(builder: (context, appContext, child) {
      final filteredUsers = _filteredUsers(appContext.allUsers);

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
          floatingActionButton: appContext.currentUser.isAreaAdmin
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
                padding: EdgeInsets.fromLTRB(webHorizontalPadding, 8, webHorizontalPadding, 8),
                child: Row(
                  children: VolunteerLocations.filterOptions.map((location) {
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
                horizontalPadding: webHorizontalPadding,
                onSelectionChanged: (selected) => setState(() => _selectedTagIDs = selected),
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
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
                        itemCount: filteredUsers.length,
                        itemBuilder: (_, index) {
                          final thisUser = filteredUsers[index];
                          final userTags = UserTagHelpers.tagsForUser(user: thisUser, allTags: appContext.allTags);
                          return ListTile(
                            title: Text(thisUser.fullname),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(thisUser.location),
                                if (userTags.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: UserTagChipRow(tags: userTags, dense: true),
                                  ),
                              ],
                            ),
                            isThreeLine: userTags.isNotEmpty,
                            leading: MyUserAvatar(thisUser),
                            onTap: () => _onUserTap(thisUser),
                            onLongPress:
                                appContext.currentUser.isAreaAdmin ? () => _navigateToEditUser(thisUser) : null,
                          );
                        }),
              ),
            ],
          ));
    });
  }

  List<User> _filteredUsers(List<User> allUsers) {
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

    final result = users.toList()..sort((a, b) => a.fullname.compareTo(b.fullname));
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
