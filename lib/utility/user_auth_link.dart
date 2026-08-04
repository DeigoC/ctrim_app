import '../firebase/db_managers/everyone_db_manager.dart';
import '../firebase/db_managers/user_db_manager.dart';
import '../firebase/functions_manager.dart';
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
///
/// Link/reassign goes through the `link_user_auth` callable so creators can link
/// their placeholders and `IsPlaceholder` is cleared server-side.
class UserAuthLinkService {
  UserAuthLinkService({
    UserDBManager? userDBManager,
    EveryoneDBManager? everyoneDBManager,
    CloudFunctionManager? cloudFunctionManager,
  })  : _userDBManager = userDBManager ?? UserDBManager(),
        _everyoneDBManager = everyoneDBManager ?? EveryoneDBManager(),
        _cloudFunctionManager = cloudFunctionManager ?? CloudFunctionManager();

  final UserDBManager _userDBManager;
  final EveryoneDBManager _everyoneDBManager;
  final CloudFunctionManager _cloudFunctionManager;

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

    if (user.authID == authID && !user.isPlaceholder) {
      await _everyoneDBManager.setAsUser(authID, isLeader: isLeader);
      return user;
    }

    final raw = await _cloudFunctionManager.linkUserAuth(
      userId: user.id,
      authId: authID,
      isLeader: isLeader,
    );
    return _userFromLinkResult(user, raw);
  }

  /// Clears Auth on [user] and clears `isUser` / `isLeader` on the previous `everyone` doc.
  ///
  /// Area-admin path (client rules). Re-marks the profile as a placeholder so it
  /// returns to the Auth-addressing queue.
  Future<User> unlinkAuth({required User user}) async {
    final oldAuthID = user.authID;
    if (oldAuthID.isEmpty) return user;

    final updated = copyUser(user, authID: '', isPlaceholder: true);
    await _userDBManager.updateUser(updated);
    await _everyoneDBManager.clearAsUser(oldAuthID);
    return updated;
  }

  User _userFromLinkResult(User previous, Map<String, dynamic> raw) {
    final id = (raw['Id'] as String?) ?? previous.id;
    final updated = User(
      id: id,
      forname: (raw['Forename'] as String?) ?? previous.forname,
      surname: (raw['Surname'] as String?) ?? previous.surname,
      imgSrc: (raw['ImgSrc'] as String?) ?? previous.imgSrc,
      location: (raw['Location'] as String?) ?? previous.location,
      isAreaAdmin: (raw['IsAreaAdmin'] as bool?) ?? previous.isAreaAdmin,
      isLeader: (raw['IsLeader'] as bool?) ?? previous.isLeader,
      authID: (raw['AuthID'] as String?) ?? '',
      tagIDs: _parseTags(raw['Tags']) ?? previous.tagIDs.toList(),
      createdByUserID: (raw['CreatedByUserID'] as String?) ?? previous.createdByUserID,
      isPlaceholder: (raw['IsPlaceholder'] as bool?) ?? false,
    );
    if (previous.roles != null) updated.setRoles(previous.roles!.toList());
    if (previous.posts != null) updated.setPosts(previous.posts!.toList());
    return updated;
  }

  static List<String>? _parseTags(dynamic raw) {
    if (raw is! List) return null;
    return raw.map((e) => e.toString()).toList();
  }
}

/// Copies [user] with optional field overrides (keeps roles/posts).
User copyUser(
  User user, {
  String? authID,
  bool? isPlaceholder,
  String? forename,
  String? surname,
  String? imgSrc,
  String? location,
  bool? isAreaAdmin,
  bool? isLeader,
  List<String>? tagIDs,
  String? createdByUserID,
}) {
  final copy = User(
    id: user.id,
    forname: forename ?? user.forname,
    surname: surname ?? user.surname,
    imgSrc: imgSrc ?? user.imgSrc,
    location: location ?? user.location,
    isAreaAdmin: isAreaAdmin ?? user.isAreaAdmin,
    isLeader: isLeader ?? user.isLeader,
    authID: authID ?? user.authID,
    tagIDs: tagIDs ?? user.tagIDs.toList(),
    createdByUserID: createdByUserID ?? user.createdByUserID,
    isPlaceholder: isPlaceholder ?? user.isPlaceholder,
  );
  if (user.roles != null) copy.setRoles(user.roles!.toList());
  if (user.posts != null) copy.setPosts(user.posts!.toList());
  return copy;
}
