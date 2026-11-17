import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/post_tag.dart';
import '../../utility/cache/directory_catalog_store.dart';

class PostTagDBManager {
  static final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance
          .collection('post_tags')
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data() ?? {},
            toFirestore: (data, _) => data,
          );

  Future<List<PostTag>> fetchAllTags() async {
    final snapshot = await _ref.get();
    final tags = snapshot.docs
        .map((doc) => PostTag.fromMap(doc.id, doc.data()))
        .toList();
    tags.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
    return tags;
  }

  Future<PostTag> createTag({
    required String name,
    String? color,
    String? streamKind,
    String? description,
    String? imageUrl,
    required int displayOrder,
  }) async {
    final docRef = _ref.doc();
    final tag = PostTag(
      id: docRef.id,
      name: name,
      color: color,
      streamKind: streamKind,
      description: description,
      imageUrl: imageUrl,
      displayOrder: displayOrder,
    );
    await docRef.set(tag.toJson());
    await DirectoryCatalogStore().upsertPostTag(tag);
    return tag;
  }

  Future<void> updateTag(final PostTag tag) async {
    await _ref.doc(tag.id).update(tag.toJson());
    await DirectoryCatalogStore().upsertPostTag(tag);
  }

  /// Counts event heads that reference [tagId] in `TagIDs`.
  Future<int> countPostsWithTag(final String tagId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('TagIDs', arrayContains: tagId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<void> deleteTag(final String tagId) async {
    await _ref.doc(tagId).delete();
    await DirectoryCatalogStore().deletePostTag(tagId);
  }
}
