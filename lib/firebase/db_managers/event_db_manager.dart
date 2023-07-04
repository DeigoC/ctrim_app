import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrim_app/models/event/event_log.dart';
import 'package:ctrim_app/models/event/event_media.dart';
import 'package:ctrim_app/models/event/event_metadata.dart';
import 'package:ctrim_app/models/event/event_program.dart';

import '../../models/event/event_head.dart';

class EventHeadDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance.collection('events').withConverter<EventHead>(
      fromFirestore: (snap, _) => EventHead.fromMap(snap.id, snap.data()!), toFirestore: (head, _) => head.toJson());

  Future<List<EventHead>> fetchEventHeads() async {
    _ref.get();
    return [];
  }

  Future<void> saveNewHead(final EventHead head) async {
    await _ref.doc(head.id).set(head);
  }
}

class EventDBManager {
  late final DocumentReference _docRef;

  EventDBManager(String id) {
    _docRef = FirebaseFirestore.instance.collection('events').doc(id);
  }

  // * Body related

  Future<void> addBody(String json) async {
    await _docRef.collection('body').doc('body').set({'body': json});
  }

  Future<void> updateBody(final List<dynamic> rawJson) async {
    final String encodedJson = jsonEncode(rawJson);
    await _docRef.collection('body').doc('body').update({'body': encodedJson});
  }

  Future<List<dynamic>> fetchBody() async {
    final doc = await _docRef.collection('body').doc('body').get();
    final String encodedBody = doc.data()!['body'];
    final String sanitisedBody = encodedBody.replaceAll('\n', '\\n');
    final List<dynamic> result = jsonDecode(sanitisedBody);
    return result;
  }

  // * Program related - Details

  Future<EventProgramDetails> fetchProgramDetails() async {
    final doc = await _docRef.collection('program').doc('details').get();
    return EventProgramDetails.fromMap(doc.data()!);
  }

  Future<void> addProgramDetail(final EventProgramDetails details) async {
    await _docRef.collection('program').doc('details').set(details.toJson());
  }

  Future<void> updatedProgramDetail(EventProgramDetails details) async {
    await _docRef.collection('program').doc('details').update(details.toJson());
  }

  // * Program related - Roles

  Future<List<EventRole>> fetchAllRoles() async {
    final collection = await _docRef.collection('program').get();
    return collection.docs
        .where((element) => element.id.compareTo('details') != 0)
        .map<EventRole>((e) => EventRole.fromMap(e.id, e.data()))
        .toList();
  }

  Future<List<EventRole>> fetchAllRolesForGuests() async {
    final collection = await _docRef.collection('program').where('ForGuests', isEqualTo: true).get();
    return collection.docs.map<EventRole>((e) => EventRole.fromMap(e.id, e.data())).toList();
  }

  Future<void> deleteAllRoles(final List<String> deletedRoles) async {
    for (final String deletedRoleID in deletedRoles) {
      await _docRef.collection('program').doc(deletedRoleID).delete();
    }
  }

  Future<void> addAllRoles(final List<EventRole> newRoles) async {
    for (final EventRole newRole in newRoles) {
      await _docRef.collection('program').doc(newRole.id).set(newRole.toJson());
    }
  }

  Future<void> updateAllRoles(final List<EventRole> updatedRoles) async {
    for (final EventRole updatedRole in updatedRoles) {
      await _docRef.collection('program').doc(updatedRole.id).update(updatedRole.toJson());
    }
  }

  // * Supplemental - MetaData
  Future<EventMetadata> fetchMetadata() async {
    final doc = await _docRef.collection('supplemental').doc('metadata').get();
    return EventMetadata.fromMap(doc.data()!);
  }

  Future<void> addMetadata(final EventMetadata data) async {
    await _docRef.collection('supplemental').doc('metadata').set(data.toJson());
  }

  Future<void> updateMetadata(final EventMetadata data) async {
    await _docRef.collection('supplemental').doc('metadata').update(data.toJson());
  }

  // * Supplemental - Media
  Future<EventMedia> fetchMedia() async {
    final doc = await _docRef.collection('supplemental').doc('media').get();
    return EventMedia.fromMap(doc.data()!);
  }

  Future<void> addMedia(final EventMedia media) async {
    await _docRef.collection('supplemental').doc('media').set(media.toJson());
  }

  Future<void> updateMedia(EventMedia media) async {
    await _docRef.collection('supplemental').doc('media').update(media.toJson());
  }

  // * Logs
  Future<List<EventLog>> fetchAllLogs() async {
    // TODO can we only fetch before the most recent one? - figure out how to fetch accordingly
    final collection = await _docRef.collection('logs').get();
    return collection.docs
        .map<EventLog>((e) => EventLog.fromMap(DateTime.fromMillisecondsSinceEpoch(int.parse(e.id)), e.data()))
        .toList();
  }

  // to fetch the most recent update
  Future<EventLog> fetchLog(final DateTime id) async {
    final doc = await _docRef.collection('logs').doc(id.millisecondsSinceEpoch.toString()).get();
    return EventLog.fromMap(DateTime.fromMillisecondsSinceEpoch(int.parse(doc.id)), doc.data()!);
  }

  Future<void> addNewLog(final EventLog newLog) async {
    await _docRef.collection('logs').doc(newLog.id.millisecondsSinceEpoch.toString()).set(newLog.toJson());
  }
}
