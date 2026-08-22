import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/info/church_info.dart';
import '../../models/info/church_page.dart';
import '../../models/info/ctrim_info.dart';
import '../../models/info/testimonial_info.dart';

typedef InfoFactory<T> = T Function(String id, Map<String, dynamic> data);
typedef InfoSerializer<T> = Map<String, dynamic> Function(T model);

class InfoCollectionDBManager<T> {
  InfoCollectionDBManager(
      {required String sectionKey,
      required InfoFactory<T> fromMap,
      required InfoSerializer<T> toJson})
      : _sectionKey = sectionKey,
        _rootRef = FirebaseFirestore.instance.collection('information'),
        _itemsRef = FirebaseFirestore.instance
            .collection('information')
            .doc(sectionKey)
            .collection('items')
            .withConverter<T>(
                fromFirestore: (snap, _) => fromMap(snap.id, snap.data()!),
                toFirestore: (item, _) => toJson(item));

  final String _sectionKey;
  final CollectionReference<Map<String, dynamic>> _rootRef;
  final CollectionReference<T> _itemsRef;

  Future<List<T>> fetchAll() async {
    final collection = await _itemsRef.get();
    return List<T>.from(collection.docs.map((doc) => doc.data()));
  }

  Future<T?> fetchById(final String id) async {
    final doc = await _itemsRef.doc(id).get();
    return doc.data();
  }

  Future<void> save(final String id, final T model) async {
    // Merge so nested watermarks (e.g. church pagesLastUpdate) are not wiped.
    await _itemsRef.doc(id).set(model, SetOptions(merge: true));
    await updateLastUpdate(DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> delete(final String id) async {
    await _itemsRef.doc(id).delete();
    await updateLastUpdate(DateTime.now().millisecondsSinceEpoch);
  }

  Future<int> fetchLastUpdate() async {
    final doc = await _rootRef.doc(_sectionKey).get();
    final data = doc.data();
    if (data == null) {
      return 0;
    }

    final dynamic rawValue = data['lastUpdate'];
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is Timestamp) {
      return rawValue.toDate().millisecondsSinceEpoch;
    }
    return 0;
  }

  Future<void> updateLastUpdate(final int lastUpdate) async {
    await _rootRef
        .doc(_sectionKey)
        .set({'lastUpdate': lastUpdate}, SetOptions(merge: true));
  }
}

class ChurchInfoDBManager extends InfoCollectionDBManager<ChurchInfo> {
  ChurchInfoDBManager()
      : super(
            sectionKey: 'churches',
            fromMap: ChurchInfo.fromMap,
            toJson: (info) => info.toJson());
}

class TestimonialInfoDBManager
    extends InfoCollectionDBManager<TestimonialInfo> {
  TestimonialInfoDBManager()
      : super(
            sectionKey: 'testimonials',
            fromMap: TestimonialInfo.fromMap,
            toJson: (info) => info.toJson());
}

class CtrimInfoDBManager extends InfoCollectionDBManager<CtrimInfo> {
  CtrimInfoDBManager()
      : super(
            sectionKey: 'ctrim_info',
            fromMap: CtrimInfo.fromMap,
            toJson: (info) => info.toJson());
}

/// Nested pages under `information/churches/items/{churchId}/pages/{pageId}`.
class ChurchPageDBManager {
  static const lastUpdateField = 'pagesLastUpdate';

  CollectionReference<ChurchPage> _pagesRef(final String churchId) {
    return FirebaseFirestore.instance
        .collection('information')
        .doc('churches')
        .collection('items')
        .doc(churchId)
        .collection('pages')
        .withConverter<ChurchPage>(
          fromFirestore: (snap, _) =>
              ChurchPage.fromMap(snap.id, churchId, snap.data()!),
          toFirestore: (page, _) => page.toJson(),
        );
  }

  DocumentReference<Map<String, dynamic>> _churchItemRef(
      final String churchId) {
    return FirebaseFirestore.instance
        .collection('information')
        .doc('churches')
        .collection('items')
        .doc(churchId);
  }

  Future<List<ChurchPage>> fetchAll(final String churchId) async {
    final collection = await _pagesRef(churchId).get();
    return List<ChurchPage>.from(collection.docs.map((doc) => doc.data()));
  }

  Future<ChurchPage?> fetchById(final String churchId, final String id) async {
    final doc = await _pagesRef(churchId).doc(id).get();
    return doc.data();
  }

  Future<void> save(
      final String churchId, final String id, final ChurchPage model) async {
    await _pagesRef(churchId).doc(id).set(model);
    await updateLastUpdate(churchId, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> delete(final String churchId, final String id) async {
    await _pagesRef(churchId).doc(id).delete();
    await updateLastUpdate(churchId, DateTime.now().millisecondsSinceEpoch);
  }

  /// Deletes nested pages without bumping the church watermark (church is going away).
  Future<void> deleteAll(final String churchId) async {
    final pages = await fetchAll(churchId);
    for (final page in pages) {
      await _pagesRef(churchId).doc(page.id).delete();
    }
  }

  Future<int> fetchLastUpdate(final String churchId) async {
    final doc = await _churchItemRef(churchId).get();
    final data = doc.data();
    if (data == null) {
      return 0;
    }

    final dynamic rawValue = data[lastUpdateField];
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is Timestamp) {
      return rawValue.toDate().millisecondsSinceEpoch;
    }
    return 0;
  }

  Future<void> updateLastUpdate(
      final String churchId, final int lastUpdate) async {
    await _churchItemRef(churchId).set(
      {lastUpdateField: lastUpdate},
      SetOptions(merge: true),
    );
  }
}
