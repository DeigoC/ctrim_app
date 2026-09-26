/// Admin-managed post content tag stored in `post_tags/{tagId}`.
///
/// Optional [streamKind] links the tag to location-aware FCM streams
/// (`{locationSlug}-{streamKind}`). See `docs/post-tags-notification-streams.md`.
/// [imageUrl] is the single cover. There is no gallery.
class PostTag {
  late String _id, _name;
  String? _color;
  String? _streamKind;
  String? _imageUrl;
  late int _displayOrder;
  late bool _isActive;

  PostTag({
    required String id,
    required String name,
    String? color,
    String? streamKind,
    String? imageUrl,
    int displayOrder = 0,
    bool isActive = true,
  }) {
    _id = id;
    _name = name;
    _color = color;
    _streamKind = streamKind;
    _imageUrl = _normalizeImageUrl(imageUrl);
    _displayOrder = displayOrder;
    _isActive = isActive;
  }

  PostTag.fromMap(final String id, final Map<String, dynamic> data)
      : _id = id,
        _name = data['Name'] as String,
        _color = data['Color'] as String?,
        _streamKind = data['StreamKind'] as String?,
        _imageUrl = _normalizeImageUrl(data['ImageUrl'] as String?),
        _displayOrder = (data['DisplayOrder'] as num?)?.toInt() ?? 0,
        _isActive = data['IsActive'] as bool? ?? true;

  Map<String, dynamic> toJson() {
    return {
      'Name': _name,
      'DisplayOrder': _displayOrder,
      'IsActive': _isActive,
      // Empty string clears a previously stored cover on update.
      'ImageUrl': _imageUrl ?? '',
      if (_color != null && _color!.isNotEmpty) 'Color': _color,
      if (_streamKind != null && _streamKind!.isNotEmpty)
        'StreamKind': _streamKind,
    };
  }

  static String? _normalizeImageUrl(final String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  String get id => _id;
  String get name => _name;
  String? get color => _color;
  String? get streamKind => _streamKind;

  /// Single cover, shared by every location. Empty values stay null.
  String? get imageUrl => _imageUrl;

  int get displayOrder => _displayOrder;
  bool get isActive => _isActive;
  bool get isNotifiable => _streamKind != null && _streamKind!.isNotEmpty;

  void setName(final String name) => _name = name;
  void setColor(final String? color) => _color = color;
  void setStreamKind(final String? streamKind) => _streamKind = streamKind;
  void setImageUrl(final String? imageUrl) =>
      _imageUrl = _normalizeImageUrl(imageUrl);
  void setDisplayOrder(final int order) => _displayOrder = order;
  void setActive(final bool active) => _isActive = active;
}
