import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_location.dart';

class UserLocationDBManager {
  static final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('user_locations').withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data() ?? {},
            toFirestore: (data, _) => data,
          );

  Future<List<UserLocation>> fetchAllLocations() async {
    final snapshot = await _ref.get();
    final locations = snapshot.docs.map((doc) => UserLocation.fromMap(doc.id, doc.data())).toList();
    locations.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
    return locations;
  }

  Future<UserLocation> createLocation({
    required String name,
    required int displayOrder,
  }) async {
    final docRef = _ref.doc();
    final location = UserLocation(
      id: docRef.id,
      name: name,
      displayOrder: displayOrder,
    );
    await docRef.set(location.toJson());
    return location;
  }

  Future<void> updateLocation(final UserLocation location) async {
    await _ref.doc(location.id).update(location.toJson());
  }

  /// Renames a location definition and rewrites matching `users.Location` values.
  Future<void> renameLocation({
    required UserLocation location,
    required String newName,
  }) async {
    final oldName = location.name;
    if (oldName == newName) {
      await updateLocation(location);
      return;
    }

    location.setName(newName);
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_ref.doc(location.id), location.toJson());

    final users = await FirebaseFirestore.instance
        .collection('users')
        .where('Location', isEqualTo: oldName)
        .get();
    for (final doc in users.docs) {
      batch.update(doc.reference, {'Location': newName});
    }
    await batch.commit();
  }

  Future<int> countUsersWithLocation(final String locationName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('Location', isEqualTo: locationName)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<void> deleteLocation(final String locationId) async {
    await _ref.doc(locationId).delete();
  }
}
