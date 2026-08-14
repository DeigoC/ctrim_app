import 'package:flutter/foundation.dart';

import '../firebase/db_managers/event_db_manager.dart';
import '../firebase/db_managers/id_tracker.dart';
import '../models/event/event_head.dart';
import 'collection_cache_policy.dart';
import 'local_data_manager.dart';

/// Loads bulletin event heads from Hive when `id_tracker/events.lastUpdate` matches.
class EventHeadsRepository {
  EventHeadsRepository({
    LocalDataManager? localDataManager,
    EventHeadDBManager? eventHeadDBManager,
    IDTrackerDBManager? idTracker,
  })  : _localDataManager = localDataManager ?? LocalDataManager(),
        _eventHeadDBManager = eventHeadDBManager ?? EventHeadDBManager(),
        _idTracker = idTracker ?? IDTrackerDBManager();

  final LocalDataManager _localDataManager;
  final EventHeadDBManager _eventHeadDBManager;
  final IDTrackerDBManager _idTracker;

  Future<List<EventHead>> fetchEventHeads({bool forceRefresh = false}) async {
    final cached = await _readCachedHeads();

    int remoteLastUpdate;
    try {
      remoteLastUpdate = await _idTracker.fetchLastUpdate(IDTrackerDBManager.eventsDoc);
    } catch (e) {
      debugPrint('EventHeadsRepository: lastUpdate read failed, using cache if any: $e');
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }

    final localLastUpdate = await _localDataManager.readCollectionLastUpdate('events');
    if (shouldUseLocalCollectionCache(
      forceRefresh: forceRefresh,
      hasCachedRecords: cached.isNotEmpty,
      remoteLastUpdate: remoteLastUpdate,
      localLastUpdate: localLastUpdate,
    )) {
      debugPrint('--fetching event heads from Local Data (${cached.length})');
      return cached;
    }

    debugPrint('--fetching event heads from DB');
    try {
      final heads = await _eventHeadDBManager.fetchEventHeads();
      var lastUpdate = remoteLastUpdate;
      if (lastUpdate <= 0) {
        lastUpdate = await _idTracker.tryTouchLastUpdate(IDTrackerDBManager.eventsDoc);
        if (lastUpdate <= 0) {
          lastUpdate = DateTime.now().millisecondsSinceEpoch;
        }
      }
      await persistEventHeadsLocalCache(heads, lastUpdate: lastUpdate);
      return heads;
    } catch (e) {
      debugPrint('EventHeadsRepository: remote fetch failed: $e');
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  Future<List<EventHead>> _readCachedHeads() async {
    final maps = await _localDataManager.readEventHeads();
    final heads = <EventHead>[];
    for (final map in maps) {
      try {
        final id = (map['id'] ?? map['ID'] ?? '').toString();
        if (id.isEmpty) continue;
        heads.add(EventHead.fromMap(id, map));
      } catch (e) {
        debugPrint('EventHeadsRepository: skipping cached head: $e');
      }
    }
    return heads;
  }
}

Future<void> persistEventHeadsLocalCache(List<EventHead> heads, {int? lastUpdate}) async {
  final resolvedLastUpdate =
      lastUpdate ?? await IDTrackerDBManager().fetchLastUpdate(IDTrackerDBManager.eventsDoc);
  final dataManager = LocalDataManager();
  await dataManager.writeEventHeads(heads.map((head) => head.toCacheJson()).toList());
  await dataManager.writeCollectionLastUpdate('events', resolvedLastUpdate);
}
