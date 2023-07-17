import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrim_app/models/user_contact.dart';

class UserContactDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance
      .collection('user_contact')
      .withConverter<UserContact>(
          fromFirestore: (snap, _) => UserContact.fromMap(snap.id, snap.data()!),
          toFirestore: (record, _) => record.toJson());

  Future addUserContact(String id, UserContact contact) async {
    await _ref.doc(id).set(contact);
  }

  Future addTokenToUser(String id, String token) async {
    final details = await fetchUserContact(id);
    details.addToken(token);
    await updateUserContact(id, details);
  }

  Future removeTokenFromUser(String id, String token) async {
    final details = await fetchUserContact(id);
    details.removeToken(token);
    await updateUserContact(id, details);
  }

  Future updateUserContact(String id, UserContact contact) async {
    await _ref.doc(id).update(contact.toJson());
  }

  Future<UserContact> fetchUserContact(String id) async {
    return await _ref.doc(id).get().then((value) => value.data() as UserContact);
  }

  Future<UserContact?> fetchUserContactByAuthID(String authID) async {
    var query = await _ref.where('AuthID', isEqualTo: authID).get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.data() as UserContact;
  }

  Future<List<String>> fetchDeviceTokensOfAMember(String id) async {
    var details = await _ref.doc(id).get().then((value) => value.data() as UserContact);
    return details.deviceTokens;
  }
}
