import 'dart:collection';

import 'package:ctrim_app/models/event/event_program.dart';

import '../firebase/db_managers/event_db_manager.dart';
import '../models/event/event_body.dart';
import '../models/event/event_head.dart';
import '../models/event/event_log.dart';
import '../models/event/event_media.dart';
import '../models/event/event_metadata.dart';

class EventContext {
  late final EventHead _head;
  late final List<EventLog> _allLogs;
  late final EventLog _latestLog;
  late final EventMetadata _metadata;
  late final EventProgram _program;

  final EventBody _eventBody = EventBody();
  final EventMedia _eventMedia = EventMedia();

  bool _fetchedBody = false, _fetchedProgram = false;
  bool _canSaveTheEditing = false;

  // for viewing and editing
  EventContext.viewing({required EventHead eventHead}) {
    _head = eventHead;
    _canSaveTheEditing = false;
  }

  EventContext.adding() {
    _fetchedBody = true;
    _metadata = EventMetadata(authorUID: '1'); // ! remember this
    _program = EventProgram();
  }

  // * Head Related
  EventHead get head => _head;

  // * Body Related
  bool get haveFetchedBody => _fetchedBody;

  // ! be weary because trim() could not be applied
  bool get isBodyEmpty => _eventBody.json.compareTo('[{"insert":"\n"}]') == 0;
  List<dynamic> get body => _eventBody.decodedJson;

  void setBodyJson(List<dynamic> json) {
    _eventBody.encodeJson(json);
  }

  void setFetchedBody(String encodedBody) {
    _eventBody.setJson(encodedBody);
    _fetchedBody = true;
  }

  bool isSameJson(List<dynamic> json) => _eventBody.compareTo(json) == 0;

  // * Program Related

  bool get allDay => _program.allDay;
  bool get haveFetchedProgram => _fetchedProgram;
  List<Map<String, dynamic>> get allPrograms => UnmodifiableListView(_program.roles);

  void setProgram(EventProgram program) {
    _fetchedProgram = true;
    _program = program;
  }

  void addProgram(Map<String, dynamic> programEntry) => _program.addRole(programEntry);

  // * Supplemental - Metadata Related

  EventMetadata get metadata => _metadata;

  // * Supplemental - Media Related

  EventMedia get media => _eventMedia;

  // * Logs Related

  EventLog get latestLog => _latestLog;
  List<EventLog> get allLogs => _allLogs;

  // * General logic

  Future<void> addNewPost({
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
  }

  Future<String> _getNewID() async {
    return '1';
  }

  void allowSavingOfTheEdit() => _canSaveTheEditing = true;
  bool get canSaveTheEditing => _canSaveTheEditing;
}
