import 'package:cloud_firestore/cloud_firestore.dart';

class IDTrackerDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance.collection('id_tracker');

  Future<String> getAndIncrementUserID() async => await _getAndIncrementIDFromDocument('users');

  Future<String> getAndIncrementEventID() async => await _getAndIncrementIDFromDocument('events');

  Future<String> _getAndIncrementIDFromDocument(String doc) async {
    var data = await _ref.doc(doc).get();
    final String id = data['id'];
    int newID = int.parse(id) + 1;
    _ref.doc(doc).set({'id': newID.toString()});

    return id;
  }
}
