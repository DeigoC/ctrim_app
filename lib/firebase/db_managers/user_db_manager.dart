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
}
