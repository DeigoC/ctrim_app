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
    required int lastUpdate,
    required String appVersion,
    required Iterable<User> users,
  }) {
    final buffer = StringBuffer('$lastUpdate-$appVersion');
    for (final user in users) {
      buffer.write('\n${_field(user.id)}');
      buffer.write('\n${_field(user.forname)}');
      buffer.write('\n${_field(user.surname)}');
      buffer.write('\n${_field(user.imgSrc)}');
      buffer.write('\n${user.isLeader ? '1' : '0'}');
      buffer.write('\n${user.isAreaAdmin ? '1' : '0'}');
      buffer.write('\n${_field(user.location)}');
      buffer.write('\n${_field(user.authID)}');
      buffer.write('\n${_field(user.tagIDs.join(','))}');
      buffer.write('\n${user.isPlaceholder ? '1' : '0'}');
      buffer.write('\n${_field(user.createdByUserID)}');
    }
    return buffer.toString();
  }

  static String _field(String value) =>
      value.replaceAll('\r', '').replaceAll('\n', ' ');

  /// Parses [lines] from [LocalDataManager.readUsers].
  ///
  /// Returns `null` when the body length does not match a known chunk size
  /// or every matching layout looks scrambled (caller should refetch).
  static List<User>? tryDecode(List<String> lines) {
    if (lines.isEmpty) return null;
    final body = lines.length == 1 && lines.first.isEmpty
        ? <String>[]
        : List<String>.from(lines);
    if (body.isEmpty) return <User>[];
    return decodeBody(body);
  }

  /// Decodes cache body lines (header already stripped).
  static List<User>? decodeBody(List<String> bodyLines) {
    if (bodyLines.isEmpty) return <User>[];
    final candidates = <int>[
      if (bodyLines.length % chunkSizeV3 == 0) chunkSizeV3,
      if (bodyLines.length % chunkSizeV2 == 0) chunkSizeV2,
      if (bodyLines.length % chunkSizeV1 == 0) chunkSizeV1,
    ];
    if (candidates.isEmpty) return null;

    for (final chunkSize in candidates) {
      final decoded = _decodeWithChunkSize(bodyLines, chunkSize);
      if (!looksScrambled(decoded)) return decoded;
    }
    return null;
  }

  static List<User> _decodeWithChunkSize(
      List<String> bodyLines, int chunkSize) {
    final result = <User>[];
    final chunks = bodyLines.length ~/ chunkSize;
    for (var i = 0; i < chunks; i++) {
      final start = i * chunkSize;
      final entry = bodyLines.sublist(start, start + chunkSize);
      result.add(_userFromEntry(entry, chunkSize));
    }
    return result;
  }

  /// True when fields have rotated (Drive URLs as location, empty ids, etc.).
  static bool looksScrambled(List<User> users) {
    for (final user in users) {
      if (user.id.trim().isEmpty) return true;
      if (user.id.contains(',')) return true;
      if (_looksLikeUrl(user.id) ||
          _looksLikeUrl(user.forname) ||
          _looksLikeUrl(user.location)) {
        return true;
      }
      if (user.location == '0' || user.location == '1') return true;
    }
    return false;
  }

  static bool _looksLikeUrl(String value) {
    final trimmed = value.trim().toLowerCase();
    return trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.contains('drive.google.com');
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
    final createdByUserID = chunkSize >= chunkSizeV3 ? entry[10] : '';

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
