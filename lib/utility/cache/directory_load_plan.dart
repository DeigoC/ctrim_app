/// How a screen should treat a Hive-backed catalogue or information section.
enum DirectoryLoadPlan {
  /// Session already compared the watermark. Read Hive only.
  useLocal,

  /// Paint Hive now and compare the watermark in the background.
  useLocalThenRevalidate,

  /// No usable local snapshot, or the caller asked for a fresh download.
  download,
}

/// Decides whether opening a record waits on Firestore.
///
/// [hasCachedRecords] is true when Hive has rows or a previous snapshot was
/// stored (including a legitimately empty collection whose watermark was saved).
DirectoryLoadPlan planDirectoryLoad({
  required bool forceRefresh,
  required bool hasCachedRecords,
  required bool sessionValidated,
}) {
  if (forceRefresh || !hasCachedRecords) {
    return DirectoryLoadPlan.download;
  }
  if (sessionValidated) {
    return DirectoryLoadPlan.useLocal;
  }
  return DirectoryLoadPlan.useLocalThenRevalidate;
}
