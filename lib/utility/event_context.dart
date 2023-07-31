import 'dart:collection';
import '../firebase/db_managers/event_db_manager.dart';
import '../firebase/db_managers/id_tracker.dart';
import '../models/event/event_body.dart';
import '../models/event/event_head.dart';
import '../models/event/event_log.dart';
import '../models/event/event_media.dart';
import '../models/event/event_metadata.dart';
import '../models/event/event_program.dart';

class EventContext {
  late final EventHead _head;
  late final EventLog _log;
  late final EventMetadata _metadata;
  late final EventProgram _program;
  late final EventMedia _media;
  final EventBody _body = EventBody();

  // there will be no need for these
  bool _fetchedBody = false,
      _fetchedProgram = false,
      _fetchedMedia = false,
      _canSaveTheEditing = false,
      _viewingChild = false,
      _fetchedLogs = false,
      _fetchedMeta = false;

  // for viewing and editing
  EventContext.viewing({required EventHead eventHead, bool? viewingChild, List<String>? data}) {
    _head = eventHead;
    _canSaveTheEditing = false;
    _viewingChild = viewingChild ?? _viewingChild;

    if (data != null) {
      _setWholePostFromTxt(data);
    }
  }

  EventContext.adding({required String uid, String? parentID}) {
    _fetchedBody = true;
    _metadata = EventMetadata(authorUID: uid, parentID: parentID);
    _program = EventProgram();
    _media = EventMedia();
  }

  // * Head Related
  EventHead get head => _head;

  // * Body Related
  bool get haveFetchedBody => _fetchedBody;

  // ! be weary because trim() could not be applied
  bool get isBodyUntouched => _body.json.compareTo('[{"insert":"Hello, time to start writing!\n"}]') == 0;
  List<dynamic> get body => _body.decodedJson;
  String get encodedBody => _body.json;

  void setBodyJson(List<dynamic> json) {
    _body.encodeJson(json);
  }

  void setFetchedBody(String encodedBody) {
    _body.setJson(encodedBody);
    _fetchedBody = true;
  }

  bool isSameJson(List<dynamic> json) => _body.compareTo(json) == 0;

  // * Program Related (and the Event Date)

  EventProgram get program => _program;
  bool get haveFetchedProgram => _fetchedProgram;
  List<Map<String, dynamic>> get allPrograms => UnmodifiableListView(_program.roles);

  void setFetchedProgram(EventProgram program) {
    _fetchedProgram = true;
    _program = program;
  }

  void addProgram(Map<String, dynamic> programEntry) => _program.addRole(programEntry);

  // * Supplemental - Metadata Related

  EventMetadata get metadata => _metadata;

  void setFetchedMetadata(EventMetadata data) {
    if (!_fetchedMeta) {
      _metadata = data;
      _fetchedMeta = true;
    }
  }

  bool get fetchedMetadata => _fetchedMeta;

  // * Supplemental - Media Related

  EventMedia get media => _media;
  bool get fethcedMedia => _fetchedMedia;
  void setFetchedMedia(EventMedia media) {
    _media = media;
    _fetchedMedia = true;
  }

  // * Logs Related
  EventLog get log => _log;
  bool get fetchedLogs => _fetchedLogs;

  void setFetchedLogs(EventLog log) {
    _log = log;
    _fetchedLogs = true;
  }

  // * General logic

  Future<String> addNewPost({
    required String title,
    required String subtitle,
    required String uid,
    DateTime? eventDate,
  }) async {
    final String id = await _getNewID();
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(id);
    final EventHeadDBManager headDBManager = EventHeadDBManager();
    final DateTime now = DateTime.now();

    // head stuff
    _head = EventHead(id: id); // TODO add the key media!
    _head.setTitle(title);
    _head.setSubtitle(subtitle);
    _head.setRecentDate(now);

    // metadata
    _metadata.setLastUID(uid);

    // log, create the new one for creation
    _log = EventLog({'uid': uid, 'log': 'Publication', 'ts': now});

    await headDBManager.saveNewHead(_head);
    dbManager.addBody(_body.json);
    dbManager.addMedia(_media);
    dbManager.addMetadata(_metadata);
    dbManager.addLog(_log);
    dbManager.addProgram(_program);
    return id;
  }

  Future<void> updatePost({required String log, required String uid}) async {
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(id);
    final EventHeadDBManager headDBManager = EventHeadDBManager();
    final DateTime now = DateTime.now();

    head.setRecentDate(now);
    metadata.setLastUID(uid);

    _log.addLog({'log': log, 'uid': uid, 'ts': now});

    await headDBManager.updateHead(_head);
    dbManager.updateBody(_body.decodedJson);
    dbManager.updateMetadata(_metadata);
    dbManager.updateProgram(_program);
    dbManager.updateLog(_log);
    if (_fetchedMedia) {
      dbManager.updateMedia(_media);
    }
  }

  Future<String> _getNewID() async {
    final IDTrackerDBManager idTrackerDBManager = IDTrackerDBManager();
    return await idTrackerDBManager.getAndIncrementEventID();
  }

  String get id => _head.id;

  bool isUserAdminOfPost(String currentUID) {
    return _metadata.authorUID.compareTo(currentUID) == 0 || _metadata.contributorUIDs.contains(currentUID);
  }

  void allowSavingOfTheEdit() => _canSaveTheEditing = true;
  bool get canSaveTheEditing => _canSaveTheEditing;
  void resetSavingOfTheEdit() => _canSaveTheEditing = false; // This one is to be used after update is complete

  bool get isViewingChild => _viewingChild;
  void enableViewingChild() => _viewingChild = true;
  void disableViewingChild() => _viewingChild = false;

  bool isCurrentUserContributor(final String currentUID) => _metadata.contributorUIDs.contains(currentUID);
  bool isCurrentUserAuthor(final String currentUID) => _metadata.authorUID.compareTo(currentUID) == 0;

  // * This one is going to be big
  // we need to run through all supplemental parts of a post (body, meta, media etc.)
  // and save it as a txt file. This file should be able to work backwards and create the
  // post from it to save having to read from the DB
  // ! The following is assumed when all of the post is fetched (including logs)
  // ? i just realised i can put a lot of this logic into each of the part's dedicated class,
  // I'll do that later...
  String transformPostToTxtFile() {
    // * Head - RecentDate
    String result = _head.recentDate.millisecondsSinceEpoch.toString();

    // * Body - whole json as 1 line?
    result += '\n----BODY_START----';
    result += '\n${_body.json}';
    result += '\n----BODY_END----';

    // * Program - Details
    result += '\n----PROGRAM_DETAILS_START----';
    result += '\n${_program.allDay ? '1' : '0'}';
    result += '\n${_program.finishTime != null ? _program.finishTime!.millisecondsSinceEpoch.toString() : 'null'}';
    result += '\n----PROGRAM_DETAILS_END----';

    // * Program - Roles
    result += '\n----PROGRAM_ROLES_START----';
    final roles = _program.roles;
    for (final role in roles) {
      result += '\n${role['uids']}';
      result += '\n${role['title'] as String}';
      result += '\n${(role['detail'] as String).replaceAll('\n', r'\n')}';
      result += '\n${role['start'] != null ? (role['start'] as DateTime).millisecondsSinceEpoch.toString() : 'null'}';
      result += '\n${role['end'] != null ? (role['end'] as DateTime).millisecondsSinceEpoch.toString() : 'null'}';
      result += '\n${role['for_guests'] == true ? '1' : '0'}';
      result += '\n${role['priority'] as int}';
    }
    result += '\n----PROGRAM_ROLES_END----';

    // * Media
    result += '\n----MEDIA_START----';
    final items = media.allMedia;
    for (final item in items) {
      result += '\n${item['type']}';
      result += '\n${item['src']}';
      result += '\n${item['title']}';
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
    result += '\n${_metadata.children}';
    result += '\n----META_END----';

    return result;
  }

  // the file has been parsed by a linesplitter
  // refer to the transform method for parsing to a full post
  void _setWholePostFromTxt(List<String> lines) {
    // * Body - whole json as 1 line?
    final int bodyStartIndex = lines.indexWhere((element) => element.contains('----BODY_START----'));
    _body.setJson(lines[bodyStartIndex + 1]);

    // * Program - Details
    final int programDetailStartIndex =
        lines.indexWhere((element) => element.contains('----PROGRAM_DETAILS_START----'));
    final int allDayIndex = programDetailStartIndex + 1;
    final int finishTimeIndex = programDetailStartIndex + 2;

    _program = EventProgram();
    _program.setAllDay(lines[allDayIndex].compareTo('1') == 0);
    _program.setFinishTime(lines[finishTimeIndex].compareTo('null') == 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(int.parse(lines[finishTimeIndex])));

    // * Program - Roles
    final int programRoleStartIndex = lines.indexWhere((element) => element.contains('----PROGRAM_ROLES_START----'));
    final int programRoleEndIndex = lines.indexWhere((element) => element.contains('----PROGRAM_ROLES_END----'));
    if (programRoleEndIndex != programRoleStartIndex + 1) {
      // sublist and create the roles from it
      _initialiseProgramRoles(lines.sublist(programRoleStartIndex + 1, programRoleEndIndex));
    }

    // * Media
    final int mediaStartIndex = lines.indexWhere((element) => element.contains('----MEDIA_START----'));
    final int mediaEndIndex = lines.indexWhere((element) => element.contains('----MEDIA_END----'));
    _media = EventMedia();
    if (mediaEndIndex != mediaStartIndex + 1) {
      // build roles from sublist
      _initialiseMedia(lines.sublist(mediaStartIndex + 1, mediaEndIndex));
    }

    // * Logs
    final int logsStartIndex = lines.indexWhere((element) => element.contains('----LOGS_START----'));
    final int logsEndIndex = lines.indexWhere((element) => element.contains('----LOGS_END----'));
    // build logs from sublist
    _initialiseLogs(lines.sublist(logsStartIndex + 1, logsEndIndex));

    // * Metadata
    final int metadataStartIndex = lines.indexWhere((element) => element.contains('----META_START----'));
    _metadata = EventMetadata(
        authorUID: lines[metadataStartIndex + 1],
        parentID: lines[metadataStartIndex + 4] == 'null' ? null : lines[metadataStartIndex + 4]);

    _metadata.setLastUID(lines[metadataStartIndex + 2]);

    final List<String> contributors = lines[metadataStartIndex + 3].replaceAll('[', '').replaceAll(']', '').split(',');
    for (final contributor in contributors) {
      _metadata.addContributorUID(contributor);
    }

    final List<String> childrenIDs = lines[metadataStartIndex + 5].replaceAll('[', '').replaceAll(']', '').split(',');
    for (final child in childrenIDs) {
      _metadata.addChildID(child);
    }

    _fetchedBody = true;
    _fetchedProgram = true;
    _fetchedMedia = true;
    _fetchedLogs = true;
    _fetchedMeta = true;
  }

  void _initialiseProgramRoles(final List<String> data) {
    // groups of 7 elements
    const int chunkSize = 7;
    final int numberOfChunks = data.length ~/ chunkSize;

    final List<List<String>> roles = List<List<String>>.generate(numberOfChunks, (index) {
      int startIndex = index * chunkSize;
      int endIndex = (index + 1) * chunkSize;
      return data.sublist(startIndex, endIndex);
    });

    for (final roleDataSet in roles) {
      final List<String> uids = roleDataSet[0].replaceAll('[', '').replaceAll(']', '').split(',');

      _program.addRole({
        'uids': uids,
        'title': roleDataSet[1],
        'detail': roleDataSet[2].replaceAll(r'\n', '\n'),
        'start': roleDataSet[3].compareTo('null') != 0
            ? DateTime.fromMillisecondsSinceEpoch(int.parse(roleDataSet[3]))
            : null,
        'end': roleDataSet[4].compareTo('null') != 0
            ? DateTime.fromMillisecondsSinceEpoch(int.parse(roleDataSet[4]))
            : null,
        'for_guests': roleDataSet[5] == '1' ? true : false,
        'priority': int.parse(roleDataSet[6])
      });
    }
  }

  void _initialiseMedia(final List<String> data) {
    // groups of 3
    const int chunkSize = 3;
    final int numberOfChunks = data.length ~/ chunkSize;

    final List<List<String>> media = List<List<String>>.generate(numberOfChunks, (index) {
      int startIndex = index * chunkSize;
      int endIndex = (index + 1) * chunkSize;
      return data.sublist(startIndex, endIndex);
    });

    for (final mediaItem in media) {
      _media.addMediaFile({'type': mediaItem[0], 'src': mediaItem[1], 'title': mediaItem[2]});
    }
  }

  void _initialiseLogs(final List<String> data) {
    // groups of 3
    const int chunkSize = 3;
    final int numberOfChunks = data.length ~/ chunkSize;

    final List<List<String>> logs = List<List<String>>.generate(numberOfChunks, (index) {
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

    for (final logItem in logs) {
      _log.addLog({
        'log': logItem[0].replaceAll(r'\n', '\n'),
        'ts': DateTime.fromMillisecondsSinceEpoch(int.parse(logItem[1])),
        'uid': logItem[2]
      });
    }
  }
}
