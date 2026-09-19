import '../models/post_template.dart';
import '../models/event/event_program.dart';
import '../models/user.dart';
import 'notifications/broadcast_audience.dart';
import 'event_context.dart';

class PostTemplateMapper {
  /// Converts a [PostTemplate] into a new [EventContext] ready for post creation.
  static EventContext mapTemplateToEventContext({
    required PostTemplate template,
    required String currentUserID,
    String? parentID,
    Iterable<User> allUsers = const [],
    SchedulePreset? schedulePreset,
    String? schedulePresetId,
  }) {
    final EventContext eventContext =
        EventContext.adding(currentUserID: currentUserID, parentID: parentID);

    // head
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
      eventContext
          .setTemplateHeadMediaPool(List<Map<String, dynamic>>.from(coverPool));
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
    eventContext.syncNotificationTopics(
      includeLocationUmbrella: BroadcastAudience.includesLocationUmbrella(
        topics: template.topics,
        locationName: template.location,
      ),
    );
    eventContext.metadata.contributorUIDs.addAll(template.contributors);
    if (template.contributors.isNotEmpty) {
      eventContext.contributorAdditionUIDs.addAll(template.contributors);
    }
    if (template.leadSpeakerUID != null &&
        template.leadSpeakerUID!.isNotEmpty) {
      eventContext.metadata.setLeadSpeakerUID(template.leadSpeakerUID);
      eventContext.syncLeadSpeakerHeadFromUsers(allUsers);
    }
    eventContext.applyIsPeriodParent(template.isPeriodParent);

    eventContext.program.setAddress(template.address);
    eventContext.program.setAllDay(template.allDay);
    eventContext.program.setMapLink(template.mapLink);
    eventContext.program.setOnline(template.online);

    applySchedulePreset(
      eventContext,
      resolveSchedulePreset(
        template,
        schedulePreset: schedulePreset,
        schedulePresetId: schedulePresetId,
      ),
    );

    return eventContext;
  }

  /// Picks an explicit preset, else the only/first preset, else null.
  static SchedulePreset? resolveSchedulePreset(
    PostTemplate template, {
    SchedulePreset? schedulePreset,
    String? schedulePresetId,
  }) {
    if (schedulePreset != null) return schedulePreset;
    if (schedulePresetId != null) {
      return template.presetById(schedulePresetId);
    }
    if (template.schedulePresets.isEmpty) return null;
    return template.schedulePresets.first;
  }

  /// Replaces the programme on [eventContext] with [preset].
  ///
  /// Venue, title, body, cover, expected attendees, and attendance are left
  /// alone. New role ids are always minted.
  ///
  /// When [eventDate] is set, start/finish and slot times are shifted onto that
  /// calendar day. When [applyEventWindow] is false (undated existing post),
  /// clock times are copied and [EventContext.head] keeps a null event date.
  /// Snapshots the live programme onto a named preset (keeps role ids).
  static SchedulePreset captureProgramAsPreset({
    required SchedulePreset existing,
    required EventContext eventContext,
  }) {
    return SchedulePreset(
      id: existing.id,
      name: existing.name,
      startTime: eventContext.head.eventDate,
      finishTime: eventContext.program.finishTime,
      roles: eventContext.program.roles,
    );
  }

  /// Loads a preset into the template editor without minting new role ids.
  static void loadSchedulePresetForEditing(
    EventContext eventContext,
    SchedulePreset preset,
  ) {
    applySchedulePreset(
      eventContext,
      preset,
      mintNewRoleIds: false,
      trackRoleDiff: false,
    );
  }

  static void applySchedulePreset(
    EventContext eventContext,
    SchedulePreset? preset, {
    DateTime? eventDate,
    bool trackRoleDiff = false,
    bool applyEventWindow = true,
    bool mintNewRoleIds = true,
  }) {
    if (trackRoleDiff) {
      eventContext.resetRoleDiffTracking();
      for (final role
          in List<Map<String, dynamic>>.from(eventContext.program.roles)) {
        final id = _roleId(role['id']);
        final uids = List<String>.from(role['uids'] ?? const []);
        if (uids.isNotEmpty) {
          eventContext.addRoleRemovalNotification(uids, id);
        }
        eventContext.addRoleDeletionTitle(id, (role['title'] as String?) ?? '');
      }
    }

    eventContext.program.clearRoles();

    if (preset == null) {
      if (eventDate != null) {
        adjustEventProgramToDate(eventContext, eventDate);
      }
      return;
    }

    if (applyEventWindow) {
      eventContext.head.setEventDate(preset.startTime);
      eventContext.program.setFinishTime(preset.finishTime);
    } else {
      eventContext.program.setFinishTime(preset.finishTime);
    }

    int nextRoleId = DateTime.now().millisecondsSinceEpoch;
    for (final role in preset.roles) {
      final List<String> roleUids = List.from(role['uids'] ?? const []);
      final int roleId = mintNewRoleIds ? nextRoleId++ : _roleId(role['id']);
      eventContext.program.addRole(
          detail: role['detail'] ?? '',
          uids: roleUids,
          title: role['title'] ?? '',
          start: role['start'] as DateTime?,
          end: role['end'] as DateTime?,
          forGuests:
              role['for_guests'] is bool ? role['for_guests'] as bool : true,
          tagIDs: EventProgram.tagIDsOf(role),
          id: roleId);

      if (roleUids.isNotEmpty) {
        eventContext.addRoleAdditionNotification(roleUids, roleId);
      }
    }

    if (eventDate != null && applyEventWindow) {
      adjustEventProgramToDate(eventContext, eventDate);
    }
  }

  /// Adjusts the event date and all schedule role times to [selectedDate],
  /// preserving the original hour and minute from the template's start time.
  static void adjustEventProgramToDate(
      EventContext eventContext, DateTime selectedDate) {
    final int hour = eventContext.head.eventDate?.hour ?? 0;
    final int minute = eventContext.head.eventDate?.minute ?? 0;

    eventContext.head.setEventDate(DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, hour, minute));

    if (eventContext.program.finishTime != null) {
      final DateTime oldFinish = eventContext.program.finishTime!;
      eventContext.program.setFinishTime(DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          oldFinish.hour,
          oldFinish.minute));
    }

    for (final scheduleItem in eventContext.program.roles) {
      if (scheduleItem['start'] != null) {
        final DateTime old = scheduleItem['start'] as DateTime;
        scheduleItem['start'] = DateTime(selectedDate.year, selectedDate.month,
            selectedDate.day, old.hour, old.minute);
      }
      if (scheduleItem['end'] != null) {
        final DateTime old = scheduleItem['end'] as DateTime;
        scheduleItem['end'] = DateTime(selectedDate.year, selectedDate.month,
            selectedDate.day, old.hour, old.minute);
      }
    }
  }

  static int _roleId(final Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }
}
