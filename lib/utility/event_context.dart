import 'dart:collection';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/event_log.dart';
import 'package:ctrim_app/models/event/event_media.dart';
import 'package:ctrim_app/models/event/event_metadata.dart';

import '../models/event/event_body.dart';
import '../models/event/event_program.dart';

class EventContext {
  late final EventHead _eventHead;
  late final EventProgramDetails _eventProgramDetails;
  late final List<EventRole> _allRoles;
  late final List<EventLog> _allLogs;
  late final EventMetadata _eventMetadata;

  final EventBody _eventBody = EventBody();
  final EventMedia _eventMedia = EventMedia(srcTypes: {});

  bool _fetchedBody = false;

  // for viewing and editing
  EventContext.viewing({required EventHead eventHead}) {
    _eventHead = eventHead;
  }

  // ? hmmm maybe we don't need a context for adding

  // * Head Related
  // * Body Related
  // * Program Related
  // * Supplemental - Metadata Related
  // * Supplemental - Media Related
  // * Logs Related

  List<EventRole> get allRoles => UnmodifiableListView(_allRoles); // ? Does this work, what is this?
  EventBody get eventBody => _eventBody;
  bool get haveFetchedBody => _fetchedBody;

  addRole(EventRole role) => _allRoles.add(role);
  addManyRoles(List<EventRole> roles) => _allRoles.addAll(roles);
  removeRole(String roleId) => _allRoles.removeWhere((element) => element.id.compareTo(roleId) == 0);

  sortEventsByTime() => _allRoles.sort((a, b) {
        // ? This time sorting could be a problem later, be weary of it
        if (a.startTime.compareTo(b.startTime) == 0) {
          return a.priorty.compareTo(b.priorty);
        }
        return a.startTime.compareTo(b.startTime);
      });

  setJson(String json) => _eventBody.setJson(json);
  flagFetchedBody() => _fetchedBody = true;
}
