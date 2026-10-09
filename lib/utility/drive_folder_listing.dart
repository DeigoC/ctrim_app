import 'package:http/http.dart' as http;

import '../pages/events/add_media_drive_helpers.dart';
import 'network_image_helper.dart';

/// Browser-like UA so Drive’s embedded folder view returns the full listing.
const String kDriveFolderListingUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

/// Public Drive folder listing via the embedded folder view HTML.
///
/// No Google API key or OAuth: Drive renders `flip-entry` rows for folders
/// shared as “Anyone with the link”. On Flutter web the existing CORS image
/// proxy is reused to fetch that HTML.
class DriveFolderListing {
  DriveFolderListing({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// URL Drive serves for a public folder’s embeddable file list.
  static String embeddedFolderViewUrl(String folderId) =>
      'https://drive.google.com/embeddedfolderview?id=$folderId';

  /// Fetches and parses media-capable entries from a public Drive folder.
  Future<List<DriveFolderEntry>> listPublicFolder(String folderId) async {
    final html = await fetchEmbeddedFolderHtml(folderId);
    if (html.contains('ServiceLogin') &&
        !html.contains('class="flip-entry"')) {
      throw DriveFolderListingException(
        'This folder is not public. Share it as “Anyone with the link” '
        '(Viewer), then try again.',
      );
    }

    final entries = parseDriveEmbeddedFolderView(html);
    if (entries.isEmpty) {
      throw DriveFolderListingException(
        'No files found in that folder. Confirm the folder link is public '
        'and that it contains files (not only subfolders).',
      );
    }
    return entries;
  }

  Future<String> fetchEmbeddedFolderHtml(String folderId) async {
    final rawUrl = embeddedFolderViewUrl(folderId);
    // On web, reuse the Drive CORS proxy already used for images.
    final fetchUrl = NetworkImageHelper.getImageUrl(rawUrl);
    final response = await _httpClient.get(
      Uri.parse(fetchUrl),
      headers: {'User-Agent': kDriveFolderListingUserAgent},
    );

    if (response.statusCode == 404) {
      throw DriveFolderListingException(
        'Folder not found. Check the folder link and that it is shared '
        'as “Anyone with the link”.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DriveFolderListingException(
        'Could not read the folder (HTTP ${response.statusCode}).',
      );
    }
    return response.body;
  }
}

class DriveFolderListingException implements Exception {
  DriveFolderListingException(this.message);
  final String message;

  @override
  String toString() => message;
}
