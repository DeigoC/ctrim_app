import 'dart:collection';

/// Admin-managed volunteer tag definition stored in `user_tags/{tagId}`.
class UserTag {
  late String _id, _name;
  String? _color;
  late int _displayOrder;
  late bool _isActive;
  late bool _visibleToGuests;
  String? _description;
  String? _imageUrl;
  late Map<String, List<String>> _headsByLocation;
  late Map<String, List<String>> _galleryByLocation;

  /// Editor cap for the short public description. Longer copy belongs on the
  /// tag detail page when that grows.
  static const int descriptionMaxLength = 400;

  /// Photos stored per church location. Matches the cell-group gallery cap.
  static const int maxGalleryImages = 8;

  UserTag({
    required String id,
    required String name,
    String? color,
    int displayOrder = 0,
    bool isActive = true,
    bool visibleToGuests = true,
    String? description,
    String? imageUrl,
    Map<String, List<String>> headsByLocation = const {},
    Map<String, List<String>> galleryByLocation = const {},
  }) {
    _id = id;
    _name = name;
    _color = color;
    _displayOrder = displayOrder;
    _isActive = isActive;
    _visibleToGuests = visibleToGuests;
    _description = _normalizeDescription(description);
    _imageUrl = _normalizeImageUrl(imageUrl);
    _headsByLocation = _copyLocationMap(headsByLocation);
    _galleryByLocation =
        _copyLocationMap(galleryByLocation, cap: maxGalleryImages);
  }

  UserTag.fromMap(final String id, final Map<String, dynamic> data)
      : _id = id,
        _name = data['Name'] as String,
        _color = data['Color'] as String?,
        _displayOrder = (data['DisplayOrder'] as num?)?.toInt() ?? 0,
        _isActive = data['IsActive'] as bool? ?? true,
        _visibleToGuests = data['VisibleToGuests'] as bool? ?? true,
        _description = _normalizeDescription(data['Description'] as String?),
        _imageUrl = _normalizeImageUrl(data['ImageUrl'] as String?),
        _headsByLocation = _parseLocationMap(data['HeadsByLocation']),
        _galleryByLocation = _parseLocationMap(
          data['GalleryByLocation'],
          cap: maxGalleryImages,
        );

  Map<String, dynamic> toJson() {
    return {
      'Name': _name,
      'DisplayOrder': _displayOrder,
      'IsActive': _isActive,
      'VisibleToGuests': _visibleToGuests,
      'Description': _description ?? '',
      'ImageUrl': _imageUrl ?? '',
      'HeadsByLocation': _locationMapToJson(_headsByLocation),
      'GalleryByLocation': _locationMapToJson(_galleryByLocation),
      if (_color != null && _color!.isNotEmpty) 'Color': _color,
    };
  }

  static String? _normalizeDescription(final String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  static String? _normalizeImageUrl(final String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  static Map<String, List<String>> _parseLocationMap(
    final dynamic raw, {
    int? cap,
  }) {
    if (raw is! Map) return {};
    final parsed = <String, List<String>>{};
    for (final entry in raw.entries) {
      parsed[entry.key.toString()] = _rawStrings(entry.value);
    }
    return _copyLocationMap(parsed, cap: cap);
  }

  static List<String> _rawStrings(final dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((item) => item.toString()).toList();
  }

  /// Drops blank keys and blank values, keeps first-seen order, and applies
  /// [cap] per location. Locations left with nothing are omitted.
  static Map<String, List<String>> _copyLocationMap(
    final Map<String, List<String>> raw, {
    int? cap,
  }) {
    final result = <String, List<String>>{};
    for (final entry in raw.entries) {
      final locationId = entry.key.toString().trim();
      if (locationId.isEmpty) continue;
      final values = _normalizeValues(entry.value, cap: cap);
      if (values.isEmpty) continue;
      result[locationId] = values;
    }
    return result;
  }

  static List<String> _normalizeValues(
    final List<String> raw, {
    int? cap,
  }) {
    final result = <String>[];
    final seen = <String>{};
    for (final item in raw) {
      final value = item.trim();
      if (value.isEmpty || !seen.add(value)) continue;
      result.add(value);
      if (cap != null && result.length >= cap) break;
    }
    return result;
  }

  static Map<String, List<String>> _locationMapToJson(
    final Map<String, List<String>> source,
  ) {
    return {
      for (final entry in source.entries)
        if (entry.value.isNotEmpty) entry.key: List<String>.from(entry.value),
    };
  }

  String get id => _id;
  String get name => _name;
  String? get color => _color;
  int get displayOrder => _displayOrder;
  bool get isActive => _isActive;

  /// When false, guests do not see this label. Missing Firestore values stay true.
  bool get visibleToGuests => _visibleToGuests;

  /// Short public explanation of the team. Empty values stay null.
  String? get description => _description;

  /// Single main graphic, shared by every location. Empty values stay null.
  String? get imageUrl => _imageUrl;

  /// Department heads keyed by `user_locations` document id.
  Map<String, List<String>> get headsByLocation => UnmodifiableMapView({
        for (final entry in _headsByLocation.entries)
          entry.key: UnmodifiableListView(entry.value),
      });

  /// Photo URLs keyed by `user_locations` document id.
  Map<String, List<String>> get galleryByLocation => UnmodifiableMapView({
        for (final entry in _galleryByLocation.entries)
          entry.key: UnmodifiableListView(entry.value),
      });

  /// Head user ids for [locationId], in stored order. Unknown locations are empty.
  List<String> headsForLocation(final String locationId) {
    final ids = _headsByLocation[locationId.trim()];
    if (ids == null) return const [];
    return UnmodifiableListView(ids);
  }

  /// Gallery URLs for [locationId], in stored order. Unknown locations are empty.
  List<String> galleryForLocation(final String locationId) {
    final urls = _galleryByLocation[locationId.trim()];
    if (urls == null) return const [];
    return UnmodifiableListView(urls);
  }

  void setName(final String name) => _name = name;
  void setColor(final String? color) => _color = color;
  void setDisplayOrder(final int order) => _displayOrder = order;
  void setActive(final bool active) => _isActive = active;
  void setVisibleToGuests(final bool visible) => _visibleToGuests = visible;
  void setDescription(final String? description) =>
      _description = _normalizeDescription(description);
  void setImageUrl(final String? imageUrl) =>
      _imageUrl = _normalizeImageUrl(imageUrl);

  /// Replaces heads at [locationId]. An empty list removes that location.
  void setHeadsForLocation(
      final String locationId, final List<String> userIds) {
    _setLocationValues(
      _headsByLocation,
      locationId,
      userIds,
    );
  }

  /// Replaces photos at [locationId]. An empty list removes that location.
  /// Values beyond [maxGalleryImages] are dropped.
  void setGalleryForLocation(
    final String locationId,
    final List<String> imageUrls,
  ) {
    _setLocationValues(
      _galleryByLocation,
      locationId,
      imageUrls,
      cap: maxGalleryImages,
    );
  }

  void _setLocationValues(
    final Map<String, List<String>> target,
    final String locationId,
    final List<String> values, {
    int? cap,
  }) {
    final key = locationId.trim();
    if (key.isEmpty) return;
    final normalized = _normalizeValues(values, cap: cap);
    if (normalized.isEmpty) {
      target.remove(key);
    } else {
      target[key] = normalized;
    }
  }
}
