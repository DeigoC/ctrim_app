import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class IDTrackerDBManager {
  static final CollectionReference _ref =
      FirebaseFirestore.instance.collection('id_tracker');

  static const String usersDoc = 'users';
  static const String eventsDoc = 'events';
  static const String cellGroupsDoc = 'cell_groups';
  static const String directoriesDoc = 'directories';

  static const String postTagsField = 'post_tags';
  static const String userLocationsField = 'user_locations';
  static const String userTagsField = 'user_tags';
  static const String cellGroupsField = 'cell_groups';
  static const String churchesField = 'churches';
  static const String testimonialsField = 'testimonials';
  static const String ctrimInfoField = 'ctrim_info';

  static const List<String> directoryFields = [
    postTagsField,
    userLocationsField,
    userTagsField,
    cellGroupsField,
    churchesField,
    testimonialsField,
    ctrimInfoField,
  ];

  Future<String> getAndIncrementUserID() async =>
      await _getAndIncrementIDFromDocument(usersDoc);

  Future<String> getAndIncrementEventID() async =>
      await _getAndIncrementIDFromDocument(eventsDoc);

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

  /// One read of `id_tracker/directories`. [DirectoryWatermarks.exists] is
  /// false until a signed-in client creates the doc.
  Future<DirectoryWatermarks> fetchDirectoryWatermarks() async {
    final snap = await _ref.doc(directoriesDoc).get();
    if (!snap.exists) {
      return const DirectoryWatermarks(exists: false, values: {});
    }
    final data = snap.data();
    final values = <String, int>{};
    if (data is Map) {
      final raw = data['lastUpdate'];
      if (raw is Map) {
        for (final entry in raw.entries) {
          values[entry.key.toString()] = _parseLastUpdate(entry.value);
        }
      }
    }
    return DirectoryWatermarks(exists: true, values: values);
  }

  /// Sets one field inside `lastUpdate` without replacing the other fields.
  Future<int> trySetDirectoryLastUpdate(
    final String field,
    final int lastUpdate,
  ) async {
    try {
      await _setDirectoryField(field, lastUpdate);
      return lastUpdate;
    } catch (e) {
      debugPrint('IDTrackerDBManager: could not set directories.$field: $e');
      return 0;
    }
  }

  Future<int> tryTouchDirectoryLastUpdate(final String field) {
    return trySetDirectoryLastUpdate(
      field,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Creates `id_tracker/directories` when it is missing. Nested map merge
  /// would wipe sibling fields, so this is only for the first write.
  Future<bool> trySeedDirectoryWatermarks(
    final Map<String, int> values,
  ) async {
    if (values.isEmpty) return false;
    try {
      await _ref.doc(directoriesDoc).set({'lastUpdate': values});
      return true;
    } catch (e) {
      debugPrint('IDTrackerDBManager: could not seed directories: $e');
      return false;
    }
  }

  Future<void> _setDirectoryField(
      final String field, final int lastUpdate) async {
    final doc = _ref.doc(directoriesDoc);
    try {
      await doc.update({'lastUpdate.$field': lastUpdate});
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
      await doc.set({
        'lastUpdate': {field: lastUpdate}
      });
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

class DirectoryWatermarks {
  const DirectoryWatermarks({required this.exists, required this.values});

  final bool exists;
  final Map<String, int> values;

  int valueOf(final String field) => values[field] ?? 0;
}
