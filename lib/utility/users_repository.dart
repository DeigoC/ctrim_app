import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../firebase/db_managers/id_tracker.dart';
import '../firebase/db_managers/user_db_manager.dart';
import '../models/user.dart';
import 'collection_cache_policy.dart';
import 'local_data_manager.dart';
import 'persist_users_local_cache.dart';
import 'users_local_cache.dart';

class UsersLoadResult {
  const UsersLoadResult({required this.users, required this.fromCache});

  final List<User> users;
  final bool fromCache;
}

/// Loads volunteer profiles from Hive when `id_tracker/users.lastUpdate` matches.
class UsersRepository {
  UsersRepository({
    LocalDataManager? localDataManager,
    UserDBManager? userDBManager,
    IDTrackerDBManager? idTracker,
  })  : _localDataManager = localDataManager ?? LocalDataManager(),
        _userDBManager = userDBManager ?? UserDBManager(),
        _idTracker = idTracker ?? IDTrackerDBManager();

  final LocalDataManager _localDataManager;
  final UserDBManager _userDBManager;
  final IDTrackerDBManager _idTracker;

  Future<List<User>> fetchUsers({bool forceRefresh = false}) async {
    final result = await fetchUsersWithMeta(forceRefresh: forceRefresh);
    return result.users;
  }

  Future<UsersLoadResult> fetchUsersWithMeta({bool forceRefresh = false}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final cached = await _readCachedUsers();

    int remoteLastUpdate;
    try {
      remoteLastUpdate = await _idTracker.fetchLastUpdate(IDTrackerDBManager.usersDoc);
    } catch (e) {
      debugPrint('UsersRepository: lastUpdate read failed, using cache if any: $e');
      if (cached.users.isNotEmpty) {
        return UsersLoadResult(users: cached.users, fromCache: true);
      }
      rethrow;
    }

    final localLastUpdate = await _localDataManager.readCollectionLastUpdate('users');
    if (shouldUseLocalCollectionCache(
      forceRefresh: forceRefresh,
      hasCachedRecords: cached.users.isNotEmpty,
      remoteLastUpdate: remoteLastUpdate,
      localLastUpdate: localLastUpdate,
      cachedAppVersion: cached.appVersion,
      currentAppVersion: currentVersion,
    )) {
      debugPrint('--fetching users from Local Data (${cached.users.length})');
      return UsersLoadResult(users: cached.users, fromCache: true);
    }

    debugPrint('--fetching users from DB');
    try {
      final allUsers = await _userDBManager.fetchAllUsers();
      var lastUpdate = remoteLastUpdate;
      if (lastUpdate <= 0) {
        lastUpdate = await _idTracker.tryTouchLastUpdate(IDTrackerDBManager.usersDoc);
        if (lastUpdate <= 0) {
          lastUpdate = DateTime.now().millisecondsSinceEpoch;
        }
      }
      await persistUsersLocalCache(allUsers, lastUpdate: lastUpdate);
      return UsersLoadResult(users: allUsers, fromCache: false);
    } catch (e) {
      debugPrint('UsersRepository: remote fetch failed: $e');
      if (cached.users.isNotEmpty) {
        return UsersLoadResult(users: cached.users, fromCache: true);
      }
      rethrow;
    }
  }

  Future<({List<User> users, String appVersion})> _readCachedUsers() async {
    final usersData = await _localDataManager.readUsers();
    if (usersData.isEmpty) {
      return (users: <User>[], appVersion: '');
    }
    final header = usersData.first.split('-');
    if (header.length != 2) {
      return (users: <User>[], appVersion: '');
    }
    final decoded = UsersLocalCache.decodeBody(usersData.sublist(1));
    if (decoded == null) {
      return (users: <User>[], appVersion: header[1]);
    }
    return (users: decoded, appVersion: header[1]);
  }
}
