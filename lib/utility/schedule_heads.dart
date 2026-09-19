import '../firebase/db_managers/event_db_manager.dart';
import '../models/event/event_head.dart';

/// Extra event heads for My Schedule that must stay out of
/// [AppContext.eventHeads] (the bulletin session).
class ScheduleHeads {
  ScheduleHeads._();

  /// Distinct role post IDs that are not already in [knownHeads].
  static List<String> missingPostIDs({
    required Iterable<String> postIDs,
    required List<EventHead> knownHeads,
  }) {
    final known = {for (final head in knownHeads) head.id};
    final missing = <String>{};
    for (final id in postIDs) {
      if (id.isEmpty || known.contains(id)) continue;
      missing.add(id);
    }
    return missing.toList();
  }

  /// Session heads win when the same id appears in [extraHeads].
  static List<EventHead> merge({
    required List<EventHead> sessionHeads,
    required Map<String, EventHead> extraHeads,
  }) {
    if (extraHeads.isEmpty) return List<EventHead>.from(sessionHeads);
    final byId = {for (final head in sessionHeads) head.id: head};
    for (final entry in extraHeads.entries) {
      byId.putIfAbsent(entry.key, () => entry.value);
    }
    return byId.values.toList();
  }

  static EventHead? lookup({
    required String postID,
    required List<EventHead> sessionHeads,
    required Map<String, EventHead> extraHeads,
  }) {
    for (final head in sessionHeads) {
      if (head.id == postID) return head;
    }
    return extraHeads[postID];
  }

  /// Fetches heads for role post IDs missing from [knownHeads].
  ///
  /// Skips documents that no longer exist. Does not write to AppContext.
  static Future<Map<String, EventHead>> fetchMissing({
    required Iterable<String> postIDs,
    required List<EventHead> knownHeads,
    EventHeadDBManager? db,
  }) async {
    final missing = missingPostIDs(postIDs: postIDs, knownHeads: knownHeads);
    if (missing.isEmpty) return {};
    final manager = db ?? EventHeadDBManager();
    final fetched = await manager.fetchExistingHeadsFromList(missing);
    return {for (final head in fetched) head.id: head};
  }
}
