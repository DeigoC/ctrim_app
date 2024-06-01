import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrim_app/models/post_template.dart';

class PostTemplateDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance.collection('post_templates');

  static const String _templates = 'templates';

  Future<void> addPostTemplate(final String location, final PostTemplate template) async {
    await _ref.doc(location).collection(_templates).doc().set(template.toJson());
  }

  Future<List<PostTemplate>> fetchTemplatesForLocation(final String location) async {
    final collection = await _ref.doc(location).collection(_templates).get();
    return List<PostTemplate>.from(collection.docs.map((e) => e.data() as PostTemplate));
  }

  Future<void> updateTemplate(final String location, final PostTemplate template) async {
    await _ref.doc(location).collection(_templates).doc(template.id).update(template.toJson());
    // TODO also update the last update time for the location post
  }
}
