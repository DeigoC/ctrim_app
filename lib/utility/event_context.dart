import 'dart:collection';

import '../firebase/db_managers/event_db_manager.dart';
import '../models/event/event_body.dart';
import '../models/event/event_head.dart';
import '../models/event/event_log.dart';
import '../models/event/event_media.dart';
import '../models/event/event_metadata.dart';
import '../models/event/event_program.dart';

class EventContext {
  late final EventHead _eventHead;
  late final EventProgramDetails _eventProgramDetails;
  final List<EventRole> _allRoles = List<EventRole>.empty(growable: true);
  late final List<EventLog> _allLogs;
  late final EventLog _latestLog;
  late final EventMetadata _eventMetadata;

  final EventBody _eventBody = EventBody();
  final EventMedia _eventMedia = EventMedia();

  bool _fetchedBody = false;

  // for viewing and editing
  EventContext.viewing({required EventHead eventHead}) {
    _eventHead = eventHead;
  }

  EventContext.adding() {
    _fetchedBody = true;
    _eventProgramDetails = EventProgramDetails();
    _eventMetadata = EventMetadata(authorUID: '1'); // ! remember this
  }

  // ? hmmm maybe we don't need a context for adding
  // * Head Related
  EventHead get head => _eventHead;

  // * Body Related
  EventBody get body => _eventBody;
  bool get haveFetchedBody => _fetchedBody;
  flagFetchedBody() => _fetchedBody = true;

  // * Program Related
  EventProgramDetails get programDetails => _eventProgramDetails;

  List<EventRole> get allRoles => UnmodifiableListView(_allRoles);
  void addRole(EventRole newRole) => _allRoles.add(newRole);
  void addManyRoles(List<EventRole> manyRoles) => _allRoles.addAll(manyRoles);
  void removeRole(String id) => _allRoles.removeWhere((element) => element.id.compareTo(id) == 0);

  sortEventsByTime() => _allRoles.sort((a, b) {
        // ? This time sorting could be a problem later, be weary of it
        if (a.startTime.compareTo(b.startTime) == 0) {
          return a.priorty.compareTo(b.priorty);
        }
        return a.startTime.compareTo(b.startTime);
      });

  // * Supplemental - Metadata Related
  EventMetadata get metadata => _eventMetadata;

  // * Supplemental - Media Related
  EventMedia get media => _eventMedia;

  // * Logs Related
  EventLog get latestLog => _latestLog;
  List<EventLog> get allLogs => _allLogs;

  Future<void> addNewPost({
    required String title,
    required String subtitle,
    DateTime? eventDate,
  }) async {
    final String id = await _getNewID();
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(id);
    final EventHeadDBManager headDBManager = EventHeadDBManager();

    // head stuff
    _eventHead = EventHead(id: id); // ! add the key media!
    _eventHead.setTitle(title);
    _eventHead.setSubtitle(subtitle);
    _eventHead.setRecentDate(DateTime.now());

    // metadata
    _eventMetadata.setLastUID('1'); // ! remember this

    // log, create the new one for creation

    await headDBManager.saveNewHead(_eventHead);
    await dbManager.addBody(_eventBody.json);
    await dbManager.addMedia(_eventMedia);
    await dbManager.addMetadata(_eventMetadata);
  }

  Future<String> _getNewID() async {
    return '1';
  }
}
