import 'package:package_info_plus/package_info_plus.dart';

import '../../firebase/db_managers/id_tracker.dart';
import '../../models/user.dart';
import 'local_data_manager.dart';
import 'users_local_cache.dart';

/// Rewrites the on-device volunteers cache so the next cold start matches
/// in-memory / Firestore edits (link Auth, area admin, names, etc.).
Future<void> persistUsersLocalCache(Iterable<User> users,
    {int? lastUpdate}) async {
  final packageInfo = await PackageInfo.fromPlatform();
  final resolvedLastUpdate = lastUpdate ??
      await IDTrackerDBManager().fetchLastUpdate(IDTrackerDBManager.usersDoc);
  final content = UsersLocalCache.encode(
    lastUpdate: resolvedLastUpdate,
    appVersion: packageInfo.version,
    users: users,
  );
  final dataManager = LocalDataManager();
  await dataManager.writeUsersList(content);
  await dataManager.writeCollectionLastUpdate('users', resolvedLastUpdate);
  await dataManager.writeLastUsersFetch();
}
