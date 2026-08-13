import '../models/user.dart';

/// Line-oriented local cache for the volunteers directory.
///
/// Layout after the header line (`{idTracker}-{appVersion}`):
/// - v1 (8): id, forename, surname, imgSrc, isLeader, isAreaAdmin, location, authID
/// - v2 (9): v1 + tagIDs (comma-separated)
/// - v3 (11): v2 + isPlaceholder + createdByUserID
///
/// Older caches omit placeholder / creator fields; decode defaults those safely.
class UsersLocalCache {
  static const int chunkSizeV1 = 8;
  static const int chunkSizeV2 = 9;
  static const int chunkSizeV3 = 11;

  /// Builds the string written to [LocalDataManager.writeUsersList].
  static String encode({
    required String idTracker,
    required String appVersion,
    required Iterable<User> users,
  }) {
    final buffer = StringBuffer('$idTracker-$appVersion');
    for (final user in users) {
      buffer.write('\n${user.id}');
      buffer.write('\n${user.forname}');
      buffer.write('\n${user.surname}');
      buffer.write('\n${user.imgSrc}');
      buffer.write('\n${user.isLeader ? '1' : '0'}');
      buffer.write('\n${user.isAreaAdmin ? '1' : '0'}');
      buffer.write('\n${user.location}');
      buffer.write('\n${user.authID}');
      buffer.write('\n${user.tagIDs.join(',')}');
      buffer.write('\n${user.isPlaceholder ? '1' : '0'}');
      buffer.write('\n${user.createdByUserID}');
    }
    return buffer.toString();
  }

  /// Parses [lines] from [LocalDataManager.readUsers].
  ///
  /// Returns `null` when the body length does not match a known chunk size
  /// (caller should refetch from Firestore).
  static List<User>? tryDecode(List<String> lines) {
    if (lines.isEmpty) return null;
    final body = lines.length == 1 && lines.first.isEmpty
        ? <String>[]
        : List<String>.from(lines);
    if (body.isNotEmpty && body.first.contains('-')) {
      // Header may already have been removed by the caller; keep flexible.
    }
    final data = body;
    if (data.isEmpty) return <User>[];

    final chunkSize = _detectChunkSize(data.length);
    if (chunkSize == null) return null;

    final result = <User>[];
    final chunks = data.length ~/ chunkSize;
    for (var i = 0; i < chunks; i++) {
      final start = i * chunkSize;
      final entry = data.sublist(start, start + chunkSize);
      result.add(_userFromEntry(entry, chunkSize));
    }
    return result;
  }

  /// Decodes cache body lines (header already stripped).
  static List<User>? decodeBody(List<String> bodyLines) {
    if (bodyLines.isEmpty) return <User>[];
    final chunkSize = _detectChunkSize(bodyLines.length);
    if (chunkSize == null) return null;

    final result = <User>[];
    final chunks = bodyLines.length ~/ chunkSize;
    for (var i = 0; i < chunks; i++) {
      final start = i * chunkSize;
      final entry = bodyLines.sublist(start, start + chunkSize);
      result.add(_userFromEntry(entry, chunkSize));
    }
    return result;
  }

  static int? _detectChunkSize(int dataLength) {
    if (dataLength % chunkSizeV3 == 0) return chunkSizeV3;
    if (dataLength % chunkSizeV2 == 0) return chunkSizeV2;
    if (dataLength % chunkSizeV1 == 0) return chunkSizeV1;
    return null;
  }

  static User _userFromEntry(List<String> entry, int chunkSize) {
    final tagIDs = chunkSize >= chunkSizeV2 && entry.length > 8
        ? entry[8].split(',').where((e) => e.isNotEmpty).toList()
        : <String>[];
    final isPlaceholder = effectiveIsPlaceholder(
      authID: entry[7],
      fallbackIsPlaceholder: chunkSize >= chunkSizeV3
          ? entry[9] == '1'
          // Legacy caches omitted the flag — empty AuthID implies placeholder.
          : entry[7].trim().isEmpty,
    );
    final createdByUserID =
        chunkSize >= chunkSizeV3 ? entry[10] : '';

    return User(
      id: entry[0],
      forname: entry[1],
      surname: entry[2],
      imgSrc: entry[3],
      isLeader: entry[4] == '1',
      isAreaAdmin: entry[5] == '1',
      location: entry[6],
      authID: entry[7],
      tagIDs: tagIDs,
      isPlaceholder: isPlaceholder,
      createdByUserID: createdByUserID,
    );
  }
}

/// Authoritative placeholder flag when persisting a volunteer profile.
///
/// A linked Auth ID means the profile is no longer a temp/placeholder account,
/// regardless of any stale in-memory flag from before Link account.
bool effectiveIsPlaceholder({
  required String authID,
  required bool fallbackIsPlaceholder,
}) {
  if (authID.trim().isNotEmpty) return false;
  return fallbackIsPlaceholder;
}
