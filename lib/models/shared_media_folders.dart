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

/// Services or Cell Groups. Each group has its own month pair.
enum SharedMediaFolderKind {
  service('Service', 'Services'),
  cellGroup('CellGroup', 'Cell Groups');

  const SharedMediaFolderKind(this.firestoreKey, this.label);

  final String firestoreKey;
  final String label;

  /// Services first: that is where a document saved before groups still lands.
  static const List<SharedMediaFolderKind> displayOrder = [
    service,
    cellGroup,
  ];
}

/// This month’s folder and the previous month only, for one group.
///
/// [startNewMonth] copies the current folder into the previous slot and
/// clears the current one, so the month before last is no longer offered.
class SharedMediaFolderPair {
  SharedMediaFolderPair({
    String currentLabel = '',
    String currentFolderUrl = '',
    String previousLabel = '',
    String previousFolderUrl = '',
  })  : currentLabel = currentLabel.trim(),
        currentFolderUrl = currentFolderUrl.trim(),
        previousLabel = previousLabel.trim(),
        previousFolderUrl = previousFolderUrl.trim();

  static final SharedMediaFolderPair empty = SharedMediaFolderPair();

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
  static SharedMediaFolderPair normalized({
    required String currentLabel,
    required String currentFolderUrl,
    required String previousLabel,
    required String previousFolderUrl,
  }) {
    return SharedMediaFolderPair(
      currentLabel: _labelFor(currentLabel, currentFolderUrl),
      currentFolderUrl: _urlFor(currentFolderUrl),
      previousLabel: _labelFor(previousLabel, previousFolderUrl),
      previousFolderUrl: _urlFor(previousFolderUrl),
    );
  }

  SharedMediaFolderPair normalize() {
    return SharedMediaFolderPair.normalized(
      currentLabel: currentLabel,
      currentFolderUrl: currentFolderUrl,
      previousLabel: previousLabel,
      previousFolderUrl: previousFolderUrl,
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
  SharedMediaFolderPair startNewMonth() {
    return SharedMediaFolderPair(
      previousLabel: currentLabel,
      previousFolderUrl: currentFolderUrl,
    );
  }

  factory SharedMediaFolderPair.fromMap(Map<String, dynamic> data) {
    return SharedMediaFolderPair(
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

/// Services and Cell Groups month folders.
///
/// Stored at `shared_media/folders`. A document written before groups
/// (flat `Current*` / `Previous*` fields only) is read as [service].
/// [toJson] still writes those flat fields from Services so an older
/// install keeps showing that group.
class SharedMediaFolders {
  SharedMediaFolders({
    SharedMediaFolderPair? service,
    SharedMediaFolderPair? cellGroup,
  })  : service = service ?? SharedMediaFolderPair.empty,
        cellGroup = cellGroup ?? SharedMediaFolderPair.empty;

  static final SharedMediaFolders empty = SharedMediaFolders();

  final SharedMediaFolderPair service;
  final SharedMediaFolderPair cellGroup;

  SharedMediaFolderPair pairFor(SharedMediaFolderKind kind) {
    switch (kind) {
      case SharedMediaFolderKind.service:
        return service;
      case SharedMediaFolderKind.cellGroup:
        return cellGroup;
    }
  }

  SharedMediaFolders replacing(
    SharedMediaFolderKind kind,
    SharedMediaFolderPair pair,
  ) {
    switch (kind) {
      case SharedMediaFolderKind.service:
        return SharedMediaFolders(service: pair, cellGroup: cellGroup);
      case SharedMediaFolderKind.cellGroup:
        return SharedMediaFolders(service: service, cellGroup: pair);
    }
  }

  factory SharedMediaFolders.fromMap(Map<String, dynamic> data) {
    final hasNested = data['Service'] is Map || data['CellGroup'] is Map;
    if (!hasNested) {
      return SharedMediaFolders(service: SharedMediaFolderPair.fromMap(data));
    }
    return SharedMediaFolders(
      service: _pairFromField(data['Service']),
      cellGroup: _pairFromField(data['CellGroup']),
    );
  }

  static SharedMediaFolderPair _pairFromField(dynamic raw) {
    if (raw is! Map) return SharedMediaFolderPair.empty;
    return SharedMediaFolderPair.fromMap(Map<String, dynamic>.from(raw));
  }

  Map<String, dynamic> toJson() {
    final serviceJson = service.toJson();
    return {
      'Service': serviceJson,
      'CellGroup': cellGroup.toJson(),
      ...serviceJson,
    };
  }
}
