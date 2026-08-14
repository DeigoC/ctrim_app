/// Shared skip-remote decision for lastUpdate-backed Hive caches.
bool shouldUseLocalCollectionCache({
  required bool forceRefresh,
  required bool hasCachedRecords,
  required int remoteLastUpdate,
  required int localLastUpdate,
  String? cachedAppVersion,
  String? currentAppVersion,
}) {
  if (forceRefresh || !hasCachedRecords || remoteLastUpdate <= 0) {
    return false;
  }
  if (cachedAppVersion != null &&
      currentAppVersion != null &&
      cachedAppVersion != currentAppVersion) {
    return false;
  }
  return remoteLastUpdate == localLastUpdate;
}
