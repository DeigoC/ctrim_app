import 'package:flutter/foundation.dart';

/// Matches Google Drive share links: `drive.google.com/file/d/{id}`.
final RegExp driveShareLinkRegExp =
    RegExp(r"drive.google.com/file/d/([a-zA-Z0-9_-]+)");

/// Matches Google Drive folder links: `drive.google.com/drive/folders/{id}`.
final RegExp driveFolderLinkRegExp = RegExp(
  r'drive\.google\.com/drive/(?:u/\d+/)?folders/([a-zA-Z0-9_-]+)',
  caseSensitive: false,
);

/// Bare Drive file/folder ids are typically 25+ URL-safe characters.
final RegExp driveIdRegExp = RegExp(r'^[a-zA-Z0-9_-]{25,}$');

bool isGoogleDriveUrl(String url) => url.contains('drive.google.com');

/// A file from a public Drive folder listing (via embedded folder view HTML).
class DriveFolderEntry {
  const DriveFolderEntry({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.isFolder,
    this.href = '',
  });

  final String id;
  final String name;
  final String mimeType;
  final bool isFolder;
  final String href;

  /// Direct URL stored the same way single-file Drive adds are stored.
  String get directMediaUrl => 'https://drive.google.com/uc?id=$id';

  bool get isImage {
    if (mimeType.toLowerCase().startsWith('image/')) return true;
    return mediaNameLooksLikeImage(name);
  }

  bool get isVideo {
    if (mimeType.toLowerCase().startsWith('video/')) return true;
    return mediaNameLooksLikeVideo(name);
  }

  bool get isImportableMedia => !isFolder && (isImage || isVideo);

  String get mediaType => isVideo ? 'vid' : 'img';
}

bool mediaNameLooksLikeImage(String name) {
  final lower = name.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.bmp') ||
      lower.endsWith('.heic') ||
      lower.endsWith('.heif');
}

bool mediaNameLooksLikeVideo(String name) {
  final lower = name.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.m4v') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.mkv');
}

/// Extracts a Drive folder id from a folder share URL or a bare id.
String? extractDriveFolderId(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final folderMatch = driveFolderLinkRegExp.firstMatch(trimmed);
  if (folderMatch != null) return folderMatch.group(1);

  // Reject file share links so they are not treated as folder ids.
  if (driveShareLinkRegExp.hasMatch(trimmed)) return null;

  if (driveIdRegExp.hasMatch(trimmed)) return trimmed;
  return null;
}

/// Parses Google Drive `embeddedfolderview` HTML into folder entries.
///
/// This is the no-API roundabout: a public folder’s embedded view lists
/// `flip-entry` rows with file ids, titles, and mime types.
List<DriveFolderEntry> parseDriveEmbeddedFolderView(String html) {
  final entryStart = RegExp(
    r'<div class="flip-entry" id="entry-([^"]+)"',
    caseSensitive: false,
  );
  final starts = entryStart.allMatches(html).toList();
  if (starts.isEmpty) return const [];

  final entries = <DriveFolderEntry>[];
  for (var i = 0; i < starts.length; i++) {
    final id = starts[i].group(1)!;
    final end = i + 1 < starts.length ? starts[i + 1].start : html.length;
    final block = html.substring(starts[i].start, end);

    final titleMatch =
        RegExp(r'class="flip-entry-title"[^>]*>([^<]*)<', caseSensitive: false)
            .firstMatch(block);
    final hrefMatch =
        RegExp(r'href="([^"]+)"', caseSensitive: false).firstMatch(block);
    final mimeMatch =
        RegExp(r'/type/([^"]+)"', caseSensitive: false).firstMatch(block);

    final href = hrefMatch?.group(1) ?? '';
    final mimeType = _decodeHtmlUrlComponent(mimeMatch?.group(1) ?? '');
    final isFolder = mimeType == 'application/vnd.google-apps.folder' ||
        href.contains('/folders/');

    entries.add(DriveFolderEntry(
      id: id,
      name: (titleMatch?.group(1) ?? '').trim(),
      mimeType: mimeType,
      isFolder: isFolder,
      href: href,
    ));
  }
  return entries;
}

String _decodeHtmlUrlComponent(String value) {
  if (value.isEmpty || !value.contains('%')) return value;
  try {
    return Uri.decodeComponent(value);
  } catch (_) {
    return value;
  }
}

/// Splits pasted text into candidate media URLs (one per line / whitespace).
List<String> splitMediaUrlList(String raw) {
  return raw
      .split(RegExp(r'[\r\n]+'))
      .expand((line) => line.split(RegExp(r'\s+')))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

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
