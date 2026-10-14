import '../pages/events/add_media_drive_helpers.dart';

/// One public Google Drive folder the gallery can list.
class SharedMediaFolder {
  const SharedMediaFolder({
    required this.label,
    required this.folderUrl,
    required this.folderId,
  });

  final String label;
  final String folderUrl;
  final String folderId;

  /// Link opened in the Drive app. A bare folder id becomes a folder URL.
  String get openUrl {
    final trimmed = folderUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://drive.google.com/drive/folders/$folderId';
  }

  String displayLabel(String fallback) {
    final trimmed = label.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}

/// This month’s shared media folder, and the previous month only.
///
/// Stored at `shared_media/folders`. [startNewMonth] copies the current
/// folder into the previous slot and clears the current one, so the month
/// before last is no longer offered in the app.
class SharedMediaFolders {
  SharedMediaFolders({
    String currentLabel = '',
    String currentFolderUrl = '',
    String previousLabel = '',
    String previousFolderUrl = '',
  })  : currentLabel = currentLabel.trim(),
        currentFolderUrl = currentFolderUrl.trim(),
        previousLabel = previousLabel.trim(),
        previousFolderUrl = previousFolderUrl.trim();

  static final SharedMediaFolders empty = SharedMediaFolders();

  final String currentLabel;
  final String currentFolderUrl;
  final String previousLabel;
  final String previousFolderUrl;

  SharedMediaFolder? get current => _slot(currentLabel, currentFolderUrl);

  SharedMediaFolder? get previous => _slot(previousLabel, previousFolderUrl);

  bool get canStartNewMonth => current != null;

  static SharedMediaFolder? _slot(String label, String url) {
    final folderId = extractDriveFolderId(url);
    if (folderId == null) return null;
    return SharedMediaFolder(
      label: label,
      folderUrl: url,
      folderId: folderId,
    );
  }

  /// Null when [raw] is empty or a Drive folder link.
  static String? validateFolderUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (extractDriveFolderId(trimmed) == null) {
      return 'Paste a Google Drive folder link (…/drive/folders/…).';
    }
    return null;
  }

  /// Drops a label when its URL is not a Drive folder link.
  static SharedMediaFolders normalized({
    required String currentLabel,
    required String currentFolderUrl,
    required String previousLabel,
    required String previousFolderUrl,
  }) {
    return SharedMediaFolders(
      currentLabel: _labelFor(currentLabel, currentFolderUrl),
      currentFolderUrl: _urlFor(currentFolderUrl),
      previousLabel: _labelFor(previousLabel, previousFolderUrl),
      previousFolderUrl: _urlFor(previousFolderUrl),
    );
  }

  static String _urlFor(String raw) {
    final trimmed = raw.trim();
    return extractDriveFolderId(trimmed) == null ? '' : trimmed;
  }

  static String _labelFor(String label, String url) {
    if (extractDriveFolderId(url.trim()) == null) return '';
    return label.trim();
  }

  /// The current folder becomes last month. The month before that is dropped.
  SharedMediaFolders startNewMonth() {
    return SharedMediaFolders(
      previousLabel: currentLabel,
      previousFolderUrl: currentFolderUrl,
    );
  }

  factory SharedMediaFolders.fromMap(Map<String, dynamic> data) {
    return SharedMediaFolders(
      currentLabel: data['CurrentLabel'] as String? ?? '',
      currentFolderUrl: data['CurrentFolderUrl'] as String? ?? '',
      previousLabel: data['PreviousLabel'] as String? ?? '',
      previousFolderUrl: data['PreviousFolderUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CurrentLabel': currentLabel,
      'CurrentFolderUrl': currentFolderUrl,
      'PreviousLabel': previousLabel,
      'PreviousFolderUrl': previousFolderUrl,
    };
  }
}
