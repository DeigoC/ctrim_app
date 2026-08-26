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
