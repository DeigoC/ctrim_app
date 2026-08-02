import '../firebase/db_managers/everyone_db_manager.dart';
import '../firebase/db_managers/user_db_manager.dart';
import '../models/user.dart';

/// Pure validation for linking a volunteer profile to an Auth / `everyone` identity.
String? validateAuthRelink({
  required String targetAuthID,
  required String currentUserId,
  required User? existingOwner,
}) {
  if (targetAuthID.trim().isEmpty) {
    return 'No account found for that email.';
  }
  if (existingOwner != null && existingOwner.id != currentUserId) {
    return 'That account is already linked to ${existingOwner.fullname}.';
  }
  return null;
}

/// Links / unlinks Firebase Auth (`everyone/{authID}`) on a volunteer `users` profile.
class UserAuthLinkService {
  UserAuthLinkService({
    UserDBManager? userDBManager,
    EveryoneDBManager? everyoneDBManager,
  })  : _userDBManager = userDBManager ?? UserDBManager(),
        _everyoneDBManager = everyoneDBManager ?? EveryoneDBManager();

  final UserDBManager _userDBManager;
  final EveryoneDBManager _everyoneDBManager;

  /// Points [user] at [newAuthID], sets `isUser` on the new identity, and clears the old one.
  Future<User> linkAuth({
    required User user,
    required String newAuthID,
    required bool isLeader,
  }) async {
    final authID = newAuthID.trim();
    final existingOwner = await _userDBManager.fetchUserByAuthID(authID);
    final error = validateAuthRelink(
      targetAuthID: authID,
      currentUserId: user.id,
      existingOwner: existingOwner,
    );
    if (error != null) {
      throw StateError(error);
    }

    final oldAuthID = user.authID;
    if (oldAuthID == authID) {
      await _everyoneDBManager.setAsUser(authID, isLeader);
      return user;
    }

    final updated = _copyUser(user, authID: authID);
    await _userDBManager.updateUser(updated);
    await _everyoneDBManager.setAsUser(authID, isLeader);
    if (oldAuthID.isNotEmpty) {
      await _everyoneDBManager.clearAsUser(oldAuthID);
    }
    return updated;
  }

  /// Clears Auth on [user] and clears `isUser` / `isLeader` on the previous `everyone` doc.
  Future<User> unlinkAuth({required User user}) async {
    final oldAuthID = user.authID;
    if (oldAuthID.isEmpty) return user;

    final updated = _copyUser(user, authID: '');
    await _userDBManager.updateUser(updated);
    await _everyoneDBManager.clearAsUser(oldAuthID);
    return updated;
  }

  User _copyUser(User user, {required String authID}) {
    final copy = User(
      id: user.id,
      forname: user.forname,
      surname: user.surname,
      imgSrc: user.imgSrc,
      location: user.location,
      isAreaAdmin: user.isAreaAdmin,
      isLeader: user.isLeader,
      authID: authID,
      tagIDs: user.tagIDs.toList(),
    );
    if (user.roles != null) copy.setRoles(user.roles!.toList());
    if (user.posts != null) copy.setPosts(user.posts!.toList());
    return copy;
  }
}
