import 'package:flutter/foundation.dart';

import '../firebase/db_managers/user_db_manager.dart';

/// Fail-soft writer for `users/{actor}/supplemental/activity`.
class UserActivityRecorder {
  UserActivityRecorder({UserDBManager? userDBManager})
      : _userDBManager = userDBManager ?? UserDBManager();

  final UserDBManager _userDBManager;

  Future<void> record({
    required String? actorUserId,
    required String log,
    required String documentId,
  }) async {
    final id = (actorUserId ?? '').trim();
    if (id.isEmpty || id == '0') return;
    try {
      await _userDBManager.addActivity(
        actorUserId: id,
        log: log,
        documentId: documentId,
      );
    } catch (e, st) {
      debugPrint('UserActivityRecorder.record failed: $e\n$st');
    }
  }
}
