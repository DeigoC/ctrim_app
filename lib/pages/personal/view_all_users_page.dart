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
      final filteredUsers = _filteredUsers(appContext.allUsers, appContext.allTags);
      final activeFiltersSummary = _buildActiveFiltersSummary(l10n, appContext, webHorizontalPadding);

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
                tooltip: l10n.volunteersFiltersTitle,
                icon: Badge(
                  isLabelVisible: _hasActiveFilters(
                    VolunteerLocations.defaultFilterForUser(appContext.currentUser.location),
                  ),
                  child: const Icon(Icons.filter_list),
                ),
                onPressed: () => _showFilterSheet(appContext, l10n),
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
              if (activeFiltersSummary != null) activeFiltersSummary,
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

  bool _hasActiveFilters(String defaultLocation) {
    return _locationFilter != defaultLocation ||
        _selectedTagIDs.isNotEmpty ||
        _sortMode != _VolunteerSortMode.surname;
  }

  Widget? _buildActiveFiltersSummary(
    AppLocalizations l10n,
    AppContext appContext,
    double horizontalPadding,
  ) {
    final defaultLocation = VolunteerLocations.defaultFilterForUser(appContext.currentUser.location);
    if (!_hasActiveFilters(defaultLocation)) return null;

    final summary = _activeFiltersDescription(l10n, appContext);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () => _showFilterSheet(appContext, l10n),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 8),
          child: Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _activeFiltersDescription(AppLocalizations l10n, AppContext appContext) {
    final defaultLocation = VolunteerLocations.defaultFilterForUser(appContext.currentUser.location);
    final parts = <String>[];

    if (_locationFilter != defaultLocation) {
      parts.add(_locationFilter == VolunteerLocations.all ? l10n.volunteersFilterAll : _locationFilter);
    }

    if (_selectedTagIDs.isNotEmpty) {
      final tagNames = appContext.allTags
          .where((tag) => _selectedTagIDs.contains(tag.id))
          .map((tag) => tag.name)
          .toList();
      if (tagNames.isNotEmpty) {
        parts.add(tagNames.join(', '));
      }
    }

    if (_sortMode == _VolunteerSortMode.tags) {
      parts.add('${l10n.volunteersSortLabel}: ${l10n.volunteersSortTags}');
    }

    return parts.join(' · ');
  }

  Future<void> _showFilterSheet(AppContext appContext, AppLocalizations l10n) async {
    final defaultLocation = VolunteerLocations.defaultFilterForUser(appContext.currentUser.location);
    final activeTags = appContext.allTags.where((tag) => tag.isActive).toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updateFilters(VoidCallback apply) {
              setState(apply);
              setSheetState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.volunteersFiltersTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.volunteersLocationFilterLabel, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: VolunteerLocations.filterOptions.map((location) {
                        final label = location == VolunteerLocations.all ? l10n.volunteersFilterAll : location;
                        return FilterChip(
                          label: Text(label),
                          selected: _locationFilter == location,
                          onSelected: (_) => updateFilters(() => _locationFilter = location),
                        );
                      }).toList(),
                    ),
                    if (activeTags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(l10n.userTagsAssignLabel, style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: activeTags.map((tag) {
                          final selected = _selectedTagIDs.contains(tag.id);
                          return UserTagChip(
                            tag: tag,
                            selected: selected,
                            onTap: () {
                              updateFilters(() {
                                final next = Set<String>.from(_selectedTagIDs);
                                if (selected) {
                                  next.remove(tag.id);
                                } else {
                                  next.add(tag.id);
                                }
                                _selectedTagIDs = next;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      if (_selectedTagIDs.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => updateFilters(() => _selectedTagIDs = {}),
                            child: Text(l10n.userTagsFilterClear),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                    Text(l10n.volunteersSortLabel, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: Text(l10n.volunteersSortSurname),
                          selected: _sortMode == _VolunteerSortMode.surname,
                          onSelected: (_) => updateFilters(() => _sortMode = _VolunteerSortMode.surname),
                        ),
                        FilterChip(
                          label: Text(l10n.volunteersSortTags),
                          selected: _sortMode == _VolunteerSortMode.tags,
                          onSelected: (_) => updateFilters(() => _sortMode = _VolunteerSortMode.tags),
                        ),
                      ],
                    ),
                    if (_hasActiveFilters(defaultLocation)) ...[
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () {
                          updateFilters(() {
                            _locationFilter = defaultLocation;
                            _selectedTagIDs = {};
                            _sortMode = _VolunteerSortMode.surname;
                          });
                        },
                        child: Text(l10n.volunteersFiltersReset),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
