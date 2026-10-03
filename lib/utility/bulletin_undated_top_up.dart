import '../models/event/event_head.dart';
import 'bulletin_listing.dart';

/// Extra undated heads for the bulletin No date filter.
///
/// The session feed only keeps undated posts that happen to sit in the recent
/// edit window, and [BulletinListing] hides period parents. When No date is
/// short, the bulletin loads one more snippet and merges it for that filter
/// only. Do not write the snippet into [AppContext.eventHeads].
class BulletinUndatedTopUp {
  BulletinUndatedTopUp._();

  /// Fetch another batch when the filtered No date list is shorter than this.
  static const int thinCount = 8;

  /// Newest undated posts, and period parents, loaded on a thin list.
  static const int snippetLimit = 40;

  static bool needsSnippet({
    required BulletinTimeFilter timeFilter,
    required int filteredCount,
    required bool alreadyFetched,
  }) {
    if (alreadyFetched) return false;
    if (timeFilter != BulletinTimeFilter.undated) return false;
    return filteredCount < thinCount;
  }

  /// Session copies win on id so an in-memory edit is not replaced.
  static List<EventHead> merge({
    required Iterable<EventHead> sessionHeads,
    required Iterable<EventHead> snippet,
  }) {
    return BulletinListing.uniqueEventHeads([...sessionHeads, ...snippet]);
  }
}
