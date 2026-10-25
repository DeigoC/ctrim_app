import '../models/user.dart';
import 'catalog/user_tag_helpers.dart';
import 'placeholder_user_permissions.dart';

/// Pure search helpers for the People directory and pickers.
class PeopleDirectoryQuery {
  PeopleDirectoryQuery._();

  /// Name matches with refine filters ignored (all locations, not serving-only,
  /// includes viewer-visible placeholders).
  ///
  /// Use when a refined search is empty so organisers can open an existing
  /// profile instead of creating a duplicate placeholder.
  static List<User> searchWithoutRefineFilters({
    required List<User> allUsers,
    required User viewer,
    required String searchQuery,
    Set<String> cellGroupMemberIdsLedByViewer = const {},
  }) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];

    return allUsers
        .where((user) => isIncludedInUnfilteredPeopleSearch(
              user: user,
              viewer: viewer,
              leadsCellGroupContainingUser:
                  cellGroupMemberIdsLedByViewer.contains(user.id),
            ))
        .where((user) => user.fullname.toLowerCase().contains(query))
        .toList()
      ..sort(UserTagHelpers.compareUsersBySurname);
  }

  /// Whether [user] stays in the directory after the Show chips.
  ///
  /// Neither chip: everyone. Serving alone: people who serve. Placeholders
  /// alone: placeholder profiles. Both: those two groups together (a person
  /// who serves, or a placeholder). Other members are left out.
  ///
  /// Callers must not pass `placeholdersOnly: true` into
  /// [isVisibleInVolunteerDirectory] while Serving is also on — that drops
  /// serving members before this check runs.
  static bool matchesShowFilter({
    required User user,
    required bool servingOnly,
    required bool placeholdersOnly,
    required bool userServes,
  }) {
    if (servingOnly && placeholdersOnly) {
      return user.isPlaceholder || userServes;
    }
    if (placeholdersOnly) return user.isPlaceholder;
    if (servingOnly) return userServes;
    return true;
  }
}
