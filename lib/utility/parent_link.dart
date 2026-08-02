/// Helpers for related-post parent/child links (`ParentID` / `ChildrenIDs`).
class ParentLink {
  ParentLink._();

  /// Whether setting [postId]'s parent to [newParentId] would create a cycle.
  ///
  /// Returns true when [newParentId] is [postId] itself or any descendant of
  /// [postId] (walked via [childrenOf]). A null [newParentId] never cycles.
  static bool wouldCreateCycle({
    required String postId,
    required String? newParentId,
    required List<String> Function(String id) childrenOf,
  }) {
    if (newParentId == null || newParentId.isEmpty) return false;
    if (newParentId == postId) return true;

    final queue = <String>[postId];
    final seen = <String>{postId};
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      for (final childId in childrenOf(id)) {
        if (childId.isEmpty) continue;
        if (childId == newParentId) return true;
        if (seen.add(childId)) queue.add(childId);
      }
    }
    return false;
  }

  /// Same as [wouldCreateCycle] but loads children asynchronously (e.g. Firestore).
  static Future<bool> wouldCreateCycleAsync({
    required String postId,
    required String? newParentId,
    required Future<List<String>> Function(String id) childrenOf,
  }) async {
    if (newParentId == null || newParentId.isEmpty) return false;
    if (newParentId == postId) return true;

    final queue = <String>[postId];
    final seen = <String>{postId};
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      final children = await childrenOf(id);
      for (final childId in children) {
        if (childId.isEmpty) continue;
        if (childId == newParentId) return true;
        if (seen.add(childId)) queue.add(childId);
      }
    }
    return false;
  }
}
