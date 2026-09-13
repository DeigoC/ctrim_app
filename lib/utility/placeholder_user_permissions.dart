import '../models/user.dart';

/// Whether [user] may sign in with a linked Auth account.
bool canSignInWithVolunteerProfile(User user) => user.isProfileActive;

/// Whether [user] should appear in pickers for new assignments.
bool isSelectableVolunteerProfile(User user) => user.isProfileActive;

/// Whether [actor] may mint a placeholder `users` profile (CF create).
///
/// Leaders and above (incl. area admin), author of the post that opened the
/// picker, or a leader of the cell group that opened the picker.
bool canCreatePlaceholderUser({
  required User actor,
  String? postAuthorUid,
  bool isCellGroupLeader = false,
}) {
  if (actor.isLeader) return true;
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

/// Whether a permalink (`/people/:id`) may show [user] to [viewer].
///
/// In-app directory taps pass the [User] as router extra and skip this check.
/// Cold links use the unfiltered directory rule: active profiles, plus
/// viewer-visible placeholders and (for area admins) inactive profiles.
bool canOpenPersonPermalink({
  required User user,
  required User viewer,
}) {
  if (viewer.id == user.id && viewer.id.compareTo('0') != 0) {
    return true;
  }
  return isIncludedInUnfilteredPeopleSearch(user: user, viewer: viewer);
}

/// Whether [user] should appear in a name search that ignores refine filters
/// (location, serving, roles, tags, placeholders-only).
///
/// Includes active profiles at any location, viewer-visible placeholders, and
/// (for area admins) hidden/archived profiles — so organisers do not mint a
/// duplicate when someone is filtered out of the directory.
bool isIncludedInUnfilteredPeopleSearch({
  required User user,
  required User viewer,
}) {
  if (user.isPlaceholder) {
    if (viewer.isAreaAdmin) return true;
    return user.createdByUserID == viewer.id;
  }
  if (!user.isProfileActive) {
    return viewer.isAreaAdmin;
  }
  return true;
}
