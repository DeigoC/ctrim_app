import '../models/user.dart';

/// Whether [actor] may mint a placeholder `users` profile (CF create).
///
/// Medium gate (Phase 0.75): area admin, or author of the post that opened the
/// picker. CG-leader ownership becomes meaningful once Cell Groups Phase 1 ships.
bool canCreatePlaceholderUser({
  required User actor,
  String? postAuthorUid,
}) {
  if (actor.isAreaAdmin) return true;
  if (postAuthorUid != null && postAuthorUid.isNotEmpty && postAuthorUid == actor.id) {
    return true;
  }
  return false;
}

/// Whether [actor] may edit name (and similar safe fields) on [target].
bool canEditPlaceholderProfile({
  required User actor,
  required User target,
}) {
  if (actor.isAreaAdmin) return true;
  return target.isPlaceholder &&
      target.createdByUserID.isNotEmpty &&
      target.createdByUserID == actor.id;
}

/// Whether [actor] may Link / Reassign Auth on [target].
///
/// While still a placeholder (unlinked): creator or area admin.
/// After a successful link (`IsPlaceholder` false / Auth set): area admin only.
bool canLinkPlaceholderAuth({
  required User actor,
  required User target,
}) {
  if (actor.isAreaAdmin) return true;
  if (!target.isPlaceholder) return false;
  if (target.authID.isNotEmpty) return false;
  return target.createdByUserID.isNotEmpty && target.createdByUserID == actor.id;
}

/// Whether [actor] may unlink Auth from [target] (area admin only).
bool canUnlinkUserAuth({required User actor}) => actor.isAreaAdmin;
