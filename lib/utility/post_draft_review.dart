import '../models/event/event_program.dart';
import '../models/post_tag.dart';
import 'broadcast_audience.dart';
import 'event_context.dart';
import 'event_notification_copy.dart';

enum PostDraftReviewStatus { ready, suggestion, info }

/// Tab index on [AddEventPage]: Header, Info, Schedule, Media.
enum PostDraftReviewTab { header, info, schedule, media }

enum PostDraftReviewKind {
  title,
  subtitle,
  location,
  eventDate,
  scheduleRoles,
  coverImage,
  leadSpeaker,
  postTags,
  cellGroups,
  expectedAttendees,
  contributors,
  mediaGallery,
  broadcastNotify,
  scheduledNotify,
}

class PostDraftReviewItem {
  const PostDraftReviewItem({
    required this.kind,
    required this.status,
    required this.title,
    this.subtitle,
    this.tab,
  });

  final PostDraftReviewKind kind;
  final PostDraftReviewStatus status;
  final String title;
  final String? subtitle;

  /// When set, tapping the row can jump to this tab on the add-post screen.
  final PostDraftReviewTab? tab;

  bool get isTappable => tab != null;
}

class PostDraftReview {
  const PostDraftReview({required this.items});

  final List<PostDraftReviewItem> items;

  int get suggestionCount =>
      items.where((item) => item.status == PostDraftReviewStatus.suggestion).length;

  String get sheetSubtitle {
    if (suggestionCount == 0) {
      return 'All common fields look good — review and save when ready';
    }
    final noun = suggestionCount == 1 ? 'item' : 'items';
    return '$suggestionCount optional $noun not set';
  }
}

/// Builds an advisory checklist for the add-post save confirmation sheet.
PostDraftReview buildPostDraftReview({
  required EventContext eventContext,
  required String title,
  required String subtitle,
  required List<PostTag> allTags,
}) {
  final head = eventContext.head;
  final program = eventContext.program;
  final location = head.location;
  final topics = eventContext.metadata.topics;
  final includeUmbrella = BroadcastAudience.includesLocationUmbrella(
    topics: topics,
    locationName: location,
  );
  final broadcastAudience = BroadcastAudience.resolveFromPost(
    location: location,
    tagIDs: head.tagIDs,
    allTags: allTags,
    includeLocationUmbrella: includeUmbrella,
    legacyTopics: topics,
  );

  final items = <PostDraftReviewItem>[
    PostDraftReviewItem(
      kind: PostDraftReviewKind.title,
      status: PostDraftReviewStatus.ready,
      title: 'Title',
      subtitle: title,
      tab: PostDraftReviewTab.header,
    ),
    PostDraftReviewItem(
      kind: PostDraftReviewKind.subtitle,
      status: PostDraftReviewStatus.ready,
      title: 'Subtitle',
      subtitle: subtitle,
      tab: PostDraftReviewTab.header,
    ),
    PostDraftReviewItem(
      kind: PostDraftReviewKind.location,
      status: PostDraftReviewStatus.ready,
      title: 'Location',
      subtitle: location,
      tab: PostDraftReviewTab.schedule,
    ),
    _eventDateItem(head.eventDate, program),
    _scheduleRolesItem(program),
    _coverImageItem(head.getKeyGraphic()),
    _leadSpeakerItem(head.hasLeadSpeaker, head.leadSpeakerName),
    _postTagsItem(head.tagIDs.length),
    _cellGroupsItem(head.cellGroupIDs.length),
    _expectedAttendeesItem(eventContext.expectedAttendeeUserIDs.length),
    _contributorsItem(eventContext.metadata.contributorUIDs.length),
    _mediaGalleryItem(eventContext.media.allMedia.length),
    _broadcastNotifyItem(
      notifyBroadcast: eventContext.notifyBroadcast,
      audience: broadcastAudience,
    ),
    _scheduledNotifyItem(
      notifyScheduledMembers: eventContext.notifyScheduledMembers,
      program: program,
    ),
  ];

  return PostDraftReview(items: items);
}

PostDraftReviewItem _eventDateItem(DateTime? eventDate, EventProgram program) {
  if (eventDate == null) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.eventDate,
      status: PostDraftReviewStatus.suggestion,
      title: 'Event date',
      subtitle: 'No date set — tap to choose date and time',
      tab: PostDraftReviewTab.schedule,
    );
  }

  String subtitle;
  if (program.allDay) {
    subtitle = '${EventNotificationCopy.formatEventDate(eventDate)} (all day)';
  } else if (program.finishTime != null) {
    subtitle =
        '${EventNotificationCopy.formatEventDateTime(eventDate)} – ${EventNotificationCopy.formatEventTime(program.finishTime!)}';
  } else {
    subtitle = EventNotificationCopy.formatEventDateTime(eventDate);
  }

  return PostDraftReviewItem(
    kind: PostDraftReviewKind.eventDate,
    status: PostDraftReviewStatus.ready,
    title: 'Event date',
    subtitle: subtitle,
    tab: PostDraftReviewTab.schedule,
  );
}

PostDraftReviewItem _scheduleRolesItem(EventProgram program) {
  final roleCount = program.roles.length;
  if (roleCount == 0) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.scheduleRoles,
      status: PostDraftReviewStatus.suggestion,
      title: 'Schedule',
      subtitle: 'No schedule roles yet',
      tab: PostDraftReviewTab.schedule,
    );
  }

  final assignedCount = program.roles.where((role) {
    final uids = role['uids'];
    return uids is List && uids.isNotEmpty;
  }).length;

  if (assignedCount == 0) {
    return PostDraftReviewItem(
      kind: PostDraftReviewKind.scheduleRoles,
      status: PostDraftReviewStatus.suggestion,
      title: 'Schedule',
      subtitle: '$roleCount ${roleCount == 1 ? 'role' : 'roles'}, none assigned yet',
      tab: PostDraftReviewTab.schedule,
    );
  }

  return PostDraftReviewItem(
    kind: PostDraftReviewKind.scheduleRoles,
    status: PostDraftReviewStatus.ready,
    title: 'Schedule',
    subtitle: '$roleCount ${roleCount == 1 ? 'role' : 'roles'}, $assignedCount assigned',
    tab: PostDraftReviewTab.schedule,
  );
}

PostDraftReviewItem _coverImageItem(String? keyGraphic) {
  if (keyGraphic == null || keyGraphic.isEmpty) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.coverImage,
      status: PostDraftReviewStatus.suggestion,
      title: 'Cover image',
      subtitle: 'No key graphic set',
      tab: PostDraftReviewTab.header,
    );
  }

  return const PostDraftReviewItem(
    kind: PostDraftReviewKind.coverImage,
    status: PostDraftReviewStatus.ready,
    title: 'Cover image',
    subtitle: 'Key graphic set',
    tab: PostDraftReviewTab.header,
  );
}

PostDraftReviewItem _leadSpeakerItem(bool hasLeadSpeaker, String? name) {
  if (!hasLeadSpeaker) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.leadSpeaker,
      status: PostDraftReviewStatus.suggestion,
      title: 'Lead speaker',
      subtitle: 'Not set',
      tab: PostDraftReviewTab.header,
    );
  }

  return PostDraftReviewItem(
    kind: PostDraftReviewKind.leadSpeaker,
    status: PostDraftReviewStatus.ready,
    title: 'Lead speaker',
    subtitle: name?.trim().isNotEmpty == true ? name!.trim() : 'Set',
    tab: PostDraftReviewTab.header,
  );
}

PostDraftReviewItem _postTagsItem(int tagCount) {
  if (tagCount == 0) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.postTags,
      status: PostDraftReviewStatus.suggestion,
      title: 'Post tags',
      subtitle: 'None selected',
      tab: PostDraftReviewTab.header,
    );
  }

  return PostDraftReviewItem(
    kind: PostDraftReviewKind.postTags,
    status: PostDraftReviewStatus.ready,
    title: 'Post tags',
    subtitle: '$tagCount selected',
    tab: PostDraftReviewTab.header,
  );
}

PostDraftReviewItem _cellGroupsItem(int groupCount) {
  if (groupCount == 0) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.cellGroups,
      status: PostDraftReviewStatus.suggestion,
      title: 'Cell groups',
      subtitle: 'None linked',
      tab: PostDraftReviewTab.header,
    );
  }

  return PostDraftReviewItem(
    kind: PostDraftReviewKind.cellGroups,
    status: PostDraftReviewStatus.ready,
    title: 'Cell groups',
    subtitle: '$groupCount linked',
    tab: PostDraftReviewTab.header,
  );
}

PostDraftReviewItem _expectedAttendeesItem(int expectedCount) {
  if (expectedCount == 0) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.expectedAttendees,
      status: PostDraftReviewStatus.suggestion,
      title: 'Expected attendees',
      subtitle: 'None set',
      tab: PostDraftReviewTab.header,
    );
  }

  return PostDraftReviewItem(
    kind: PostDraftReviewKind.expectedAttendees,
    status: PostDraftReviewStatus.ready,
    title: 'Expected attendees',
    subtitle: '$expectedCount expected',
    tab: PostDraftReviewTab.header,
  );
}

PostDraftReviewItem _contributorsItem(int contributorCount) {
  if (contributorCount == 0) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.contributors,
      status: PostDraftReviewStatus.suggestion,
      title: 'Contributors',
      subtitle: 'Only you can edit this post',
      tab: PostDraftReviewTab.header,
    );
  }

  return PostDraftReviewItem(
    kind: PostDraftReviewKind.contributors,
    status: PostDraftReviewStatus.ready,
    title: 'Contributors',
    subtitle: '$contributorCount contributor${contributorCount == 1 ? '' : 's'}',
    tab: PostDraftReviewTab.header,
  );
}

PostDraftReviewItem _mediaGalleryItem(int mediaCount) {
  if (mediaCount == 0) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.mediaGallery,
      status: PostDraftReviewStatus.suggestion,
      title: 'Media gallery',
      subtitle: 'No photos or videos',
      tab: PostDraftReviewTab.media,
    );
  }

  return PostDraftReviewItem(
    kind: PostDraftReviewKind.mediaGallery,
    status: PostDraftReviewStatus.ready,
    title: 'Media gallery',
    subtitle: '$mediaCount ${mediaCount == 1 ? 'item' : 'items'}',
    tab: PostDraftReviewTab.media,
  );
}

PostDraftReviewItem _broadcastNotifyItem({
  required bool notifyBroadcast,
  required List<String> audience,
}) {
  if (!notifyBroadcast) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.broadcastNotify,
      status: PostDraftReviewStatus.ready,
      title: 'Broadcast notify',
      subtitle: 'Off — no push on save',
      tab: PostDraftReviewTab.header,
    );
  }

  if (audience.isEmpty) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.broadcastNotify,
      status: PostDraftReviewStatus.suggestion,
      title: 'Broadcast notify',
      subtitle: 'On, but no audience — add notifiable tags',
      tab: PostDraftReviewTab.header,
    );
  }

  return PostDraftReviewItem(
    kind: PostDraftReviewKind.broadcastNotify,
    status: PostDraftReviewStatus.info,
    title: 'Broadcast notify',
    subtitle: 'Will notify: ${BroadcastAudience.describe(audience)}',
    tab: PostDraftReviewTab.header,
  );
}

PostDraftReviewItem _scheduledNotifyItem({
  required bool notifyScheduledMembers,
  required EventProgram program,
}) {
  if (!notifyScheduledMembers) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.scheduledNotify,
      status: PostDraftReviewStatus.ready,
      title: 'Scheduled notify',
      subtitle: 'Off',
      tab: PostDraftReviewTab.header,
    );
  }

  final hasAssignees = program.roles.any((role) {
    final uids = role['uids'];
    return uids is List && uids.isNotEmpty;
  });

  if (!hasAssignees) {
    return const PostDraftReviewItem(
      kind: PostDraftReviewKind.scheduledNotify,
      status: PostDraftReviewStatus.suggestion,
      title: 'Scheduled notify',
      subtitle: 'On, but no one is assigned on the schedule',
      tab: PostDraftReviewTab.schedule,
    );
  }

  return const PostDraftReviewItem(
    kind: PostDraftReviewKind.scheduledNotify,
    status: PostDraftReviewStatus.info,
    title: 'Scheduled notify',
    subtitle: 'Will notify people assigned to schedule roles',
    tab: PostDraftReviewTab.schedule,
  );
}
