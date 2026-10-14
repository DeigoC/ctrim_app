import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/shared_media_folders.dart';

/// The single `shared_media/folders` document.
///
/// Not loaded at startup. The gallery month tab and the area-admin editor
/// read it when they open.
class SharedMediaFoldersDBManager {
  static const String documentId = 'folders';

  static final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance
          .collection('shared_media')
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data() ?? {},
            toFirestore: (data, _) => data,
          );

  Future<SharedMediaFolders> fetch() async {
    final snap = await _ref.doc(documentId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return SharedMediaFolders.empty;
    return SharedMediaFolders.fromMap(data);
  }

  Future<void> save(SharedMediaFolders folders) async {
    await _ref.doc(documentId).set(folders.toJson());
  }
}
