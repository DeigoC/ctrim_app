import '../models/post_template.dart';
import '../models/post_tag.dart';
import '../models/user.dart';
import 'broadcast_audience.dart';
import 'event_context.dart';

class PostTemplateMapper {
  /// Converts a [PostTemplate] into a new [EventContext] ready for post creation.
  static EventContext mapTemplateToEventContext({
    required PostTemplate template,
    required String currentUserID,
    String? parentID,
    Iterable<User> allUsers = const [],
    List<PostTag> allPostTags = const [],
  }) {
    final EventContext eventContext = EventContext.adding(currentUserID: currentUserID, parentID: parentID);

    // head
    eventContext.head.setEventDate(template.startTime);
    eventContext.head.setLocation(template.location);
    eventContext.head.setTitle(template.title);

    // subtitle - auto-select random if available
    if (template.subtitles.isNotEmpty) {
      final randomSubtitle = template.getRandomSubtitle();
      if (randomSubtitle != null) {
        eventContext.head.setSubtitle(randomSubtitle);
      }
      eventContext.setTemplateSubtitles(List<String>.from(template.subtitles));
    }

    // Cover / key graphic: prefer body media pool (intended cover pool),
    // fall back to head media pool, else fixed headMedia.
    final coverPool = template.keyGraphicPool;
    if (coverPool.isNotEmpty) {
      final randomCover = template.getRandomKeyGraphicPoolItem();
      if (randomCover != null) {
        eventContext.head.addMediaItem(
            type: randomCover['type']!,
            src: randomCover['src']!,
            title: randomCover['title'] ?? '',
            thumbnail: randomCover['thumbnailSrc'] ?? '');
      }
      // Expose on the head-pool selector so cover can be changed while adding a post.
      eventContext.setTemplateHeadMediaPool(List<Map<String, dynamic>>.from(coverPool));
    } else {
      for (final headMediaItem in template.headMedia) {
        eventContext.head.addMediaItem(
            type: headMediaItem['type']!,
            src: headMediaItem['src']!,
            title: headMediaItem['title'] ?? '',
            thumbnail: headMediaItem['thumbnailSrc'] ?? '');
      }
    }

    // body and fixed media (fixed Media only — body pool is for covers, not gallery)
    eventContext.setFetchedBody(template.body);
    if (template.media.isNotEmpty) {
      eventContext.media.addAllMediaFiles(template.media);
    }

    // meta related
    eventContext.applyTagIDs(List<String>.from(template.tagIDs));
    eventContext.applyCellGroupIDs(List<String>.from(template.cellGroupIDs));
    eventContext.applyExpectedAttendeeUserIDs(
        List<String>.from(template.expectedAttendeeUserIDs));
    if (template.tagIDs.isEmpty && template.topics.isNotEmpty) {
      // Legacy templates: keep Topics as FCM audience until tags are assigned.
      eventContext.metadata.addAllTopics(template.topics);
    } else if (template.tagIDs.isNotEmpty && allPostTags.isNotEmpty) {
      final includeUmbrella = BroadcastAudience.includesLocationUmbrella(
        topics: template.topics,
        locationName: template.location,
      );
      eventContext.syncNotificationTopics(
        allTags: allPostTags,
        includeLocationUmbrella: includeUmbrella,
      );
    }
    eventContext.metadata.contributorUIDs.addAll(template.contributors);
    if (template.contributors.isNotEmpty) {
      eventContext.contributorAdditionUIDs.addAll(template.contributors);
    }
    if (template.leadSpeakerUID != null && template.leadSpeakerUID!.isNotEmpty) {
      eventContext.metadata.setLeadSpeakerUID(template.leadSpeakerUID);
      eventContext.syncLeadSpeakerHeadFromUsers(allUsers);
    }
    eventContext.applyIsPeriodParent(template.isPeriodParent);

    // program related
    int roleId = DateTime.now().millisecondsSinceEpoch;
    for (final role in template.roles) {
      final List<String> roleUids = List.from(role['uids']);
      eventContext.program.addRole(
          detail: role['detail'] ?? '',
          uids: roleUids,
          title: role['title'],
          start: role['start'],
          end: role['end'],
          id: roleId);

      if (roleUids.isNotEmpty) {
        eventContext.addRoleAdditionNotification(roleUids, roleId);
        roleId++;
      }
    }
    eventContext.program.setAddress(template.address);
    eventContext.program.setAllDay(template.allDay);
    eventContext.program.setMapLink(template.mapLink);
    eventContext.program.setOnline(template.online);
    eventContext.program.setFinishTime(template.finishTime);

    return eventContext;
  }

  /// Adjusts the event date and all schedule role times to [selectedDate],
  /// preserving the original hour and minute from the template's start time.
  static void adjustEventProgramToDate(EventContext eventContext, DateTime selectedDate) {
    final int hour = eventContext.head.eventDate?.hour ?? 0;
    final int minute = eventContext.head.eventDate?.minute ?? 0;

    eventContext.head.setEventDate(DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, minute));

    if (eventContext.program.finishTime != null) {
      final DateTime oldFinish = eventContext.program.finishTime!;
      eventContext.program.setFinishTime(
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day, oldFinish.hour, oldFinish.minute));
    }

    for (final scheduleItem in eventContext.program.roles) {
      if (scheduleItem['start'] != null) {
        final DateTime old = scheduleItem['start'] as DateTime;
        scheduleItem['start'] = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, old.hour, old.minute);
      }
      if (scheduleItem['end'] != null) {
        final DateTime old = scheduleItem['end'] as DateTime;
        scheduleItem['end'] = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, old.hour, old.minute);
      }
    }
  }
}
