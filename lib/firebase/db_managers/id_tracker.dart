import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class IDTrackerDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance.collection('id_tracker');

  static const String usersDoc = 'users';
  static const String eventsDoc = 'events';
  static const String cellGroupsDoc = 'cell_groups';

  Future<String> getAndIncrementUserID() async => await _getAndIncrementIDFromDocument(usersDoc);

  Future<String> getAndIncrementEventID() async => await _getAndIncrementIDFromDocument(eventsDoc);

  Future<String> getAndIncrementCellGroupID() async =>
      await _getAndIncrementIDFromDocument(cellGroupsDoc);

  Future<String> getCurrentUserID() async {
    var data = await _ref.doc(usersDoc).get();
    final String id = data['id'];
    final String currentID = (int.parse(id) - 1).toString();
    return currentID;
  }

  Future<int> fetchLastUpdate(final String doc) async {
    final snap = await _ref.doc(doc).get();
    final data = snap.data();
    if (data is! Map) {
      return 0;
    }
    return _parseLastUpdate(data['lastUpdate']);
  }

  /// Merges [lastUpdate] onto the tracker doc. Does not change the ID counter.
  Future<int> touchLastUpdate(final String doc) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _ref.doc(doc).set({'lastUpdate': now}, SetOptions(merge: true));
    return now;
  }

  Future<int> touchUsersLastUpdate() async => touchLastUpdate(usersDoc);

  Future<int> touchEventsLastUpdate() async => touchLastUpdate(eventsDoc);

  Future<int> tryTouchLastUpdate(final String doc) async {
    try {
      return await touchLastUpdate(doc);
    } catch (e) {
      debugPrint('IDTrackerDBManager: could not bump lastUpdate for $doc: $e');
      return 0;
    }
  }

  Future<String> _getAndIncrementIDFromDocument(final String doc) async {
    var data = await _ref.doc(doc).get();
    final String id = data['id'];
    final int newID = int.parse(id) + 1;
    await _ref.doc(doc).set({'id': newID.toString()}, SetOptions(merge: true));

    return id;
  }

  static int _parseLastUpdate(final dynamic rawValue) {
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is num) {
      return rawValue.toInt();
    }
    if (rawValue is Timestamp) {
      return rawValue.toDate().millisecondsSinceEpoch;
    }
    return 0;
  }
}
