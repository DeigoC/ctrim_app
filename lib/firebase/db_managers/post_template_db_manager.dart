import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrim_app/models/post_template.dart';

class PostTemplateDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance.collection('post_templates');

  Future<void> addPostTemplate(final PostTemplate template) async {
    await _ref.doc().set(template.toJson(false));
  }

  Future<List<PostTemplate>> fetchAllTemplates() async {
    final collection = await _ref.get();
    return collection.docs
        .where((doc) => doc.id.compareTo('ALastUpdate') != 0)
        .map((e) => PostTemplate.fromMap(false, e.id, e.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateTemplate(final PostTemplate template) async {
    await _ref.doc(template.id).update(template.toJson(false));
  }

  Future<int> fetchLastUpdateTime() async {
    final data = await _ref.doc('ALastUpdate').get();
    return data['lastUpdate'];
  }

  Future<void> updateLastUpdateTime(final int lastUpdate) async {
    await _ref.doc('ALastUpdate').update({'lastUpdate': lastUpdate});
  }
}
