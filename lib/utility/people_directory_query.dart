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
  }) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];

    return allUsers
        .where((user) => isIncludedInUnfilteredPeopleSearch(
              user: user,
              viewer: viewer,
            ))
        .where((user) => user.fullname.toLowerCase().contains(query))
        .toList()
      ..sort(UserTagHelpers.compareUsersBySurname);
  }
}
