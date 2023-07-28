import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrim_app/models/user_contact.dart';

class UserContactDBManager {
  static final CollectionReference _ref = FirebaseFirestore.instance
      .collection('user_contacts')
      .withConverter<UserContact>(
          fromFirestore: (snap, _) => UserContact.fromMap(snap.id, snap.data()!),
          toFirestore: (record, _) => record.toJson());

  Future addUserContact(final String id, final UserContact contact) async {
    await _ref.doc(id).set(contact);
  }

  Future addTokenToUser(final String id, final String token) async {
    final details = await fetchUserContact(id);
    details.addToken(token);
    await updateUserContact(id, details);
  }

  Future removeTokenFromUser(final String id, final String token) async {
    final details = await fetchUserContact(id);
    details.removeToken(token);
    await updateUserContact(id, details);
  }

  Future updateUserContact(final String id, final UserContact contact) async {
    await _ref.doc(id).update(contact.toJson());
  }

  Future<UserContact> fetchUserContact(final String id) async {
    return await _ref.doc(id).get().then((value) => value.data() as UserContact);
  }

  Future<List<UserContact>> fetchUserContacts(final List<String> ids) async {
    final List<UserContact> results = List<UserContact>.empty(growable: true);
    for (final String id in ids) {
      results.add(await fetchUserContact(id));
    }
    return results;
  }

  Future<UserContact> fetchUserContactByAuthID(String authID) async {
    var query = await _ref.where('AuthID', isEqualTo: authID).get();
    return query.docs.first.data() as UserContact;
  }
}
