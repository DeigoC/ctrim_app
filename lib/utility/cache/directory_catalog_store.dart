import '../../firebase/db_managers/id_tracker.dart';
import '../../models/cell_group.dart';
import '../../models/post_tag.dart';
import '../../models/user_location.dart';
import '../../models/user_tag.dart';
import 'local_data_manager.dart';

/// Hive copies of post tags, locations, team tags, and cell-group heads.
///
/// Writes that change a record also bump `id_tracker/directories` so the next
/// session can skip the collection read. Roster documents are not stored.
class DirectoryCatalogStore {
  DirectoryCatalogStore({
    LocalDataManager? localDataManager,
    IDTrackerDBManager? idTracker,
  })  : _local = localDataManager ?? LocalDataManager(),
        _tracker = idTracker ?? IDTrackerDBManager();

  final LocalDataManager _local;
  final IDTrackerDBManager _tracker;

  Future<List<PostTag>> readPostTags() async {
    return _decode(await _local.readPostTags(), PostTag.fromMap);
  }

  Future<List<UserLocation>> readUserLocations() async {
    return _decode(await _local.readUserLocations(), UserLocation.fromMap);
  }

  Future<List<UserTag>> readUserTags() async {
    return _decode(await _local.readUserTags(), UserTag.fromMap);
  }

  Future<List<CellGroup>> readCellGroups() async {
    return _decode(await _local.readCellGroups(), CellGroup.fromMap);
  }

  Future<void> replacePostTags(
    final List<PostTag> tags, {
    required int remoteLastUpdate,
  }) async {
    await _local.writePostTags(
      tags.map((tag) => {'id': tag.id, ...tag.toJson()}).toList(),
    );
    await _stampFetched(IDTrackerDBManager.postTagsField, remoteLastUpdate);
  }

  Future<void> replaceUserLocations(
    final List<UserLocation> locations, {
    required int remoteLastUpdate,
  }) async {
    await _local.writeUserLocations(
      locations
          .map((location) => {'id': location.id, ...location.toJson()})
          .toList(),
    );
    await _stampFetched(
      IDTrackerDBManager.userLocationsField,
      remoteLastUpdate,
    );
  }

  Future<void> replaceUserTags(
    final List<UserTag> tags, {
    required int remoteLastUpdate,
  }) async {
    await _local.writeUserTags(
      tags.map((tag) => {'id': tag.id, ...tag.toJson()}).toList(),
    );
    await _stampFetched(IDTrackerDBManager.userTagsField, remoteLastUpdate);
  }

  Future<void> replaceCellGroups(
    final List<CellGroup> groups, {
    required int remoteLastUpdate,
  }) async {
    await _local.writeCellGroups(
      groups.map((group) => group.toCacheJson()).toList(),
    );
    await _stampFetched(IDTrackerDBManager.cellGroupsField, remoteLastUpdate);
  }

  Future<void> upsertPostTag(final PostTag tag) async {
    await _upsert(
      read: _local.readPostTags,
      write: _local.writePostTags,
      id: tag.id,
      json: {'id': tag.id, ...tag.toJson()},
      field: IDTrackerDBManager.postTagsField,
    );
  }

  Future<void> deletePostTag(final String id) async {
    await _delete(
      read: _local.readPostTags,
      write: _local.writePostTags,
      id: id,
      field: IDTrackerDBManager.postTagsField,
    );
  }

  Future<void> upsertUserLocation(final UserLocation location) async {
    await _upsert(
      read: _local.readUserLocations,
      write: _local.writeUserLocations,
      id: location.id,
      json: {'id': location.id, ...location.toJson()},
      field: IDTrackerDBManager.userLocationsField,
    );
  }

  Future<void> deleteUserLocation(final String id) async {
    await _delete(
      read: _local.readUserLocations,
      write: _local.writeUserLocations,
      id: id,
      field: IDTrackerDBManager.userLocationsField,
    );
  }

  Future<void> upsertUserTag(final UserTag tag) async {
    await _upsert(
      read: _local.readUserTags,
      write: _local.writeUserTags,
      id: tag.id,
      json: {'id': tag.id, ...tag.toJson()},
      field: IDTrackerDBManager.userTagsField,
    );
  }

  Future<void> deleteUserTag(final String id) async {
    await _delete(
      read: _local.readUserTags,
      write: _local.writeUserTags,
      id: id,
      field: IDTrackerDBManager.userTagsField,
    );
  }

  Future<void> upsertCellGroup(final CellGroup group) async {
    await _upsert(
      read: _local.readCellGroups,
      write: _local.writeCellGroups,
      id: group.id,
      json: group.toCacheJson(),
      field: IDTrackerDBManager.cellGroupsField,
    );
  }

  Future<void> patchCellGroupMemberCount({
    required String id,
    required int memberCount,
  }) async {
    if (!await _hasSnapshot(IDTrackerDBManager.cellGroupsField)) {
      await _bumpRemoteOnly(IDTrackerDBManager.cellGroupsField);
      return;
    }
    final maps = await _local.readCellGroups();
    var found = false;
    for (final map in maps) {
      if (map['id']?.toString() == id) {
        map['MemberCount'] = memberCount < 0 ? 0 : memberCount;
        found = true;
      }
    }
    if (!found) {
      await _bumpRemoteOnly(IDTrackerDBManager.cellGroupsField);
      await _local.writeCollectionLastUpdate(
          IDTrackerDBManager.cellGroupsField, 0);
      return;
    }
    await _local.writeCellGroups(maps);
    await _stampMutation(IDTrackerDBManager.cellGroupsField);
  }

  Future<void> _upsert({
    required Future<List<Map<String, dynamic>>> Function() read,
    required Future<void> Function(List<Map<String, dynamic>> records) write,
    required String id,
    required Map<String, dynamic> json,
    required String field,
  }) async {
    if (!await _hasSnapshot(field)) {
      await _bumpRemoteOnly(field);
      return;
    }
    final maps = await read();
    final next = <Map<String, dynamic>>[];
    var replaced = false;
    for (final map in maps) {
      if (map['id']?.toString() == id) {
        next.add(json);
        replaced = true;
      } else {
        next.add(map);
      }
    }
    if (!replaced) next.add(json);
    await write(next);
    await _stampMutation(field);
  }

  Future<void> _delete({
    required Future<List<Map<String, dynamic>>> Function() read,
    required Future<void> Function(List<Map<String, dynamic>> records) write,
    required String id,
    required String field,
  }) async {
    if (!await _hasSnapshot(field)) {
      await _bumpRemoteOnly(field);
      return;
    }
    final maps = await read();
    maps.removeWhere((map) => map['id']?.toString() == id);
    await write(maps);
    await _stampMutation(field);
  }

  Future<bool> _hasSnapshot(final String field) async {
    return (await _local.readCollectionLastUpdate(field)) > 0;
  }

  /// Move the shared watermark without writing a one-record list over Hive.
  Future<void> _bumpRemoteOnly(final String field) async {
    await _tracker.tryTouchDirectoryLastUpdate(field);
  }

  /// A real edit. Move the remote watermark, then mirror it locally.
  Future<void> _stampMutation(final String field) async {
    final stamped = await _tracker.tryTouchDirectoryLastUpdate(field);
    final local = stamped > 0 ? stamped : DateTime.now().millisecondsSinceEpoch;
    await _local.writeCollectionLastUpdate(field, local);
  }

  /// A download. Keep the server watermark when it already exists.
  Future<void> _stampFetched(
      final String field, final int remoteLastUpdate) async {
    var stamp = remoteLastUpdate;
    if (stamp <= 0) {
      stamp = await _tracker.tryTouchDirectoryLastUpdate(field);
    }
    if (stamp <= 0) {
      stamp = DateTime.now().millisecondsSinceEpoch;
    }
    await _local.writeCollectionLastUpdate(field, stamp);
  }

  List<T> _decode<T>(
    final List<Map<String, dynamic>> maps,
    final T Function(String id, Map<String, dynamic> data) fromMap,
  ) {
    final records = <T>[];
    for (final map in maps) {
      final id = map['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      try {
        records.add(fromMap(id, map));
      } catch (_) {
        continue;
      }
    }
    return records;
  }
}
