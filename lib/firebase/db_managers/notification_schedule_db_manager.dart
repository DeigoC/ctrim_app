import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/notification_schedule.dart';

class NotificationScheduleDBManager {
  static final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance
          .collection('notification_schedules')
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data() ?? {},
            toFirestore: (data, _) => data,
          );

  Future<List<NotificationSchedule>> fetchAll() async {
    final snapshot = await _ref.get();
    final schedules = snapshot.docs
        .map((doc) => NotificationSchedule.fromMap(doc.id, doc.data()))
        .toList();
    schedules.sort((a, b) {
      final locationCompare = a.location.compareTo(b.location);
      if (locationCompare != 0) return locationCompare;
      return a.postTagId.compareTo(b.postTagId);
    });
    return schedules;
  }

  Future<NotificationSchedule> create(
      final NotificationSchedule schedule) async {
    final docRef = _ref.doc();
    final stored = NotificationSchedule(
      id: docRef.id,
      enabled: schedule.enabled,
      postTagId: schedule.postTagId,
      location: schedule.location,
      timing: schedule.timing ?? NotificationScheduleTiming.dayBefore,
      clockTime: schedule.clockTime,
      hoursBefore: schedule.hoursBefore,
    );
    await docRef.set(stored.toConfigJson());
    return stored;
  }

  /// Updates the hub's fields. Does not touch last-sent or last-error.
  Future<void> updateConfig(final NotificationSchedule schedule) async {
    await _ref.doc(schedule.id).update(schedule.toConfigJson());
  }

  Future<void> setEnabled({
    required String id,
    required bool enabled,
  }) async {
    await _ref.doc(id).update({'Enabled': enabled});
  }

  Future<void> delete(final String id) async {
    await _ref.doc(id).delete();
  }
}
