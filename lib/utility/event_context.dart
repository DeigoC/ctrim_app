import 'dart:collection';

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
  late final EventMedia _eventMedia;
  final EventBody _eventBody = EventBody();

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
    _eventMedia = EventMedia();
  }

  // * Head Related
  EventHead get head => _head;

  // * Body Related
  bool get haveFetchedBody => _fetchedBody;

  // ! be weary because trim() could not be applied
  bool get isBodyUntouched => _eventBody.json.compareTo('[{"insert":"Hello, time to start writing!\n"}]') == 0;
  List<dynamic> get body => _eventBody.decodedJson;

  void setBodyJson(List<dynamic> json) {
    _eventBody.encodeJson(json);
  }

  void setFetchedBody(String encodedBody) {
    _eventBody.setJson(encodedBody);
    _fetchedBody = true;
  }

  bool isSameJson(List<dynamic> json) => _eventBody.compareTo(json) == 0;

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

  // * Supplemental - Media Related

  EventMedia get media => _eventMedia;
  bool get fethcedMedia => _fetchedMedia;
  void setFetchedMedia(EventMedia media) {
    _eventMedia = media;
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
    DateTime? eventDate,
  }) async {
    final String id = await _getNewID();
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(id);
    final EventHeadDBManager headDBManager = EventHeadDBManager();

    // head stuff
    _head = EventHead(id: id); // ! add the key media!
    _head.setTitle(title);
    _head.setSubtitle(subtitle);
    _head.setRecentDate(DateTime.now());

    // metadata
    _metadata.setLastUID('1'); // ! remember this

    // log, create the new one for creation

    await headDBManager.saveNewHead(_head);
    await dbManager.addBody(_eventBody.json);
    await dbManager.addMedia(_eventMedia);
    await dbManager.addMetadata(_metadata);
    return id;
  }

  Future<String> _getNewID() async {
    final IDTrackerDBManager idTrackerDBManager = IDTrackerDBManager();
    return await idTrackerDBManager.getAndIncrementEventID();
  }

  String get id => _head.id;

  void allowSavingOfTheEdit() => _canSaveTheEditing = true;
  bool get canSaveTheEditing => _canSaveTheEditing;
  bool get isViewingChild => _viewingChild;
  void nowViewingChild() => _viewingChild = true;
  void notViewingChild() => _viewingChild = false;
}
