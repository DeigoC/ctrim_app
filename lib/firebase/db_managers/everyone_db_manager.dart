import 'package:cloud_firestore/cloud_firestore.dart';

class EveryoneDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance.collection('everyone');
  static const String _supplemental = 'supplemental',
      _deviceTokens = 'device_tokens',
      _bookmarks = 'bookmarks',
      _auth = 'auth',
      _email = 'email';

  // Future<void> bookmarksWriteTest(List<String> data) async {
  //   // await _ref.doc('tVV1P736xr9EucuSWlXRudLDra9R').update({'bookmarks': content});
  //   await _ref
  //       .doc('dvEtvt8SrmdsZ7MnRrKWa1QQMRx8')
  //       .collection('supplemental')
  //       .doc('bookmarks')
  //       .update({'bookmarks': data});
  // }

  // Future<void> userWriteTest(bool content) async {
  //   // await _ref.doc('tVV1P736xr9EucuSWlXRudLDra9R').update({'isUser': content});
  //   await _ref.doc('dvEtvt8SrmdsZ7MnRrKWa1QQMRx8').update({'isUser': true});
  // }

  Future<void> createUser(final String authID, final String email) async {
    await _ref.doc(authID).set({_email: email});
    await _ref.doc(authID).collection(_supplemental).doc(_bookmarks).set({_bookmarks: [], _auth: authID});
    await _ref.doc(authID).collection(_supplemental).doc(_deviceTokens).set({_deviceTokens: {}, _auth: authID});
  }

  // ! token related

  Future<List<String>> fetchTokens(final String authID) async {
    final doc = await _ref.doc(authID).collection(_supplemental).doc(_deviceTokens).get();
    final deviceTokens = Map<String, String>.from(doc.data()![_deviceTokens]);
    return deviceTokens.keys.toList();
  }

  Future<void> addToken({required String authID, required String token, required String platform}) async {
    // check it doesn't exist, add it
    final doc = await _ref.doc(authID).collection(_supplemental).doc(_deviceTokens).get();
    final deviceTokens = Map<String, String>.from(doc.data()![_deviceTokens]);
    deviceTokens[token] = platform;
    await _ref.doc(authID).collection(_supplemental).doc(_deviceTokens).update({_deviceTokens: deviceTokens});
  }

  Future<void> removeToken(final String authID, final String token) async {
    final doc = await _ref.doc(authID).collection(_supplemental).doc(_deviceTokens).get();
    final deviceTokens = Map<String, String>.from(doc.data()![_deviceTokens]);
    deviceTokens.remove(token);
    await _ref.doc(authID).collection(_supplemental).doc(_deviceTokens).update({_deviceTokens: deviceTokens});
  }

  // ! bookmark related

  Future<List<String>> fetchBookmarks(final String authID) async {
    final doc = await _ref.doc(authID).collection(_supplemental).doc(_deviceTokens).get();
    return List<String>.from(doc.data()![_bookmarks]);
  }

  Future<void> updateBookmark(final String authID, final List<String> bookmarks) async {
    await _ref.doc(authID).collection(_supplemental).doc(_bookmarks).update({_bookmarks: bookmarks});
  }

  // ! user related

  Future<void> setAsUser(final String authID, final bool isLeader) async {
    final Map<String, dynamic> data = isLeader ? {'isLeader': true, 'isUser': true} : {'isUser': true};
    await _ref.doc(authID).update(data);
  }

  Future<String?> fetchAuthIDFromEmail(final String email) async {
    final q = await _ref.where(_email, isEqualTo: email).get();
    if (q.docs.isNotEmpty) {
      return q.docs.first.id;
    }
    return null;
  }
}
