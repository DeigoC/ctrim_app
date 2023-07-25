import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrim_app/firebase/db_managers/id_tracker.dart';
import 'package:ctrim_app/models/event/event_program.dart';

import '../firebase/db_managers/event_db_manager.dart';
import '../models/event/event_body.dart';
import '../models/event/event_head.dart';
import '../models/event/event_log.dart';
import '../models/event/event_media.dart';
import '../models/event/event_metadata.dart';

class EventContext {
  late final EventHead _head;
  late final EventLog _log;
  late final EventMetadata _metadata;
  late final EventProgram _program;
  late final EventMedia _media;
  final EventBody _body = EventBody();

  bool _fetchedBody = false,
      _fetchedProgram = false,
      _fetchedMedia = false,
      _canSaveTheEditing = false,
      _viewingChild = false,
      _fetchedLogs = false,
      _fetchedMeta = false;

  // for viewing and editing
  EventContext.viewing({required EventHead eventHead, bool? viewingChild}) {
    _head = eventHead;
    _canSaveTheEditing = false;
    _viewingChild = viewingChild ?? _viewingChild;
  }

  EventContext.adding({String? parentID}) {
    _fetchedBody = true;
    _metadata = EventMetadata(authorUID: '1', parentID: parentID); // ! remember this
    _program = EventProgram();
    _media = EventMedia();
  }

  // * Head Related
  EventHead get head => _head;

  // * Body Related
  bool get haveFetchedBody => _fetchedBody;

  // ! be weary because trim() could not be applied
  bool get isBodyUntouched => _body.json.compareTo('[{"insert":"Hello, time to start writing!\n"}]') == 0;
  List<dynamic> get body => _body.decodedJson;

  void setBodyJson(List<dynamic> json) {
    _body.encodeJson(json);
  }

  void setFetchedBody(String encodedBody) {
    _body.setJson(encodedBody);
    _fetchedBody = true;
  }

  bool isSameJson(List<dynamic> json) => _body.compareTo(json) == 0;

  // * Program Related (and the Event Date)

  EventProgram get program => _program;
  bool get haveFetchedProgram => _fetchedProgram;
  List<Map<String, dynamic>> get allPrograms => UnmodifiableListView(_program.roles);

  void setFetchedProgram(EventProgram program) {
    _fetchedProgram = true;
    _program = program;
  }

  void addProgram(Map<String, dynamic> programEntry) => _program.addRole(programEntry);

  // * Supplemental - Metadata Related

  EventMetadata get metadata => _metadata;

  void setFetchedMetadata(EventMetadata data) {
    if (!_fetchedMeta) {
      _metadata = data;
      _fetchedMeta = true;
    }
  }

  bool get fetchedMetadata => _fetchedMeta;

  // * Supplemental - Media Related

  EventMedia get media => _media;
  bool get fethcedMedia => _fetchedMedia;
  void setFetchedMedia(EventMedia media) {
    _media = media;
    _fetchedMedia = true;
  }

  // * Logs Related
  EventLog get log => _log;
  bool get fetchedLogs => _fetchedLogs;

  void setFetchedLogs(EventLog log) {
    _log = log;
    _fetchedLogs = true;
  }

  // * General logic

  Future<String> addNewPost({
    required String title,
    required String subtitle,
    required String uid,
    DateTime? eventDate,
  }) async {
    final String id = await _getNewID();
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(id);
    final EventHeadDBManager headDBManager = EventHeadDBManager();
    final DateTime now = DateTime.now();

    // head stuff
    _head = EventHead(id: id); // ! add the key media!
    _head.setTitle(title);
    _head.setSubtitle(subtitle);
    _head.setRecentDate(now);

    // metadata
    _metadata.setLastUID(uid);

    // log, create the new one for creation
    _log = EventLog({'uid': uid, 'log': 'Publication', 'ts': Timestamp.fromDate(now)});

    await headDBManager.saveNewHead(_head);
    dbManager.addBody(_body.json);
    dbManager.addMedia(_media);
    dbManager.addMetadata(_metadata);
    dbManager.addLog(_log);
    return id;
  }

  Future<void> updatePost({required String log, required String uid}) async {
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(id);
    final EventHeadDBManager headDBManager = EventHeadDBManager();
    final DateTime now = DateTime.now();

    head.setRecentDate(now);
    _log.addLog({'log': log, 'uid': uid, 'ts': Timestamp.fromDate(now)});

    await headDBManager.updateHead(_head);
    dbManager.updateBody(_body.decodedJson);
    dbManager.updateMedia(_media);
    dbManager.updateMetadata(_metadata);
    dbManager.updateLog(_log);
  }

  Future<String> _getNewID() async {
    final IDTrackerDBManager idTrackerDBManager = IDTrackerDBManager();
    return await idTrackerDBManager.getAndIncrementEventID();
  }

  String get id => _head.id;

  bool isUserAdminOfPost(String currentUID) {
    return _metadata.authorUID.compareTo(currentUID) == 0 || _metadata.contributorUIDs.contains(currentUID);
  }

  void allowSavingOfTheEdit() => _canSaveTheEditing = true;
  bool get canSaveTheEditing => _canSaveTheEditing;
  bool get isViewingChild => _viewingChild;
  void nowViewingChild() => _viewingChild = true;
  void notViewingChild() => _viewingChild = false;
}
