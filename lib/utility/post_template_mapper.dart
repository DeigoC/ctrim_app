import '../models/post_template.dart';
import 'event_context.dart';

class PostTemplateMapper {
  /// Converts a [PostTemplate] into a new [EventContext] ready for post creation.
  static EventContext mapTemplateToEventContext({
    required PostTemplate template,
    required String currentUserID,
    String? parentID,
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

    // head media pool - auto-select one random item if pool exists, otherwise use fixed headMedia
    if (template.headMediaPool.isNotEmpty) {
      final randomHeadMedia = template.getRandomHeadMediaPoolItem();
      if (randomHeadMedia != null) {
        eventContext.head.addMediaItem(
            type: randomHeadMedia['type']!,
            src: randomHeadMedia['src']!,
            title: randomHeadMedia['title'] ?? '',
            thumbnail: randomHeadMedia['thumbnailSrc'] ?? '');
      }
      eventContext.setTemplateHeadMediaPool(List<Map<String, dynamic>>.from(template.headMediaPool));
    } else {
      for (final headMediaItem in template.headMedia) {
        eventContext.head.addMediaItem(
            type: headMediaItem['type']!,
            src: headMediaItem['src']!,
            title: headMediaItem['title'] ?? '',
            thumbnail: headMediaItem['thumbnailSrc'] ?? '');
      }
    }

    // body media pool
    if (template.bodyMediaPool.isNotEmpty) {
      eventContext.setTemplateBodyMediaPool(List<Map<String, dynamic>>.from(template.bodyMediaPool));
    }

    // body and fixed media
    eventContext.setFetchedBody(template.body);
    if (template.media.isNotEmpty) {
      eventContext.media.addAllMediaFiles(template.media);
    }

    // meta related
    eventContext.metadata.addAllTopics(template.topics);
    eventContext.metadata.contributorUIDs.addAll(template.contributors);
    if (template.contributors.isNotEmpty) {
      eventContext.contributorAdditionUIDs.addAll(template.contributors);
    }

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
