import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user.dart';

class UserDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance.collection('users').withConverter<User>(
      fromFirestore: (snap, _) => User.fromMap(snap.id, snap.data()!), toFirestore: (user, _) => user.toJson());
  static const String _supplemental = 'supplemental', _roles = 'roles', _posts = 'posts';

  Future<void> addUser(final User user) async {
    await _ref.doc(user.id).set(user);
    _ref.doc(user.id).collection(_supplemental).doc(_roles).set({_roles: []});
    _ref.doc(user.id).collection(_supplemental).doc(_posts).set({_posts: []});
  }

  Future<void> updateUser(final User user) async {
    await _ref.doc(user.id).update(user.toJson());
  }

  Future<List<User>> fetchAllUsers() async {
    final collection = await _ref.get();
    return List<User>.from(collection.docs.map((doc) => doc.data()).toList());
  }

  Future<User> fetchUserByID(final String id) async {
    return await _ref.doc(id).get().then((value) => value.data() as User);
  }

  Future<User?> fetchUserByAuthID(final String authID) async {
    final results = await _ref.where('AuthID', isEqualTo: authID).get();
    if (results.docs.isNotEmpty) {
      return results.docs.first.data() as User;
    }
    return null;
  }

  // * Suppplemental data
  // For the sake of further enhancement to these fields, they will remain as a list of maps

  // User roles (or tasks)
  // this tracks the posts that they have a specific role in as well as
  // the id (datetime) of the specific schedule item
  Future<List<Map<String, dynamic>>> fetchUserRoles(final String uid) async {
    final doc = await _ref.doc(uid).collection(_supplemental).doc(_roles).get();
    final roleData = List<Map<String, dynamic>>.from(doc.data()![_roles]);
    return roleData;
  }

  Future<void> addUserRole(
      {required String uid,
      required String postID,
      required int roleID,
      required int millisecondStart,
      required int millisecondEnd,
      required String title}) async {
    final data = await fetchUserRoles(uid);
    data.add({'postID': postID, 'id': roleID, 'startMil': millisecondStart, 'endMil': millisecondEnd, 'title': title});
    await _ref.doc(uid).collection(_supplemental).doc(_roles).update({_roles: data});
  }

  Future<void> removeUserRole(final String uid, final int roleID) async {
    final data = await fetchUserRoles(uid);
    data.removeWhere((e) => e['id'] as int == roleID);
    await _ref.doc(uid).collection(_supplemental).doc(_roles).update({_roles: data});
  }

  Future<void> removeUserPostRole(final String uid, final String postID) async {
    final data = await fetchUserRoles(uid);
    data.removeWhere((e) => e['postID'] == postID);
    await _ref.doc(uid).collection(_supplemental).doc(_roles).update({_roles: data});
  }

  // User posts
  // this tracks the posts the user is tied with as either
  // an author or contributor
  Future<List<Map<String, dynamic>>> fetchUserPosts(final String uid) async {
    final doc = await _ref.doc(uid).collection(_supplemental).doc(_posts).get();
    final postsData = List<Map<String, dynamic>>.from(doc.data()![_posts]);
    return postsData;
  }

  Future<void> addPostToUser(final String uid, final String postID, final String ownership) async {
    final data = await fetchUserPosts(uid);
    data.add({'id': postID, 'ownership': ownership});
    _ref.doc(uid).collection(_supplemental).doc(_posts).update({_posts: data});
  }

  Future<void> removePostFromUser(final String uid, final String postID) async {
    final data = await fetchUserPosts(uid);
    data.removeWhere((e) => e['id'] == postID);
    _ref.doc(uid).collection(_supplemental).doc(_posts).update({_posts: data});
  }

  Future<void> updatePosts(final User user) async {
    await _ref.doc(user.id).collection(_supplemental).doc(_posts).update({_posts: user.posts!});
  }
}
