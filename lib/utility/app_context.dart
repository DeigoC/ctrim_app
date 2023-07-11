import 'dart:collection';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/event_metadata.dart';
import 'package:flutter/material.dart';

// handles some highlevel behaviours (like notifications) and persistant data for network optimisation
class AppContext extends ChangeNotifier {
  static final List<EventHead> _eventHeads = List.empty(growable: true);
  static final Map<String, EventMetadata> _metaData = {};

  AppContext({required List<EventHead> heads}) {
    _eventHeads.addAll(heads);
  }

  void addMetadata(String id, EventMetadata data) => _metaData[id] = data;
  EventMetadata? getMetadata(String id) => _metaData[id];

  List<EventHead> get eventHeads => UnmodifiableListView(_eventHeads);
}
