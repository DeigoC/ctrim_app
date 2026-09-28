import 'package:flutter/foundation.dart';

/// Matches Google Drive share links: `drive.google.com/file/d/{id}`.
final RegExp driveShareLinkRegExp =
    RegExp(r"drive.google.com/file/d/([a-zA-Z0-9_-]+)");

bool isGoogleDriveUrl(String url) => url.contains('drive.google.com');

bool isValidMediaUrl(String url) {
  if (url.trim().isEmpty) return false;
  try {
    final uri = Uri.parse(url.trim());
    return uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority;
  } catch (e) {
    return false;
  }
}

/// True when [url] is ready for Test & Preview (https URL or a Drive share link).
bool isTestableMediaUrl(String url) {
  final trimmed = url.trim();
  return isValidMediaUrl(trimmed) || driveShareLinkRegExp.hasMatch(trimmed);
}

/// A paste (or other multi-character edit) of a usable link should be checked now.
bool shouldAutoTestMediaUrlNow(String previous, String next) {
  if (previous == next || !isTestableMediaUrl(next)) return false;
  return !isSingleCharacterMediaUrlEdit(previous, next);
}

/// A keystroke that already forms a usable link should be checked after a pause.
bool shouldAutoTestMediaUrlAfterPause(String previous, String next) {
  if (!isTestableMediaUrl(next)) return false;
  return isSingleCharacterMediaUrlEdit(previous, next);
}

/// True when [previous] and [next] differ by one inserted, deleted, or replaced
/// character.
bool isSingleCharacterMediaUrlEdit(String previous, String next) {
  if (previous == next) return false;
  if ((previous.length - next.length).abs() > 1) return false;

  if (next.length == previous.length + 1) {
    return _isOneCharacterLonger(previous, next);
  }
  if (previous.length == next.length + 1) {
    return _isOneCharacterLonger(next, previous);
  }

  var differences = 0;
  for (var i = 0; i < previous.length; i++) {
    if (previous[i] != next[i]) differences++;
    if (differences > 1) return false;
  }
  return differences == 1;
}

/// True when [longer] is [shorter] plus exactly one character anywhere.
bool _isOneCharacterLonger(String shorter, String longer) {
  var shorterIndex = 0;
  var longerIndex = 0;
  var skipped = false;
  while (shorterIndex < shorter.length && longerIndex < longer.length) {
    if (shorter[shorterIndex] == longer[longerIndex]) {
      shorterIndex++;
      longerIndex++;
      continue;
    }
    if (skipped) return false;
    skipped = true;
    longerIndex++;
  }
  return shorterIndex == shorter.length;
}

/// Converts Google Drive share links to direct `uc?id=` URLs; otherwise trims.
String sanitiseMediaUrl(String raw) {
  final trimmed = raw.trim();
  final match = driveShareLinkRegExp.firstMatch(trimmed);
  if (match != null) {
    final id = match.group(1)!;
    debugPrint('Link is a GoogleDrive Share link. Parsing now. ID is $id');
    return 'https://drive.google.com/uc?id=$id';
  }
  return trimmed;
}
