import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/post_template.dart';

class PostTemplateDBManager {
  static final CollectionReference _ref =
      FirebaseFirestore.instance.collection('post_templates');

  /// Creates a new template doc. Returns `(id, lastUpdate)`.
  Future<({String id, int lastUpdate})> addPostTemplate(
      final PostTemplate template) async {
    final docRef = _ref.doc();
    final now = DateTime.now().millisecondsSinceEpoch;
    await docRef.set(template.toJson(false));
    await updateLastUpdateTime(now);
    return (id: docRef.id, lastUpdate: now);
  }

  Future<List<PostTemplate>> fetchAllTemplates() async {
    final collection = await _ref.get();
    return collection.docs
        .where((doc) => doc.id.compareTo('ALastUpdate') != 0)
        .map((e) =>
            PostTemplate.fromMap(false, e.id, e.data() as Map<String, dynamic>))
        .toList();
  }

  Future<PostTemplate?> fetchTemplate(final String id) async {
    final doc = await _ref.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null || data is! Map<String, dynamic>)
      return null;
    return PostTemplate.fromMap(false, doc.id, data);
  }

  /// Updates an existing template. Returns the new `lastUpdate` epoch ms.
  Future<int> updateTemplate(final PostTemplate template) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _ref.doc(template.id).update(template.toJson(false));
    await updateLastUpdateTime(now);
    return now;
  }

  Future<int> fetchLastUpdateTime() async {
    final data = await _ref.doc('ALastUpdate').get();
    return data['lastUpdate'];
  }

  Future<void> updateLastUpdateTime(final int lastUpdate) async {
    await _ref
        .doc('ALastUpdate')
        .set({'lastUpdate': lastUpdate}, SetOptions(merge: true));
  }
}
