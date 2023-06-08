import 'dart:collection';

import 'package:ctrim_app/models/event_body.dart';
import 'package:ctrim_app/models/event_role.dart';

class EventContext {
  late List<EventRole> _allRoles;
  late EventBody _eventBody;

  EventContext({required EventBody eventBody}) {
    _eventBody = eventBody;
    _allRoles = List.empty(growable: true);
  }

  List<EventRole> get allRoles => UnmodifiableListView(_allRoles); // ? Does this work, what is this?
  EventBody get eventBody => _eventBody;

  addRole(EventRole role) => _allRoles.add(role);
  addManyRoles(List<EventRole> roles) => _allRoles.addAll(roles);
  removeRole(String roleId) => _allRoles.removeWhere((element) => element.id.compareTo(roleId) == 0);
}
