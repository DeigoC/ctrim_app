import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/event/event_head.dart';

class EventHeadDBManager {
  final CollectionReference _ref = FirebaseFirestore.instance.collection('events');

  Future<List<EventHead>> fetchEventHeads() async {
    _ref.get();
    return [];
  }
}

class EventDBManager {
  late final DocumentReference _docRef;

  EventDBManager(String id) {
    _docRef = FirebaseFirestore.instance.collection('events').doc(id);
  }

  Future addBody(Map<String, dynamic> data) async {
    await _docRef.collection('body').doc('body').set(data);
  }
}
