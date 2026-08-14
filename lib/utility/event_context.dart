import 'dart:collection';

import '../firebase/db_managers/cell_group_db_manager.dart';
import '../firebase/db_managers/event_db_manager.dart';
import '../firebase/db_managers/id_tracker.dart';
import '../models/event/event_attendance.dart';
import '../models/event/event_body.dart';
import '../models/event/event_head.dart';
import '../models/event/event_log.dart';
import '../models/event/event_media.dart';
import '../models/event/event_metadata.dart';
import '../models/event/event_program.dart';
import '../models/post_tag.dart';
import '../models/user.dart';
import 'broadcast_audience.dart';
import 'parent_link.dart';
import 'user_activity_messages.dart';
import 'user_activity_recorder.dart';

class EventContext {
  late final EventHead _head;
  late final EventLog _log; // ? doesn't have to be late
  late final EventMetadata _metadata;
  late final EventProgram _program;
  late final EventMedia _media; // ? doesn't have to be late
  late final String _currentUID;
  final EventBody _body = EventBody();
  EventAttendance? _attendance;
  bool _attendanceDirty = false;

  bool _canSaveTheEditing = false,
      _notifyBroadcast = false,
      _notifyScheduledMembers = false;

  /// Parent id as loaded / last saved — used to sync [ChildrenIDs] on save.
  String? _baselineParentID;

  /// Result of the last [updatePost] parent-link sync (for AppContext cache).
  Map<String, EventMetadata> _lastParentLinkSync = const {};

  // id (datetime milliseconds) to uids
  late final Map<int, List<String>> _roleAdditions, _roleRemovals;
  late final Map<int, String> _deletedRoleTitle;
  late final List<String> _contributorAdditionUIDs, _contributorRemovalUIDs;

  // template subtitles list (for posts created from templates)
  List<String>? _templateSubtitles;

  /// Draft expected attendees for create / template edit (written to attendance on publish).
  final List<String> _expectedAttendeeUserIDs = <String>[];

  // for viewing and editing
  EventContext.viewing(
      {required final EventHead eventHead,
      required final String currentUID,
      final List<String>? data}) {
    _head = eventHead;
    _canSaveTheEditing = false;
    _currentUID = currentUID;
    if (data != null) {
      _setWholePostFromTxt(data);
      _initialiseInternalLists();
    }
  }

  EventContext.adding(
      {required final String currentUserID,
      final String? parentID,
      final String? id}) {
    _metadata = EventMetadata(authorUID: currentUserID, parentID: parentID);
    _baselineParentID = parentID;
    _program = EventProgram();
    _media = EventMedia();
    _head = EventHead(id: id ?? 'x'); // temporary
    _currentUID = currentUserID;
    _initialiseInternalLists();
  }

  // * Head Related
  EventHead get head => _head;
  bool get notifyBroadcast => _notifyBroadcast;
  bool get notifyScheduledMembers => _notifyScheduledMembers;
  void setNotifyBroadcast(final bool newState) => _notifyBroadcast = newState;
  void setNotifyScheduledMembers(final bool newState) =>
      _notifyScheduledMembers = newState;

  // * Body Related
  bool get isBodyUntouched =>
      _body.json.compareTo(r'[{"insert":"Hello, time to start writing!\n"}]') ==
      0;
  List<dynamic> get body => _body.decodedJson;
  String get encodedBody => _body.json;
  bool isSameJson(final List<dynamic> json) => _body.compareTo(json) == 0;

  void setBodyJson(final List<dynamic> json) => _body.encodeJson(json);
  void setFetchedBody(final String encodedBody) => _body.setJson(encodedBody);

  // * Program Related (and the Event Date)
  EventProgram get program => _program;

  void setFetchedProgram(final EventProgram program) => _program = program;

  // * Supplemental - Metadata Related
  EventMetadata get metadata => _metadata;
  void setFetchedMetadata(final EventMetadata data) {
    _metadata = data;
    _baselineParentID = data.parentID;
    // Prefer metadata TagIDs; fall back to head if metadata predates the field.
    if (data.tagIDs.isNotEmpty) {
      _head.setTagIDs(data.tagIDs);
    } else if (_head.tagIDs.isNotEmpty) {
      _metadata.setTagIDs(_head.tagIDs);
    }
    // Prefer metadata CellGroupIDs; fall back to head denorm.
    if (data.cellGroupIDs.isNotEmpty) {
      _head.setCellGroupIDs(data.cellGroupIDs);
    } else if (_head.cellGroupIDs.isNotEmpty) {
      _metadata.setCellGroupIDs(_head.cellGroupIDs);
    }
    // Keep head denorm in sync with metadata period-parent flag.
    _head.setIsPeriodParent(data.isPeriodParent);
    _initialiseInternalLists();
  }

  /// Parent ids whose [ChildrenIDs] were rewritten on the last [updatePost].
  Map<String, EventMetadata> get lastParentLinkSync => _lastParentLinkSync;

  // * Supplemental - Media Related
  EventMedia get media => _media;
  void setFetchedMedia(final EventMedia media) => _media = media;

  // * Logs Related
  EventLog get log => _log;
  void setFetchedLogs(final EventLog log) => _log = log;

  // * Attendance Related (private supplemental; null until fetched / signed-in load)
  EventAttendance? get attendance => _attendance;
  bool get hasLoadedAttendance => _attendance != null;
  bool get isAttendanceDirty => _attendanceDirty;

  /// Applies a server attendance snapshot.
  ///
  /// When [forceReplace] is false and staff lists are dirty (unsaved local edits),
  /// only [interested] is taken from the server so self-serve interest toggles do
  /// not wipe pending attendee/expected changes.
  void setFetchedAttendance(final EventAttendance attendance,
      {bool forceReplace = false}) {
    if (!forceReplace && _attendanceDirty && _attendance != null) {
      _attendance = EventAttendance.fromMap({
        'interested': {
          for (final e in attendance.interested.entries)
            e.key: e.value.toJson(),
        },
        'attendees': _attendance!.attendees.map((e) => e.toJson()).toList(),
        'expectedUserIds': List<String>.from(_attendance!.expectedUserIds),
      });
    } else {
      _attendance = attendance;
      if (forceReplace) {
        _attendanceDirty = false;
      }
    }
    _head.setInterestedCount(_attendance!.interestedCount);
    _head.setAttendeeCount(_attendance!.attendeeCount);
  }

  /// Local staff edit to attendees / expected checklist; enables post Save.
  void applyStaffAttendanceEdit(final EventAttendance attendance) {
    _attendance = attendance;
    _head.setInterestedCount(attendance.interestedCount);
    _head.setAttendeeCount(attendance.attendeeCount);
    _attendanceDirty = true;
    _canSaveTheEditing = true;
  }

  // * General logic

  Future<String> addNewPost({
    required String title,
    required String subtitle,
    required String uid,
    required String location,
    DateTime? eventDate,
  }) async {
    final IDTrackerDBManager idTrackerDBManager = IDTrackerDBManager();
    final String newID = await idTrackerDBManager.getAndIncrementEventID();

    final EventSupplementalDBManager dbManager =
        EventSupplementalDBManager(newID);
    final EventHeadDBManager headDBManager = EventHeadDBManager();
    final DateTime now = DateTime.now();

    // head stuff
    final headToUpload = EventHead(id: newID);
    headToUpload.setTitle(title);
    headToUpload.setSubtitle(subtitle);
    headToUpload.setRecentDate(now);
    headToUpload.setEventDate(_head.eventDate);
    headToUpload.setLocation(location);
    headToUpload.setTagIDs(_head.tagIDs);
    headToUpload.setCellGroupIDs(_head.cellGroupIDs);
    headToUpload.setIsPeriodParent(_metadata.isPeriodParent);
    if (_head.hasLeadSpeaker) {
      headToUpload.setLeadSpeaker(
        uid: _head.leadSpeakerUID,
        imgSrc: _head.leadSpeakerImgSrc,
        name: _head.leadSpeakerName,
      );
    }
    for (final mediaEntry in _head.media) {
      headToUpload.addMediaItem(
          src: mediaEntry['src']!,
          type: mediaEntry['type']!,
          title: mediaEntry['title']!);
    }

    // metadata
    _metadata.setLastUID(uid);
    _head.setIsPeriodParent(_metadata.isPeriodParent);

    // log, create the new one for creation
    _log = EventLog({'uid': uid, 'log': 'Publication', 'ts': now});

    await headDBManager.saveNewHead(headToUpload);
    await dbManager.addBody(_body.json);
    await dbManager.addMedia(_media);
    await dbManager.addMetadata(_metadata);
    await dbManager.setLog(_log);
    await dbManager.addProgram(_program);
    final expectedIds = await resolveExpectedUserIdsForNewPost();
    await dbManager
        .setAttendance(EventAttendance(expectedUserIds: expectedIds));
    await UserActivityRecorder().record(
      actorUserId: uid,
      log: UserActivityMessages.createdBulletinPost,
      documentId: newID,
    );
    return newID;
  }

  Future<void> updatePost({required String log, required String uid}) async {
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(id);
    final EventHeadDBManager headDBManager = EventHeadDBManager();
    final DateTime now = DateTime.now();

    _head.setRecentDate(now);
    metadata.setLastUID(uid);
    _head.setIsPeriodParent(_metadata.isPeriodParent);

    _lastParentLinkSync = const {};
    final String? oldParent = _baselineParentID;
    final String? newParent = _metadata.parentID;
    if (oldParent != newParent) {
      final createsCycle = await ParentLink.wouldCreateCycleAsync(
        postId: id,
        newParentId: newParent,
        childrenOf: (candidateId) async {
          if (candidateId == id)
            return List<String>.from(_metadata.childrenPostIDs);
          return EventSupplementalDBManager(candidateId).fetchChildrenIDs();
        },
      );
      if (createsCycle) {
        throw StateError(
            'Cannot set parent: would create a related-post cycle');
      }
      _lastParentLinkSync = await dbManager.syncChildrenLinkage(
        childId: id,
        oldParentId: oldParent,
        newParentId: newParent,
      );
      _baselineParentID = newParent;
    }

    await dbManager.addLogEntry(logMessage: log, uid: uid, ts: now);

    await headDBManager.updateHead(_head);
    await dbManager.updateBody(_body.decodedJson);
    await dbManager.updateMetadata(_metadata);
    await dbManager.updateProgram(_program);
    await dbManager.updateMedia(_media);

    if (_attendanceDirty && _attendance != null) {
      final saved = await dbManager.saveStaffManagedAttendance(
        attendees: List<AttendeeEntry>.from(_attendance!.attendees),
        expectedUserIds: List<String>.from(_attendance!.expectedUserIds),
      );
      _attendance = saved;
      _head.setInterestedCount(saved.interestedCount);
      _head.setAttendeeCount(saved.attendeeCount);
      _attendanceDirty = false;
    }
    await UserActivityRecorder().record(
      actorUserId: uid,
      log: UserActivityMessages.editedBulletinPost,
      documentId: id,
    );
  }

  /// User IDs removed from program roles during the current edit (for CF role sync).
  List<String> collectRoleRemovalUserIds() {
    final uids = <String>{};
    for (final removed in _roleRemovals.values) {
      uids.addAll(removed);
    }
    return uids.toList();
  }

  String get id => _head.id;
  bool isUserAdminOfPost(final String currentUID) =>
      _metadata.authorUID.compareTo(currentUID) == 0 ||
      _metadata.contributorUIDs.contains(currentUID);

  void allowSavingOfTheEdit() => _canSaveTheEditing = true;

  // This one is to be used after update is complete
  void resetSavingOfTheEdit() {
    if (_contributorAdditionUIDs.isNotEmpty) {
      _contributorAdditionUIDs.clear();
    }
    if (_contributorRemovalUIDs.isNotEmpty) {
      _contributorRemovalUIDs.clear();
    }
    if (_roleAdditions.isNotEmpty) {
      _roleAdditions.clear();
    }
    if (_roleRemovals.isNotEmpty) {
      _roleRemovals.clear();
      _deletedRoleTitle.clear();
    }
    _notifyBroadcast = true;
    _notifyScheduledMembers = true;
    _attendanceDirty = false;
    _canSaveTheEditing = false;
  }

  bool get canSaveTheEditing => _canSaveTheEditing;

  bool isUserContributor(final String currentUID) =>
      _metadata.contributorUIDs.contains(currentUID);
  bool isUserAuthor(final String currentUID) =>
      _metadata.authorUID.compareTo(currentUID) == 0;

  /// Keeps head and metadata [TagIDs] in sync.
  void applyTagIDs(final List<String> tagIDs) {
    _head.setTagIDs(tagIDs);
    _metadata.setTagIDs(tagIDs);
  }

  /// Keeps head and metadata [CellGroupIDs] in sync.
  void applyCellGroupIDs(final List<String> cellGroupIDs) {
    _head.setCellGroupIDs(cellGroupIDs);
    _metadata.setCellGroupIDs(cellGroupIDs);
  }

  /// Draft expected attendees for new posts / templates (not the live attendance doc).
  List<String> get expectedAttendeeUserIDs =>
      UnmodifiableListView(_expectedAttendeeUserIDs);

  void applyExpectedAttendeeUserIDs(final List<String> userIds) {
    _expectedAttendeeUserIDs
      ..clear()
      ..addAll({
        for (final id in userIds)
          if (id.isNotEmpty) id
      });
  }

  /// Resolves expected IDs for a new post: draft list, else linked CG roster members.
  Future<List<String>> resolveExpectedUserIdsForNewPost() async {
    if (_expectedAttendeeUserIDs.isNotEmpty) {
      return List<String>.from(_expectedAttendeeUserIDs);
    }
    final cgIds = _head.cellGroupIDs;
    if (cgIds.isEmpty) return <String>[];

    final ids = <String>{};
    for (final cgId in cgIds) {
      try {
        final roster = await CellGroupSupplementalDBManager(cgId).fetchRoster();
        for (final member in roster.members) {
          if (member.isLinkedUser && member.isActive) {
            ids.add(member.userId);
          }
        }
      } catch (_) {
        // Roster may be unavailable; skip that group.
      }
    }
    return ids.toList();
  }

  /// Keeps head denorm and metadata [IsPeriodParent] in sync.
  void applyIsPeriodParent(final bool value) {
    _metadata.setIsPeriodParent(value);
    _head.setIsPeriodParent(value);
  }

  /// Sets or clears this post's parent in memory (persisted on [updatePost]).
  void applyParentID(final String? parentID) {
    _metadata.setParentID(parentID);
  }

  /// Recomputes FCM [Topics] from location + notifiable tags (+ optional location umbrella).
  ///
  /// When no notifiable tags are present, preserves non-umbrella entries from current Topics
  /// so legacy posts keep working.
  void syncNotificationTopics({
    required List<PostTag> allTags,
    required bool includeLocationUmbrella,
  }) {
    final legacy = List<String>.from(_metadata.topics);
    final resolved = BroadcastAudience.resolveFromPost(
      location: _head.location,
      tagIDs: _metadata.tagIDs.isNotEmpty ? _metadata.tagIDs : _head.tagIDs,
      allTags: allTags,
      includeLocationUmbrella: includeLocationUmbrella,
      legacyTopics: legacy,
    );
    _metadata.clearTopics();
    _metadata.addAllTopics(resolved);
  }

  void _initialiseInternalLists() {
    if (_metadata.authorUID == _currentUID ||
        _metadata.contributorUIDs.contains(_currentUID)) {
      _contributorAdditionUIDs = List<String>.empty(growable: true);
      _contributorRemovalUIDs = List<String>.empty(growable: true);
    } else {
      _contributorAdditionUIDs = List.empty();
      _contributorRemovalUIDs = List.empty();
    }

    if (_metadata.contributorUIDs.contains(_currentUID) ||
        _metadata.authorUID == _currentUID) {
      _roleAdditions = <int, List<String>>{};
      _roleRemovals = <int, List<String>>{};
      _deletedRoleTitle = <int, String>{};
    } else {
      _roleAdditions = Map.unmodifiable({});
      _roleRemovals = Map.unmodifiable({});
      _deletedRoleTitle = Map.unmodifiable({});
    }
  }

  // * This one is going to be big
  // we need to run through all supplemental parts of a post (body, meta, media etc.)
  // and save it as a txt file. This file should be able to work backwards and create the
  // post from it to save having to read from the DB
  // ! The following is assumed when all of the post is fetched (including logs)
  String transformPostToTxtFile(final String version) {
    // * Head - RecentDate
    String result = '${_head.recentDate.millisecondsSinceEpoch}-$version';

    // * Body - whole json as 1 line?
    result += '\n----BODY_START----';
    result += '\n${_body.json}';
    result += '\n----BODY_END----';

    // * Program - Details
    result += '\n----PROGRAM_DETAILS_START----';
    result += '\n${_program.allDay ? '1' : '0'}';
    result +=
        '\n${_program.finishTime != null ? _program.finishTime!.millisecondsSinceEpoch.toString() : 'null'}';
    result += '\n${_program.online ? '1' : '0'}';
    result += '\n${_program.address}';
    result += '\n${_program.mapLink}';
    result += '\n----PROGRAM_DETAILS_END----';

    // * Program - Roles
    result += '\n----PROGRAM_ROLES_START----';
    final roles = _program.roles;
    for (final role in roles) {
      result += '\n${role['uids']}';
      result += '\n${role['title'] as String}';
      result += '\n${(role['detail'] as String).replaceAll('\n', r'\n')}';
      result +=
          '\n${role['start'] != null ? (role['start'] as DateTime).millisecondsSinceEpoch.toString() : 'null'}';
      result +=
          '\n${role['end'] != null ? (role['end'] as DateTime).millisecondsSinceEpoch.toString() : 'null'}';
      result += '\n${role['for_guests'] == true ? '1' : '0'}';
      result += '\n${role['id'] as int}';
    }
    result += '\n----PROGRAM_ROLES_END----';

    // * Media
    result += '\n----MEDIA_START----';
    final items = media.allMedia;
    for (final item in items) {
      result += '\n${item['type']}';
      result += '\n${item['src']}';
      result += '\n${item['title']}';
      result += '\n${item['thumbnailSrc']}';
    }
    result += '\n----MEDIA_END----';

    // * Logs
    result += '\n----LOGS_START----';
    for (final entry in _log.logs) {
      final String log = (entry['log'] as String).replaceAll('\n', r'\n');
      final DateTime ts = entry['ts'];
      final String uid = entry['uid'];
      result += '\n$log';
      result += '\n${ts.millisecondsSinceEpoch}';
      result += '\n$uid';
    }
    result += '\n----LOGS_END----';

    // * Metadata
    result += '\n----META_START----';
    result += '\n${_metadata.authorUID}';
    result += '\n${_metadata.lastUID}';
    result += '\n${_metadata.contributorUIDs}';
    result += '\n${_metadata.parentID ?? 'null'}';
    result += '\n${_metadata.childrenPostIDs}';
    result += '\n${_metadata.topics}';
    result += '\n${_metadata.leadSpeakerUID ?? 'null'}';
    result += '\n${_metadata.isPeriodParent ? '1' : '0'}';
    result += '\n----META_END----';

    return result;
  }

  // refer to the transform method for parsing to a full post
  void _setWholePostFromTxt(List<String> lines) {
    // * Body - whole json as 1 line?
    final int bodyStartIndex =
        lines.indexWhere((element) => element.contains('----BODY_START----'));
    _body.setJson(lines[bodyStartIndex + 1]);

    // * Program - Details
    final int programDetailStartIndex = lines.indexWhere(
        (element) => element.contains('----PROGRAM_DETAILS_START----'));
    final int allDayIndex = programDetailStartIndex + 1;
    final int finishTimeIndex = programDetailStartIndex + 2;
    final int onlineIndex = programDetailStartIndex + 3;
    final int addressIndex = programDetailStartIndex + 4;
    final int mapLinkIndex = programDetailStartIndex + 5;

    _program = EventProgram();
    _program.setAllDay(lines[allDayIndex].compareTo('1') == 0);
    _program.setFinishTime(lines[finishTimeIndex].compareTo('null') == 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            int.parse(lines[finishTimeIndex])));
    _program.setOnline(lines[onlineIndex] == '1');
    _program.setAddress(lines[addressIndex]);
    _program.setMapLink(lines[mapLinkIndex]);

    // * Program - Roles
    final int programRoleStartIndex = lines.indexWhere(
        (element) => element.contains('----PROGRAM_ROLES_START----'));
    final int programRoleEndIndex = lines
        .indexWhere((element) => element.contains('----PROGRAM_ROLES_END----'));
    if (programRoleEndIndex != programRoleStartIndex + 1) {
      // sublist and create the roles from it
      _initialiseProgramRoles(
          lines.sublist(programRoleStartIndex + 1, programRoleEndIndex));
    }

    // * Media
    final int mediaStartIndex =
        lines.indexWhere((element) => element.contains('----MEDIA_START----'));
    final int mediaEndIndex =
        lines.indexWhere((element) => element.contains('----MEDIA_END----'));
    _media = EventMedia();
    if (mediaEndIndex != mediaStartIndex + 1) {
      // build roles from sublist
      _initialiseMedia(lines.sublist(mediaStartIndex + 1, mediaEndIndex));
    }

    // * Logs
    final int logsStartIndex =
        lines.indexWhere((element) => element.contains('----LOGS_START----'));
    final int logsEndIndex =
        lines.indexWhere((element) => element.contains('----LOGS_END----'));
    // build logs from sublist
    _initialiseLogs(lines.sublist(logsStartIndex + 1, logsEndIndex));

    // * Metadata
    final int metadataStartIndex =
        lines.indexWhere((element) => element.contains('----META_START----'));
    _metadata = EventMetadata(
        authorUID: lines[metadataStartIndex + 1],
        parentID: lines[metadataStartIndex + 4] == 'null'
            ? null
            : lines[metadataStartIndex + 4]);

    _metadata.setLastUID(lines[metadataStartIndex + 2]);
    _metadata.contributorUIDs
        .addAll(_getListFromData(lines[metadataStartIndex + 3]));
    _metadata.childrenPostIDs
        .addAll(_getListFromData(lines[metadataStartIndex + 5]));

    String rawTopicsData = lines.elementAt(metadataStartIndex + 6);
    if (!rawTopicsData.contains('----META_END----')) {
      _metadata.addAllTopics(_getListFromData(rawTopicsData));
      final String rawLeadSpeaker = lines.elementAt(metadataStartIndex + 7);
      if (!rawLeadSpeaker.contains('----META_END----') &&
          rawLeadSpeaker != 'null') {
        _metadata.setLeadSpeakerUID(rawLeadSpeaker);
      }
      if (lines.length > metadataStartIndex + 8) {
        final String rawPeriod = lines.elementAt(metadataStartIndex + 8);
        if (!rawPeriod.contains('----META_END----')) {
          _metadata.setIsPeriodParent(rawPeriod == '1');
          _head.setIsPeriodParent(_metadata.isPeriodParent);
        }
      }
    }
    _baselineParentID = _metadata.parentID;
  }

  List<String> _getListFromData(final String rawData) {
    final String contributorLine =
        rawData.replaceAll('[', '').replaceAll(']', '').replaceAll(' ', '');
    final List<String> contributors = List.empty(growable: true);
    if (contributorLine.isNotEmpty && !contributorLine.contains(',')) {
      contributors.add(contributorLine);
    } else if (contributorLine.isNotEmpty) {
      contributors.addAll(contributorLine.split(','));
    }

    return contributors;
  }

  void _initialiseProgramRoles(final List<String> data) {
    // groups of 7 elements
    const int chunkSize = 7;
    final int numberOfChunks = data.length ~/ chunkSize;

    final List<List<String>> roles =
        List<List<String>>.generate(numberOfChunks, (index) {
      int startIndex = index * chunkSize;
      int endIndex = (index + 1) * chunkSize;
      return data.sublist(startIndex, endIndex);
    });

    for (final roleDataSet in roles) {
      final String uidLine = roleDataSet[0]
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll(' ', '');
      final List<String> uids = List<String>.empty(growable: true);
      if (uidLine.isNotEmpty && !uidLine.contains(',')) {
        uids.add(uidLine);
      } else if (uidLine.isNotEmpty) {
        uids.addAll(uidLine.split(','));
      }

      _program.addRole(
          uids: uids,
          title: roleDataSet[1],
          detail: roleDataSet[2].replaceAll(r'\n', '\n'),
          start: roleDataSet[3].compareTo('null') != 0
              ? DateTime.fromMillisecondsSinceEpoch(int.parse(roleDataSet[3]))
              : null,
          end: roleDataSet[4].compareTo('null') != 0
              ? DateTime.fromMillisecondsSinceEpoch(int.parse(roleDataSet[4]))
              : null,
          forGuests: roleDataSet[5] == '1' ? true : false,
          id: int.parse(roleDataSet[6]));
    }
  }

  void _initialiseMedia(final List<String> data) {
    // groups of 3
    const int chunkSize = 4;
    final int numberOfChunks = data.length ~/ chunkSize;

    final List<List<String>> media =
        List<List<String>>.generate(numberOfChunks, (index) {
      int startIndex = index * chunkSize;
      int endIndex = (index + 1) * chunkSize;
      return data.sublist(startIndex, endIndex);
    });

    for (final mediaItem in media) {
      if (mediaItem.length == 4) {
        _media.addMediaFile({
          'type': mediaItem[0],
          'src': mediaItem[1],
          'title': mediaItem[2],
          'thumbnailSrc': mediaItem[3]
        });
      } else {
        _media.addMediaFile(
            {'type': mediaItem[0], 'src': mediaItem[1], 'title': mediaItem[2]});
      }
    }
  }

  void _initialiseLogs(final List<String> data) {
    // groups of 3
    const int chunkSize = 3;
    final int numberOfChunks = data.length ~/ chunkSize;

    final List<List<String>> logs =
        List<List<String>>.generate(numberOfChunks, (index) {
      int startIndex = index * chunkSize;
      int endIndex = (index + 1) * chunkSize;
      return data.sublist(startIndex, endIndex);
    });

    final firstLog = logs.removeAt(0);

    _log = EventLog({
      'log': firstLog[0].replaceAll(r'\n', '\n'),
      'ts': DateTime.fromMillisecondsSinceEpoch(int.parse(firstLog[1])),
      'uid': firstLog[2]
    });

    for (final List<String> logItem in logs) {
      _log.addLog(
          log: logItem[0].replaceAll(r'\n', '\n'),
          uid: logItem[2],
          ts: DateTime.fromMillisecondsSinceEpoch(int.parse(logItem[1])));
    }
  }

  Map<int, List<String>> get roleAdditions =>
      UnmodifiableMapView(_roleAdditions);
  Map<int, List<String>> get roleRemovalals =>
      UnmodifiableMapView(_roleRemovals);
  String deletedRoleTitle(final int id) => _deletedRoleTitle[id]!;

  void addRoleAdditionNotification(final Iterable<String> uids, final int id) {
    if (_roleAdditions[id] == null) {
      _roleAdditions[id] = <String>[];
    }
    _roleAdditions[id]!.addAll(uids);
  }

  void addRoleRemovalNotification(final Iterable<String> uids, final int id) {
    if (_roleRemovals[id] == null) {
      _roleRemovals[id] = <String>[];
    }
    _roleRemovals[id]!.addAll(uids);
  }

  void addRoleDeletionTitle(final int id, final String title) =>
      _deletedRoleTitle[id] = title;

  void removeRoleAdditionNotification(final int id) =>
      _roleAdditions.remove(id);

  List<String> get contributorAdditionUIDs => _contributorAdditionUIDs;
  List<String> get contributorRemovalUIDs => _contributorRemovalUIDs;

  /// Replaces contributor UIDs and updates addition/removal tracking for save notifications.
  void applyContributorUIDs(List<String> newUIDs) {
    final previous = Set<String>.from(_metadata.contributorUIDs);
    final next = Set<String>.from(newUIDs);

    _metadata.contributorUIDs
      ..clear()
      ..addAll(newUIDs);

    for (final added in next.difference(previous)) {
      if (!_contributorAdditionUIDs.contains(added)) {
        _contributorAdditionUIDs.add(added);
      }
      _contributorRemovalUIDs.remove(added);
    }
    for (final removed in previous.difference(next)) {
      _contributorAdditionUIDs.remove(removed);
      if (!_contributorRemovalUIDs.contains(removed)) {
        _contributorRemovalUIDs.add(removed);
      }
    }
  }

  /// Sets or clears the lead speaker on metadata + head denormalized portrait fields.
  void applyLeadSpeaker({
    required String? uid,
    String? imgSrc,
    String? name,
  }) {
    if (uid == null || uid.isEmpty) {
      _metadata.clearLeadSpeakerUID();
      _head.clearLeadSpeaker();
      return;
    }
    _metadata.setLeadSpeakerUID(uid);
    _head.setLeadSpeaker(
      uid: uid,
      imgSrc: (imgSrc != null && imgSrc.isNotEmpty) ? imgSrc : null,
      name: (name != null && name.isNotEmpty) ? name : null,
    );
  }

  /// Resolves [metadata.leadSpeakerUID] against [users] into head portrait fields.
  void syncLeadSpeakerHeadFromUsers(Iterable<User> users) {
    final uid = _metadata.leadSpeakerUID;
    if (uid == null || uid.isEmpty) {
      _head.clearLeadSpeaker();
      return;
    }
    for (final user in users) {
      if (user.id == uid) {
        applyLeadSpeaker(uid: uid, imgSrc: user.imgSrc, name: user.fullname);
        return;
      }
    }
    // Keep UID even if user list does not contain them yet.
    _head.setLeadSpeaker(
        uid: uid, imgSrc: _head.leadSpeakerImgSrc, name: _head.leadSpeakerName);
  }

  // template subtitles
  List<String>? get templateSubtitles => _templateSubtitles;
  void setTemplateSubtitles(final List<String>? subtitles) =>
      _templateSubtitles = subtitles;

  // template media pools
  List<Map<String, dynamic>>? _templateHeadMediaPool;
  List<Map<String, dynamic>>? _templateBodyMediaPool;

  List<Map<String, dynamic>>? get templateHeadMediaPool =>
      _templateHeadMediaPool;
  void setTemplateHeadMediaPool(final List<Map<String, dynamic>>? pool) =>
      _templateHeadMediaPool = pool;

  List<Map<String, dynamic>>? get templateBodyMediaPool =>
      _templateBodyMediaPool;
  void setTemplateBodyMediaPool(final List<Map<String, dynamic>>? pool) =>
      _templateBodyMediaPool = pool;
}
