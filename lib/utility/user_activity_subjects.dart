import '../models/user_activity_record.dart';
import 'user_activity_messages.dart';

/// What an activity row is about.
enum UserActivityKind {
  post,
  person,
  church,
  churchPage,
  testimonial,
  ctrimInfo,
  cellGroup,
  ministry,
  postTag,
  location,
  postTemplate,
  other,
}

/// Current display name for a record id, or null when it no longer exists
/// (or the viewer may not see it).
typedef ActivityTitleLookup = String? Function(String id);

/// Resolved title and destination for one [UserActivityRecord].
class UserActivitySubject {
  const UserActivitySubject({
    required this.kind,
    required this.id,
    required this.title,
    required this.canOpen,
    this.parentId = '',
  });

  final UserActivityKind kind;
  final String id;

  /// Empty when nothing safe to show is known.
  final String title;
  final bool canOpen;

  /// Church id for [UserActivityKind.churchPage].
  final String parentId;
}

class UserActivitySubjects {
  UserActivitySubjects._();

  static const Map<String, UserActivityKind> _kinds = {
    UserActivityMessages.createdBulletinPost: UserActivityKind.post,
    UserActivityMessages.editedBulletinPost: UserActivityKind.post,
    UserActivityMessages.updatedPostInterest: UserActivityKind.post,
    UserActivityMessages.updatedMinistrySchedule: UserActivityKind.post,
    UserActivityMessages.registeredVolunteer: UserActivityKind.person,
    UserActivityMessages.editedVolunteerProfile: UserActivityKind.person,
    UserActivityMessages.updatedProfilePhoto: UserActivityKind.person,
    UserActivityMessages.linkedVolunteerAccount: UserActivityKind.person,
    UserActivityMessages.unlinkedVolunteerAccount: UserActivityKind.person,
    UserActivityMessages.createdChurchRecord: UserActivityKind.church,
    UserActivityMessages.createdOutreachRecord: UserActivityKind.church,
    UserActivityMessages.editedChurchRecord: UserActivityKind.church,
    UserActivityMessages.deletedChurchRecord: UserActivityKind.church,
    UserActivityMessages.promotedOutreachToChurch: UserActivityKind.church,
    UserActivityMessages.demotedChurchToOutreach: UserActivityKind.church,
    UserActivityMessages.createdChurchPage: UserActivityKind.churchPage,
    UserActivityMessages.editedChurchPage: UserActivityKind.churchPage,
    UserActivityMessages.deletedChurchPage: UserActivityKind.churchPage,
    UserActivityMessages.createdTestimonial: UserActivityKind.testimonial,
    UserActivityMessages.editedTestimonial: UserActivityKind.testimonial,
    UserActivityMessages.deletedTestimonial: UserActivityKind.testimonial,
    UserActivityMessages.createdCtrimInfo: UserActivityKind.ctrimInfo,
    UserActivityMessages.editedCtrimInfo: UserActivityKind.ctrimInfo,
    UserActivityMessages.deletedCtrimInfo: UserActivityKind.ctrimInfo,
    UserActivityMessages.createdCellGroup: UserActivityKind.cellGroup,
    UserActivityMessages.editedCellGroup: UserActivityKind.cellGroup,
    UserActivityMessages.updatedCellMembers: UserActivityKind.cellGroup,
    UserActivityMessages.createdUserTag: UserActivityKind.ministry,
    UserActivityMessages.editedUserTag: UserActivityKind.ministry,
    UserActivityMessages.deletedUserTag: UserActivityKind.ministry,
    UserActivityMessages.createdPostTag: UserActivityKind.postTag,
    UserActivityMessages.editedPostTag: UserActivityKind.postTag,
    UserActivityMessages.deletedPostTag: UserActivityKind.postTag,
    UserActivityMessages.createdLocation: UserActivityKind.location,
    UserActivityMessages.editedLocation: UserActivityKind.location,
    UserActivityMessages.deletedLocation: UserActivityKind.location,
    UserActivityMessages.createdPostTemplate: UserActivityKind.postTemplate,
    UserActivityMessages.editedPostTemplate: UserActivityKind.postTemplate,
  };

  static const Set<String> _deletions = {
    UserActivityMessages.deletedChurchRecord,
    UserActivityMessages.deletedChurchPage,
    UserActivityMessages.deletedTestimonial,
    UserActivityMessages.deletedCtrimInfo,
    UserActivityMessages.deletedUserTag,
    UserActivityMessages.deletedPostTag,
    UserActivityMessages.deletedLocation,
  };

  /// Kinds with a page the activity list can open.
  static const Set<UserActivityKind> _openable = {
    UserActivityKind.post,
    UserActivityKind.person,
    UserActivityKind.church,
    UserActivityKind.churchPage,
    UserActivityKind.testimonial,
    UserActivityKind.ctrimInfo,
    UserActivityKind.cellGroup,
    UserActivityKind.ministry,
    UserActivityKind.postTag,
  };

  /// Kinds whose stored title is already public. Names of people, post tags,
  /// and templates are only shown to guests through a live, guest-aware lookup.
  static const Set<UserActivityKind> _guestSafeStoredTitle = {
    UserActivityKind.post,
    UserActivityKind.church,
    UserActivityKind.churchPage,
    UserActivityKind.testimonial,
    UserActivityKind.ctrimInfo,
    UserActivityKind.cellGroup,
    UserActivityKind.location,
  };

  static const Set<UserActivityKind> _signedInOnlyDestination = {
    UserActivityKind.postTag,
  };

  static UserActivityKind kindOf(final String log) =>
      _kinds[log] ?? UserActivityKind.other;

  static bool isDeletion(final String log) => _deletions.contains(log);

  /// Post ids among [records], for fetching heads the session does not hold.
  static Set<String> postIds(final Iterable<UserActivityRecord> records) {
    return {
      for (final record in records)
        if (kindOf(record.log) == UserActivityKind.post &&
            record.documentId.isNotEmpty)
          record.documentId,
    };
  }

  static bool includesKind(
    final Iterable<UserActivityRecord> records,
    final UserActivityKind kind,
  ) {
    return records.any((record) => kindOf(record.log) == kind);
  }

  /// A live name from [lookups] wins over the stored title (renames show the
  /// current name). A kind with a lookup that returns null no longer exists,
  /// so it cannot be opened. A kind without a lookup is assumed to exist.
  static UserActivitySubject resolve(
    final UserActivityRecord record, {
    final Map<UserActivityKind, ActivityTitleLookup> lookups = const {},
    final bool guest = false,
  }) {
    final kind = kindOf(record.log);
    final id = record.documentId;
    final lookup = lookups[kind];
    final live = (lookup == null || id.isEmpty) ? null : lookup(id);
    final liveTitle = live?.trim() ?? '';

    var title = liveTitle;
    if (title.isEmpty && (!guest || _guestSafeStoredTitle.contains(kind))) {
      title = record.title;
    }

    var canOpen = id.isNotEmpty &&
        _openable.contains(kind) &&
        !isDeletion(record.log) &&
        (lookup == null || live != null) &&
        !(guest && _signedInOnlyDestination.contains(kind));
    if (kind == UserActivityKind.churchPage && record.parentId.isEmpty) {
      canOpen = false;
    }
    if (guest && kind == UserActivityKind.person && live == null) {
      canOpen = false;
    }

    return UserActivitySubject(
      kind: kind,
      id: id,
      title: title,
      canOpen: canOpen,
      parentId: record.parentId,
    );
  }
}
