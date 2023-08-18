import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user.dart';

class UserDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance.collection('users').withConverter<User>(
      fromFirestore: (snap, _) => User.fromMap(snap.id, snap.data()!), toFirestore: (user, _) => user.toJson());

  Future addUser(User user) async {
    await _ref.doc(user.id).set(user);
  }

  Future updateUser(User user) async {
    await _ref.doc(user.id).update(user.toJson());
  }

  Future<List<User>> fetchAllUsers() async {
    var collection = await _ref.get();
    return List<User>.from(collection.docs.map((doc) => doc.data()).toList());
  }

  Future<User> fetchUserByID(String id) async {
    return await _ref.doc(id).get().then((value) => value.data() as User);
  }

  Future<User?> fetchUserByAuthID(String authID) async {
    final results = await _ref.where('AuthID', isEqualTo: authID).get();
    if (results.docs.isNotEmpty) {
      return results.docs.first.data() as User;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchUserRoles(String uid) async {
    final doc = await _ref.doc(uid).collection('supplemental').doc('roles').get();
    final roleData = List<Map<String, dynamic>>.from(doc.data()!['roles']);
    final List<Map<String, dynamic>> result = [];
    for (final dataEntry in roleData) {
      result.add({'postID': dataEntry['postID'], 'id': dataEntry['id']});
    }

    return result;
  }

  Future<void> updateRoles(final String uid, final List<Map<String, dynamic>> content) async {
    await _ref.doc(uid).collection('supplemental').doc('roles').update({'roles': content});
  }
}
