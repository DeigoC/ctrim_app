import '../models/user.dart';

/// Whether [user] may sign in with a linked Auth account.
bool canSignInWithVolunteerProfile(User user) => user.isProfileActive;

/// Whether [user] should appear in pickers for new assignments.
bool isSelectableVolunteerProfile(User user) => user.isProfileActive;

/// Whether [actor] may mint a placeholder `users` profile (CF create).
///
/// Medium gate: area admin, author of the post that opened the picker, or a
/// leader of the cell group that opened the picker (Phase 1).
bool canCreatePlaceholderUser({
  required User actor,
  String? postAuthorUid,
  bool isCellGroupLeader = false,
}) {
  if (actor.isAreaAdmin) return true;
  if (isCellGroupLeader) return true;
  if (postAuthorUid != null &&
      postAuthorUid.isNotEmpty &&
      postAuthorUid == actor.id) {
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
  return target.createdByUserID.isNotEmpty &&
      target.createdByUserID == actor.id;
}

/// Whether [actor] may unlink Auth from [target] (area admin only).
bool canUnlinkUserAuth({required User actor}) => actor.isAreaAdmin;

/// Picker-minted placeholders (have a creator). Used to decide whether a
/// non-admin should see the People directory "Placeholders" filter chip.
bool isTransientVolunteerPlaceholder(User user) {
  if (!user.isPlaceholder) return false;
  return user.createdByUserID.trim().isNotEmpty;
}

/// Whether [user] should appear in the People directory for [viewer]
/// given the placeholders filter.
///
/// Off: hide every `IsPlaceholder` profile (including legacy empty-Auth
/// backfill rows). On: placeholders only — area admins see all of them;
/// others only see ones they created.
bool isVisibleInVolunteerDirectory({
  required User user,
  required User viewer,
  required bool placeholdersOnly,
  bool showInactive = false,
}) {
  if (!placeholdersOnly) {
    if (!user.isProfileActive) {
      return showInactive && viewer.isAreaAdmin;
    }
    return !user.isPlaceholder;
  }

  if (!user.isPlaceholder) return false;
  if (viewer.isAreaAdmin) return true;
  return user.createdByUserID == viewer.id;
}
