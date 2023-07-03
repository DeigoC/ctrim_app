import 'dart:collection';

import '../models/event/event_body.dart';
import '../models/event/event_head.dart';
import '../models/event/event_log.dart';
import '../models/event/event_media.dart';
import '../models/event/event_metadata.dart';
import '../models/event/event_program.dart';

class EventContext {
  static const String _startingBodyText = '[{"insert":"Hello, time to start writing!\n"}]';
  late final EventHead _eventHead;
  late final EventProgramDetails _eventProgramDetails;
  late final List<EventRole> _allRoles;
  late final List<EventLog> _allLogs;
  late final EventLog _latestLog;
  late final EventMetadata _eventMetadata;

  final EventBody _eventBody = EventBody();
  final EventMedia _eventMedia = EventMedia(srcTypes: {});

  bool _fetchedBody = false;

  // for viewing and editing
  EventContext.viewing({required EventHead eventHead}) {
    _eventHead = eventHead;
  }

  EventContext.adding() {
    _eventBody.setJson(_startingBodyText);
    _fetchedBody = true;
    _eventProgramDetails = EventProgramDetails(currentID: 1, finishTime: DateTime.now());
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
  EventMedia get eventMedia => _eventMedia;

  // * Logs Related
  EventLog get latestLog => _latestLog;
  List<EventLog> get allLogs => _allLogs;
}
