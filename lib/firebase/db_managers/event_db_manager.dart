import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/event/event_attendance.dart';
import '../../models/event/event_head.dart';
import '../../models/event/event_log.dart';
import '../../models/event/event_media.dart';
import '../../models/event/event_metadata.dart';
import '../../models/event/event_program.dart';

class EventHeadDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance.collection('events').withConverter<EventHead>(
      fromFirestore: (snap, _) => EventHead.fromMap(snap.id, snap.data()!), toFirestore: (head, _) => head.toJson());

  Future<List<EventHead>> fetchEventHeads() async {
    final collection = await _ref.orderBy('RecentDate', descending: true).limit(40).get();
    return List<EventHead>.from(collection.docs.map((e) => e.data()));
  }

  Future<EventHead> fetchHead(final String id) async {
    return await _ref.doc(id).get().then((value) => value.data() as EventHead);
  }

  Future<List<EventHead>> fetchHeadsFromList(final List<String> ids) async {
    final List<EventHead> result = [];
    for (final String id in ids) {
      result.add(await fetchHead(id));
    }
    return result;
  }

  Future<void> saveNewHead(final EventHead head) async {
    await _ref.doc(head.id).set(head);
  }

  Future<void> updateHead(final EventHead head) async {
    await _ref.doc(head.id).update(head.toJson());
  }

  /// Heads marked as period/season parents (`IsPeriodParent`).
  /// Sorted client-side by [RecentDate] so no composite index is required.
  Future<List<EventHead>> fetchPeriodParentHeads({int limit = 40}) async {
    final collection = await _ref.where('IsPeriodParent', isEqualTo: true).limit(limit).get();
    final heads = List<EventHead>.from(collection.docs.map((e) => e.data()));
    heads.sort((a, b) => b.recentDate.compareTo(a.recentDate));
    return heads;
  }

  /// Updates only attendance counts on the head (public denorm for guest-visible cards).
  Future<void> updateAttendanceCounts({
    required String id,
    required int interestedCount,
    required int attendeeCount,
  }) async {
    await _ref.doc(id).update({
      'InterestedCount': interestedCount < 0 ? 0 : interestedCount,
      'AttendeeCount': attendeeCount < 0 ? 0 : attendeeCount,
    });
  }
}

class EventSupplementalDBManager {
  late final CollectionReference _colRef;
  late final String _postId;

  EventSupplementalDBManager(String id) {
    _postId = id;
    _colRef = FirebaseFirestore.instance.collection('events').doc(id).collection('supplemental');
  }

  // * Body related

  Future<void> addBody(String json) async {
    await _colRef.doc('body').set({'Body': json});
  }

  Future<void> updateBody(final List<dynamic> rawJson) async {
    final String encodedJson = jsonEncode(rawJson);
    await _colRef.doc('body').update({'Body': encodedJson});
  }

  Future<String> fetchBody() async {
    final doc = await _colRef.doc('body').get();
    final data = doc.data() as Map<String, dynamic>;
    final String encodedBody = data['Body'];
    return encodedBody;
  }

  // * Program related - Details

  Future<EventProgram> fetchProgram() async {
    final doc = await _colRef.doc('program').get();
    return EventProgram.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> addProgram(EventProgram program) async {
    await _colRef.doc('program').set(program.toJson());
  }

  Future<void> updateProgram(EventProgram program) async {
    await _colRef.doc('program').update(program.toJson());
  }

  // * Supplemental - MetaData

  Future<EventMetadata> fetchMetadata() async {
    final doc = await _colRef.doc('metadata').get();
    return EventMetadata.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> addMetadata(final EventMetadata data) async {
    await _colRef.doc('metadata').set(data.toJson());
  }

  Future<void> updateMetadata(final EventMetadata data) async {
    await _colRef.doc('metadata').update(data.toJson());
  }

  /// Bidirectionally syncs [ChildrenIDs] when a post's parent changes.
  ///
  /// Does not write the child's [ParentID] — caller updates that via [updateMetadata].
  /// Returns updated parent metadata keyed by parent post id (for AppContext cache).
  Future<Map<String, EventMetadata>> syncChildrenLinkage({
    required String childId,
    required String? oldParentId,
    required String? newParentId,
  }) async {
    final String? oldId = (oldParentId == null || oldParentId.isEmpty) ? null : oldParentId;
    final String? newId = (newParentId == null || newParentId.isEmpty) ? null : newParentId;
    if (oldId == newId) return {};
    if (newId == childId) {
      throw ArgumentError('A post cannot be its own parent');
    }

    final Map<String, EventMetadata> updated = {};

    if (oldId != null) {
      final oldManager = EventSupplementalDBManager(oldId);
      final oldMeta = await oldManager.fetchMetadata();
      oldMeta.removeChildID(childId);
      await oldManager.updateMetadata(oldMeta);
      updated[oldId] = oldMeta;
    }

    if (newId != null) {
      final newManager = EventSupplementalDBManager(newId);
      final newMeta = await newManager.fetchMetadata();
      newMeta.addChildID(childId);
      await newManager.updateMetadata(newMeta);
      updated[newId] = newMeta;
    }

    return updated;
  }

  /// Children ids for cycle checks when reparenting.
  Future<List<String>> fetchChildrenIDs() async {
    final meta = await fetchMetadata();
    return List<String>.from(meta.childrenPostIDs);
  }

  // * Supplemental - Media

  Future<EventMedia> fetchMedia() async {
    final doc = await _colRef.doc('media').get();
    return EventMedia.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> addMedia(final EventMedia media) async {
    await _colRef.doc('media').set(media.toJson());
  }

  Future<void> updateMedia(EventMedia media) async {
    await _colRef.doc('media').update(media.toJson());
  }

  // * Logs
  Future<EventLog> fetchLog() async {
    final doc = await _colRef.doc('logs').get();
    return EventLog.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> setLog(final EventLog log) async {
    await _colRef.doc('logs').set(log.toJson());
  }

  Future<void> addLogEntry({required String logMessage, required String uid, required DateTime ts}) async {
    final log = await fetchLog();
    log.addLog(log: logMessage, uid: uid, ts: ts);
    await _colRef.doc('logs').update(log.toJson());
  }

  // * Attendance (private lists; counts live on EventHead)

  Future<EventAttendance> fetchAttendance() async {
    final doc = await _colRef.doc('attendance').get();
    if (!doc.exists || doc.data() == null) {
      return EventAttendance();
    }
    return EventAttendance.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> setAttendance(final EventAttendance attendance) async {
    await _colRef.doc('attendance').set(attendance.toJson());
  }

  /// Adds or removes the caller's interest and syncs counts on the head.
  Future<EventAttendance> setOwnInterest({
    required String authId,
    required String displayName,
    String? userId,
    required bool interested,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final headRef = firestore.collection('events').doc(_postId);
    final attRef = _colRef.doc('attendance');

    return firestore.runTransaction((tx) async {
      final attSnap = await tx.get(attRef);
      final attendance = attSnap.exists && attSnap.data() != null
          ? EventAttendance.fromMap(attSnap.data() as Map<String, dynamic>)
          : EventAttendance();

      if (interested) {
        attendance.putInterest(InterestedEntry(
          authId: authId,
          displayName: displayName,
          userId: userId,
        ));
      } else {
        attendance.removeInterest(authId);
      }

      tx.set(attRef, attendance.toJson());
      tx.update(headRef, {
        'InterestedCount': attendance.interestedCount,
        'AttendeeCount': attendance.attendeeCount,
      });
      return attendance;
    });
  }

  /// Removes any interest entry (moderation by workers / post admins).
  Future<EventAttendance> removeInterestForAuthId(final String authId) async {
    final firestore = FirebaseFirestore.instance;
    final headRef = firestore.collection('events').doc(_postId);
    final attRef = _colRef.doc('attendance');

    return firestore.runTransaction((tx) async {
      final attSnap = await tx.get(attRef);
      if (!attSnap.exists || attSnap.data() == null) {
        return EventAttendance();
      }
      final attendance = EventAttendance.fromMap(attSnap.data() as Map<String, dynamic>);
      attendance.removeInterest(authId);
      tx.set(attRef, attendance.toJson());
      tx.update(headRef, {
        'InterestedCount': attendance.interestedCount,
        'AttendeeCount': attendance.attendeeCount,
      });
      return attendance;
    });
  }

  /// Replaces the full attendee list and syncs [AttendeeCount] (staff-managed).
  /// Preserves [EventAttendance.expectedUserIds] and interest.
  Future<EventAttendance> saveAttendees(final List<AttendeeEntry> attendees) async {
    final firestore = FirebaseFirestore.instance;
    final headRef = firestore.collection('events').doc(_postId);
    final attRef = _colRef.doc('attendance');

    return firestore.runTransaction((tx) async {
      final attSnap = await tx.get(attRef);
      final attendance = attSnap.exists && attSnap.data() != null
          ? EventAttendance.fromMap(attSnap.data() as Map<String, dynamic>)
          : EventAttendance();

      final data = attendance.toMutableMap();
      data['attendees'] = attendees.map((e) => e.toJson()).toList();
      final updated = EventAttendance.fromMap(data);

      tx.set(attRef, updated.toJson());
      tx.update(headRef, {
        'InterestedCount': updated.interestedCount,
        'AttendeeCount': updated.attendeeCount,
      });
      return updated;
    });
  }

  /// Replaces the expected-attendee checklist (staff-managed). Preserves attendees
  /// and interest; does not change public head counts.
  Future<EventAttendance> saveExpectedUserIds(final List<String> expectedUserIds) async {
    final firestore = FirebaseFirestore.instance;
    final attRef = _colRef.doc('attendance');

    return firestore.runTransaction((tx) async {
      final attSnap = await tx.get(attRef);
      final attendance = attSnap.exists && attSnap.data() != null
          ? EventAttendance.fromMap(attSnap.data() as Map<String, dynamic>)
          : EventAttendance();

      final data = attendance.toMutableMap();
      data['expectedUserIds'] = expectedUserIds;
      final updated = EventAttendance.fromMap(data);

      tx.set(attRef, updated.toJson());
      return updated;
    });
  }
}
