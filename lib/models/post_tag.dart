/// Admin-managed post content tag stored in `post_tags/{tagId}`.
///
/// Optional [streamKind] links the tag to location-aware FCM streams
/// (`{locationSlug}-{streamKind}`). See `docs/post-tags-notification-streams.md`.
class PostTag {
  late String _id, _name;
  String? _color;
  String? _streamKind;
  late int _displayOrder;
  late bool _isActive;

  PostTag({
    required String id,
    required String name,
    String? color,
    String? streamKind,
    int displayOrder = 0,
    bool isActive = true,
  }) {
    _id = id;
    _name = name;
    _color = color;
    _streamKind = streamKind;
    _displayOrder = displayOrder;
    _isActive = isActive;
  }

  PostTag.fromMap(final String id, final Map<String, dynamic> data)
      : _id = id,
        _name = data['Name'] as String,
        _color = data['Color'] as String?,
        _streamKind = data['StreamKind'] as String?,
        _displayOrder = (data['DisplayOrder'] as num?)?.toInt() ?? 0,
        _isActive = data['IsActive'] as bool? ?? true;

  Map<String, dynamic> toJson() {
    return {
      'Name': _name,
      'DisplayOrder': _displayOrder,
      'IsActive': _isActive,
      if (_color != null && _color!.isNotEmpty) 'Color': _color,
      if (_streamKind != null && _streamKind!.isNotEmpty) 'StreamKind': _streamKind,
    };
  }

  String get id => _id;
  String get name => _name;
  String? get color => _color;
  String? get streamKind => _streamKind;
  int get displayOrder => _displayOrder;
  bool get isActive => _isActive;
  bool get isNotifiable => _streamKind != null && _streamKind!.isNotEmpty;

  void setName(final String name) => _name = name;
  void setColor(final String? color) => _color = color;
  void setStreamKind(final String? streamKind) => _streamKind = streamKind;
  void setDisplayOrder(final int order) => _displayOrder = order;
  void setActive(final bool active) => _isActive = active;
}
