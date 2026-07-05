import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/pages/personal/view_user_roles_page.dart';
import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/responsive_layout.dart';
import 'package:ctrim_app/utility/user_tag_helpers.dart';
import 'package:ctrim_app/utility/volunteer_locations.dart';
import 'package:ctrim_app/widgets/app_search_bar.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:ctrim_app/widgets/user_tag_chip.dart';
import 'package:ctrim_app/widgets/user_tag_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-screen multi-select picker for volunteers.
///
/// Returns the selected user IDs via [Navigator.pop]. Intended as the shared
/// entry point for schedule assignees, contributors, and future user pickers.
class SelectUsersPage extends StatefulWidget {
  const SelectUsersPage({
    super.key,
    required this.selectedUIDs,
    this.excludedUIDs = const [],
    this.includeCurrentUser = false,
    this.allowTaskCheck = false,
    this.title,
  });

  final List<String> selectedUIDs;
  final List<String> excludedUIDs;
  final bool includeCurrentUser;
  final bool allowTaskCheck;
  final String? title;

  @override
  State<SelectUsersPage> createState() => _SelectUsersPageState();
}

class _SelectUsersPageState extends State<SelectUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  late final Set<String> _selectedUIDs;
  late String _locationFilter;

  bool _isSearching = false;
  String _searchQuery = '';
  Set<String> _selectedTagIDs = {};

  @override
  void initState() {
    super.initState();
    _selectedUIDs = Set<String>.from(widget.selectedUIDs);
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

    return Consumer<AppContext>(builder: (context, appContext, _) {
      final filteredUsers = _filteredUsers(appContext);

      return Scaffold(
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(_selectedUIDs.toList()),
              child: Text(l10n.selectUsersDone),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding, vertical: 8),
                child: Text(
                  l10n.selectUsersSelected(_selectedUIDs.length),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
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
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
                        child: Text(
                          _emptyMessage(l10n),
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
                      itemCount: filteredUsers.length,
                      itemBuilder: (_, index) {
                        final user = filteredUsers[index];
                        final userTags = UserTagHelpers.tagsForUser(user: user, allTags: appContext.allTags);
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
                              Text(user.location),
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
                      },
                    ),
            ),
          ],
        ),
      );
    });
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
      } else {
        _selectedUIDs.add(uid);
      }
    });
  }

  void _openUserSchedule(User user) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ViewUserRolesPage(selectedUser: user)));
  }
}
