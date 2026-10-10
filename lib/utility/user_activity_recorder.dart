import 'package:flutter/foundation.dart';

import '../firebase/db_managers/user_db_manager.dart';

/// Fail-soft writer for `users/{actor}/supplemental/activity`.
class UserActivityRecorder {
  UserActivityRecorder({UserDBManager? userDBManager})
      : _userDBManager = userDBManager ?? UserDBManager();

  final UserDBManager _userDBManager;

  /// [title] is the record's name at the time (post title, person's full
  /// name, tag name). [parentId] is needed when [documentId] cannot be opened
  /// on its own (a church page needs its church).
  Future<void> record({
    required String? actorUserId,
    required String log,
    required String documentId,
    String title = '',
    String note = '',
    String parentId = '',
  }) async {
    final id = (actorUserId ?? '').trim();
    if (id.isEmpty || id == '0') return;
    try {
      await _userDBManager.addActivity(
        actorUserId: id,
        log: log,
        documentId: documentId,
        title: title,
        note: note,
        parentId: parentId,
      );
    } catch (e, st) {
      debugPrint('UserActivityRecorder.record failed: $e\n$st');
    }
  }
}
