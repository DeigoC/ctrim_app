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
    final collection = await _ref.get();
    return List<EventHead>.from(collection.docs.map((e) => e.data()));
  }

  Future<EventHead> fetchHead(final String id) async {
    return await _ref.doc(id).get().then((value) => value.data() as EventHead);
  }

  Future<void> saveNewHead(final EventHead head) async {
    await _ref.doc(head.id).set(head);
  }

  Future<void> updateHead(final EventHead head) async {
    await _ref.doc(head.id).update(head.toJson());
  }
}

class EventSupplementalDBManager {
  late final CollectionReference _colRef;

  EventSupplementalDBManager(String id) {
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
    _colRef.doc('program').set(program.toJson());
  }

  Future<void> updateProgram(EventProgram program) async {
    _colRef.doc('program').update(program.toJson());
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

  Future<void> updateLog(final EventLog log) async {
    await _colRef.doc('logs').update(log.toJson());
  }

  Future<void> addLog(final EventLog log) async {
    await _colRef.doc('logs').set(log.toJson());
  }
}
