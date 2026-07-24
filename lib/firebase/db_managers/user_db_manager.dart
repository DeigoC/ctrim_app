import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user.dart';
import '../../models/user_post_involvement.dart';
import '../../models/user_role_assignment.dart';

class UserDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance.collection('users').withConverter<User>(
      fromFirestore: (snap, _) => User.fromMap(snap.id, snap.data()!), toFirestore: (user, _) => user.toJson());
  static const String _supplemental = 'supplemental', _roles = 'roles', _posts = 'posts';

  Future<void> addUser(final User user) async {
    await _ref.doc(user.id).set(user);
    await _ref.doc(user.id).collection(_supplemental).doc(_roles).set({_roles: []});
    await _ref.doc(user.id).collection(_supplemental).doc(_posts).set({_posts: []});
  }

  Future<void> updateUser(final User user) async {
    await _ref.doc(user.id).update(user.toJson());
  }

  /// Self-serve profile photo update — only touches `ImgSrc`.
  Future<void> updateUserImgSrc(final String uid, final String imgSrc) async {
    await _ref.doc(uid).update({'ImgSrc': imgSrc});
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

  // User roles (or tasks)
  // this tracks the posts that they have a specific role in as well as
  // the id (datetime) of the specific schedule item
  Future<List<UserRoleAssignment>> fetchUserRoles(final String uid) async {
    final doc = await _ref.doc(uid).collection(_supplemental).doc(_roles).get();
    final roleData = List<dynamic>.from(doc.data()![_roles]);
    return UserRoleAssignment.listFromFirestore(roleData);
  }

  // Role/post tracking: program role rows are synced by Cloud Function
  // sync_user_roles_on_program_write; clients still prune stale rows locally.
  Future<void> addUserRole(
      {required String uid,
      required String postID,
      required int roleID,
      required int millisecondStart,
      required int millisecondEnd,
      required String title}) async {
    final data = await fetchUserRoles(uid);
    data.add(UserRoleAssignment(
      postID: postID,
      roleID: roleID,
      start: DateTime.fromMillisecondsSinceEpoch(millisecondStart),
      end: DateTime.fromMillisecondsSinceEpoch(millisecondEnd),
      title: title,
    ));
    await _ref.doc(uid).collection(_supplemental).doc(_roles).update({_roles: UserRoleAssignment.listToFirestore(data)});
  }

  Future<void> removeUserRole(final String uid, final int roleID) async {
    final data = await fetchUserRoles(uid);
    data.removeWhere((e) => e.roleID == roleID);
    await _ref.doc(uid).collection(_supplemental).doc(_roles).update({_roles: UserRoleAssignment.listToFirestore(data)});
  }

  Future<void> removeUserPostRole(final String uid, final String postID) async {
    final data = await fetchUserRoles(uid);
    data.removeWhere((e) => e.postID == postID);
    await _ref.doc(uid).collection(_supplemental).doc(_roles).update({_roles: UserRoleAssignment.listToFirestore(data)});
  }

  // User posts
  // this tracks the posts the user is tied with as either
  // an author or contributor
  Future<List<UserPostInvolvement>> fetchUserPosts(final String uid) async {
    final doc = await _ref.doc(uid).collection(_supplemental).doc(_posts).get();
    final postsData = List<dynamic>.from(doc.data()![_posts]);
    return UserPostInvolvement.listFromFirestore(postsData);
  }

  Future<void> addPostToUser(final String uid, final String postID, final String ownership) async {
    final data = await fetchUserPosts(uid);
    data.add(UserPostInvolvement(postID: postID, ownership: PostOwnership.fromString(ownership)));
    await _ref.doc(uid).collection(_supplemental).doc(_posts).update({_posts: UserPostInvolvement.listToFirestore(data)});
  }

  Future<void> removePostFromUser(final String uid, final String postID) async {
    final data = await fetchUserPosts(uid);
    data.removeWhere((e) => e.postID == postID);
    await _ref.doc(uid).collection(_supplemental).doc(_posts).update({_posts: UserPostInvolvement.listToFirestore(data)});
  }

  Future<void> updatePosts(final User user) async {
    await _ref
        .doc(user.id)
        .collection(_supplemental)
        .doc(_posts)
        .update({_posts: UserPostInvolvement.listToFirestore(user.posts!.toList())});
  }
}
