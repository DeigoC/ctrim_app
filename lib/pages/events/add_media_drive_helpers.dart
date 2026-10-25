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
    this.modifiedLabel = '',
    this.modified,
  });

  final String id;
  final String name;
  final String mimeType;
  final bool isFolder;
  final String href;

  /// Date text from the public folder page, such as `22 Sept` or `15/10/2024`.
  final String modifiedLabel;

  /// Parsed [modifiedLabel]. Null when the page omitted a date or it did not parse.
  final DateTime? modified;

  /// Short caption for the picker row. Empty when no date was parsed.
  String get modifiedCaption {
    final when = modified;
    if (when == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    final date = '${when.day} ${months[when.month - 1]} ${when.year}';
    if (when.hour == 0 && when.minute == 0) return date;
    final hour = when.hour.toString().padLeft(2, '0');
    final minute = when.minute.toString().padLeft(2, '0');
    return '$date, $hour:$minute';
  }

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
    final modifiedLabel = RegExp(
          r'class="flip-entry-last-modified"[^>]*>\s*<div>([^<]*)',
          caseSensitive: false,
        ).firstMatch(block)?.group(1)?.trim() ??
        '';

    entries.add(DriveFolderEntry(
      id: id,
      name: (titleMatch?.group(1) ?? '').trim(),
      mimeType: mimeType,
      isFolder: isFolder,
      href: href,
      modifiedLabel: modifiedLabel,
      modified: parseDriveModifiedLabel(modifiedLabel),
    ));
  }
  return entries;
}

/// Reads the date text Drive prints in a public folder listing.
///
/// The listing is requested with `hl=en-GB`. Older files are `d/M/yyyy`
/// (`15/10/2024`). Files from the current year omit the year (`22 Sept`,
/// `9 Feb`). A clock time (`14:30` or `2:30 pm`) means today. Two-digit
/// US dates (`8/25/25`, `Sep 22`) are accepted when `hl` is ignored.
DateTime? parseDriveModifiedLabel(String raw, {DateTime? now}) {
  final label = raw.trim();
  if (label.isEmpty) return null;
  final clock = now ?? DateTime.now();

  final time = RegExp(
    r'^(\d{1,2}):(\d{2})(?:\s*([ap]m))?$',
    caseSensitive: false,
  ).firstMatch(label);
  if (time != null) {
    var hour = int.parse(time.group(1)!);
    final minute = int.parse(time.group(2)!);
    final ampm = time.group(3)?.toLowerCase();
    if (ampm == 'pm' && hour < 12) hour += 12;
    if (ampm == 'am' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return DateTime(clock.year, clock.month, clock.day, hour, minute);
  }

  final numeric =
      RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2}|\d{4})$').firstMatch(label);
  if (numeric != null) {
    final first = int.parse(numeric.group(1)!);
    final second = int.parse(numeric.group(2)!);
    final yearText = numeric.group(3)!;
    var year = int.parse(yearText);
    if (year < 100) year += 2000;
    if (first > 12 && second > 12) return null;

    final int day;
    final int month;
    if (first > 12) {
      day = first;
      month = second;
    } else if (second > 12) {
      month = first;
      day = second;
    } else if (yearText.length == 4) {
      // en-GB prints a four-digit year as day/month.
      day = first;
      month = second;
    } else {
      // A two-digit year is the US listing: month/day.
      month = first;
      day = second;
    }
    return _driveDate(year, month, day);
  }

  final dayMonth = RegExp(
    r'^(\d{1,2})\s+([A-Za-z]+)(?:\s+(\d{4}))?$',
  ).firstMatch(label);
  if (dayMonth != null) {
    final month = _driveMonthNumber(dayMonth.group(2)!);
    if (month == null) return null;
    final year = int.tryParse(dayMonth.group(3) ?? '') ?? clock.year;
    return _driveDate(year, month, int.parse(dayMonth.group(1)!));
  }

  final monthDay = RegExp(
    r'^([A-Za-z]+)\s+(\d{1,2})(?:,)?(?:\s+(\d{4}))?$',
  ).firstMatch(label);
  if (monthDay != null) {
    final month = _driveMonthNumber(monthDay.group(1)!);
    if (month == null) return null;
    final year = int.tryParse(monthDay.group(3) ?? '') ?? clock.year;
    return _driveDate(year, month, int.parse(monthDay.group(2)!));
  }

  return null;
}

/// Newest modified files first. Entries with no date stay in their original
/// order, after every dated file. Ties keep the listing order.
List<DriveFolderEntry> sortDriveFolderEntriesNewestFirst(
  List<DriveFolderEntry> entries,
) {
  final indexed = entries.asMap().entries.toList();
  indexed.sort((a, b) {
    final aModified = a.value.modified;
    final bModified = b.value.modified;
    if (aModified == null && bModified == null) return a.key.compareTo(b.key);
    if (aModified == null) return 1;
    if (bModified == null) return -1;
    final byDate = bModified.compareTo(aModified);
    if (byDate != 0) return byDate;
    return a.key.compareTo(b.key);
  });
  return [for (final entry in indexed) entry.value];
}

DateTime? _driveDate(int year, int month, int day,
    [int hour = 0, int minute = 0]) {
  if (month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31 ||
      hour > 23 ||
      minute > 59) {
    return null;
  }
  final result = DateTime(year, month, day, hour, minute);
  if (result.year != year || result.month != month || result.day != day) {
    return null;
  }
  return result;
}

int? _driveMonthNumber(String raw) {
  return switch (raw.toLowerCase()) {
    'jan' || 'january' => 1,
    'feb' || 'february' => 2,
    'mar' || 'march' => 3,
    'apr' || 'april' => 4,
    'may' => 5,
    'jun' || 'june' => 6,
    'jul' || 'july' => 7,
    'aug' || 'august' => 8,
    'sep' || 'sept' || 'september' => 9,
    'oct' || 'october' => 10,
    'nov' || 'november' => 11,
    'dec' || 'december' => 12,
    _ => null,
  };
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
