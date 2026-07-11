import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_tag.dart';

class UserTagDBManager {
  static final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('user_tags').withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data() ?? {},
            toFirestore: (data, _) => data,
          );

  Future<List<UserTag>> fetchAllTags() async {
    final snapshot = await _ref.get();
    final tags = snapshot.docs.map((doc) => UserTag.fromMap(doc.id, doc.data())).toList();
    tags.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
    return tags;
  }

  Future<UserTag> createTag({
    required String name,
    String? color,
    required int displayOrder,
  }) async {
    final docRef = _ref.doc();
    final tag = UserTag(
      id: docRef.id,
      name: name,
      color: color,
      displayOrder: displayOrder,
    );
    await docRef.set(tag.toJson());
    return tag;
  }

  Future<void> updateTag(final UserTag tag) async {
    await _ref.doc(tag.id).update(tag.toJson());
  }

  Future<int> countUsersWithTag(final String tagId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('Tags', arrayContains: tagId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<void> deleteTag(final String tagId) async {
    await _ref.doc(tagId).delete();
  }
}
