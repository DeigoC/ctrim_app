import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrim_app/models/post_template.dart';

class PostTemplateDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance
      .collection('post_templates')
      .withConverter<PostTemplate>(
          fromFirestore: (snap, _) => PostTemplate.fromMap(snap.id, snap.data()!),
          toFirestore: (template, _) => template.toJson());

  Future<void> addPostTemplate(final PostTemplate template) async {
    await _ref.doc(template.id).update(template.toJson());
  }

  Future<List<PostTemplate>> fetchAllTemplates() async {
    final collection = await _ref.get();
    return collection.docs.where((doc) => doc.id != 'ALastUpdate').map((e) => e.data() as PostTemplate).toList();
  }

  Future<void> updateTemplate(final PostTemplate template) async {
    await _ref.doc(template.id).update(template.toJson());
    // TODO also update the last update time for the location post
  }

  Future<int> fetchLastUpdateTime() async {
    final data = await _ref.doc('ALastUpdate').get();
    final String dateStr = data['lastUpdate'];
    return int.parse(dateStr);
  }

  Future<void> updateLastUpdateTime(final int lastUpdate) async {
    await _ref.doc('ALastUpdate').set({'lastUpdate': lastUpdate});
  }
}
