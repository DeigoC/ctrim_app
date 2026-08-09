import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/cell_group.dart';
import '../../models/cell_group_roster.dart';
import '../../models/event/event_head.dart';
import 'id_tracker.dart';

class CellGroupDBManager {
  static final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('cell_groups').withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data() ?? {},
            toFirestore: (data, _) => data,
          );

  Future<List<CellGroup>> fetchAllGroups() async {
    final snapshot = await _ref.get();
    final groups = snapshot.docs.map((doc) => CellGroup.fromMap(doc.id, doc.data())).toList();
    groups.sort((a, b) {
      final statusOrder = _statusRank(a.status).compareTo(_statusRank(b.status));
      if (statusOrder != 0) return statusOrder;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return groups;
  }

  Future<CellGroup?> fetchGroup(final String id) async {
    final snap = await _ref.doc(id).get();
    if (!snap.exists) return null;
    return CellGroup.fromMap(snap.id, snap.data() ?? {});
  }

  Future<CellGroup> createGroup({
    required String name,
    String summary = '',
    String location = 'Belfast',
    List<String> leaderUserIds = const [],
    List<String> leaderAuthIds = const [],
    List<Map<String, dynamic>> media = const [],
    String? keyGraphicSrc,
    String status = CellGroupStatus.active,
    int? meetingWeekday,
    String meetingTime = '',
    required String createdByUserID,
  }) async {
    final id = await IDTrackerDBManager().getAndIncrementCellGroupID();
    final now = DateTime.now();
    final group = CellGroup(
      id: id,
      name: name,
      summary: summary,
      location: location,
      leaderUserIds: leaderUserIds,
      leaderAuthIds: leaderAuthIds,
      media: media,
      keyGraphicSrc: keyGraphicSrc,
      memberCount: 0,
      status: status,
      meetingWeekday: meetingWeekday,
      meetingTime: meetingTime,
      createdByUserID: createdByUserID,
      createdAt: now,
      updatedAt: now,
    );
    await _ref.doc(id).set(group.toJson());
    await CellGroupSupplementalDBManager(id).setRoster(CellGroupRoster());
    return group;
  }

  Future<void> updateGroup(final CellGroup group) async {
    group.setUpdatedAt(DateTime.now());
    await _ref.doc(group.id).update(group.toJson());
  }

  /// Updates only [MemberCount] denorm (e.g. after roster save).
  Future<void> updateMemberCount({
    required String id,
    required int memberCount,
  }) async {
    await _ref.doc(id).update({
      'MemberCount': memberCount < 0 ? 0 : memberCount,
      'UpdatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Recent bulletin heads linked to this CG (`CellGroupIDs` array-contains).
  Future<List<EventHead>> fetchMeetingTrail({
    required String cellGroupId,
    int limit = 4,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('CellGroupIDs', arrayContains: cellGroupId)
        .limit(limit * 3)
        .get();
    final heads = snapshot.docs
        .map((doc) => EventHead.fromMap(doc.id, doc.data()))
        .toList();
    heads.sort((a, b) {
      final aDate = a.eventDate ?? a.recentDate;
      final bDate = b.eventDate ?? b.recentDate;
      return bDate.compareTo(aDate);
    });
    if (heads.length <= limit) return heads;
    return heads.sublist(0, limit);
  }

  static int _statusRank(final String status) {
    switch (status) {
      case CellGroupStatus.active:
        return 0;
      case CellGroupStatus.paused:
        return 1;
      case CellGroupStatus.archived:
        return 2;
      default:
        return 3;
    }
  }
}

class CellGroupSupplementalDBManager {
  late final CollectionReference<Map<String, dynamic>> _colRef;
  late final String _cellGroupId;

  CellGroupSupplementalDBManager(String id) {
    _cellGroupId = id;
    _colRef = FirebaseFirestore.instance
        .collection('cell_groups')
        .doc(id)
        .collection('supplemental')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? {},
          toFirestore: (data, _) => data,
        );
  }

  String get cellGroupId => _cellGroupId;

  Future<CellGroupRoster> fetchRoster() async {
    final snap = await _colRef.doc('roster').get();
    if (!snap.exists) return CellGroupRoster();
    return CellGroupRoster.fromMap(snap.data() ?? {});
  }

  Future<void> setRoster(final CellGroupRoster roster) async {
    await _colRef.doc('roster').set(roster.toJson());
  }
}
