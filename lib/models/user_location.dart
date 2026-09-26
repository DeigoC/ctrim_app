import 'dart:collection';

/// Admin-managed volunteer location definition stored in `user_locations/{locationId}`.
///
/// Users store the location **name** on `users/{uid}.Location` (legacy string field).
/// [media] is the photo gallery. [keyGraphicSrc] is the cover, and must be one
/// of those image srcs.
class UserLocation {
  late String _id, _name;
  late int _displayOrder;
  late bool _isActive;
  late List<Map<String, dynamic>> _media;
  String? _keyGraphicSrc;

  static const int maxMediaItems = 8;

  UserLocation({
    required String id,
    required String name,
    int displayOrder = 0,
    bool isActive = true,
    List<Map<String, dynamic>> media = const [],
    String? keyGraphicSrc,
  }) {
    _id = id;
    _name = name;
    _displayOrder = displayOrder;
    _isActive = isActive;
    _media = _copyMedia(media);
    _keyGraphicSrc = keyGraphicSrc;
    _syncKeyGraphicWithMedia();
  }

  UserLocation.fromMap(final String id, final Map<String, dynamic> data)
      : _id = id,
        _name = data['Name'] as String,
        _displayOrder = (data['DisplayOrder'] as num?)?.toInt() ?? 0,
        _isActive = data['IsActive'] as bool? ?? true,
        _media = _parseMedia(data['Media']),
        _keyGraphicSrc = data['KeyGraphicSrc'] as String? {
    _syncKeyGraphicWithMedia();
  }

  static List<Map<String, dynamic>> _parseMedia(final dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    final results = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final src = (map['src'] as String?) ?? '';
      if (src.isEmpty) continue;
      results.add({
        'title': map['title'] ?? '',
        'src': src,
        'type': map['type'] ?? 'img',
        'thumbnailSrc': map['thumbnailSrc'],
      });
    }
    return results;
  }

  static List<Map<String, dynamic>> _copyMedia(
    final List<Map<String, dynamic>> media,
  ) {
    return media.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'Name': _name,
      'DisplayOrder': _displayOrder,
      'IsActive': _isActive,
      'Media': _media.map((e) => Map<String, dynamic>.from(e)).toList(),
      'KeyGraphicSrc': _keyGraphicSrc,
    };
  }

  String get id => _id;
  String get name => _name;
  int get displayOrder => _displayOrder;
  bool get isActive => _isActive;
  List<Map<String, dynamic>> get media => UnmodifiableListView(_media);
  String? get keyGraphicSrc => _keyGraphicSrc;
  bool get hasKeyGraphic =>
      _keyGraphicSrc != null && _keyGraphicSrc!.isNotEmpty;

  void setName(final String name) => _name = name;
  void setDisplayOrder(final int order) => _displayOrder = order;
  void setActive(final bool active) => _isActive = active;

  void setMedia(final List<Map<String, dynamic>> media) {
    _media = _copyMedia(media);
    _syncKeyGraphicWithMedia();
  }

  /// Returns false if at capacity, [src] is empty, or [src] is already present.
  bool addMediaItem(final Map<String, dynamic> item) {
    final src = (item['src'] as String?) ?? '';
    if (src.isEmpty) return false;
    if (_media.length >= maxMediaItems) return false;
    if (_media.any((e) => e['src'] == src)) return false;
    _media.add({
      'title': item['title'] ?? '',
      'src': src,
      'type': item['type'] ?? 'img',
      'thumbnailSrc': item['thumbnailSrc'],
    });
    return true;
  }

  void removeMediaItem(final String src) {
    _media.removeWhere((e) => e['src'] == src);
    if (_keyGraphicSrc == src) _keyGraphicSrc = null;
  }

  /// Sets the cover. [src] must already be in [media], or null to clear.
  bool setKeyGraphicSrc(final String? src) {
    if (src == null || src.isEmpty) {
      _keyGraphicSrc = null;
      return true;
    }
    if (!_media.any((e) => e['src'] == src)) return false;
    _keyGraphicSrc = src;
    return true;
  }

  void _syncKeyGraphicWithMedia() {
    if (_keyGraphicSrc == null || _keyGraphicSrc!.isEmpty) {
      _keyGraphicSrc = null;
      return;
    }
    if (!_media.any((e) => e['src'] == _keyGraphicSrc)) {
      _keyGraphicSrc = null;
    }
  }
}
