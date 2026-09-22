/// Admin-managed volunteer tag definition stored in `user_tags/{tagId}`.
class UserTag {
  late String _id, _name;
  String? _color;
  late int _displayOrder;
  late bool _isActive;
  late bool _visibleToGuests;
  String? _description;
  String? _imageUrl;

  /// Editor cap for the short public description. Longer copy belongs on the
  /// tag detail page when that grows.
  static const int descriptionMaxLength = 400;

  UserTag({
    required String id,
    required String name,
    String? color,
    int displayOrder = 0,
    bool isActive = true,
    bool visibleToGuests = true,
    String? description,
    String? imageUrl,
  }) {
    _id = id;
    _name = name;
    _color = color;
    _displayOrder = displayOrder;
    _isActive = isActive;
    _visibleToGuests = visibleToGuests;
    _description = _normalizeDescription(description);
    _imageUrl = _normalizeImageUrl(imageUrl);
  }

  UserTag.fromMap(final String id, final Map<String, dynamic> data)
      : _id = id,
        _name = data['Name'] as String,
        _color = data['Color'] as String?,
        _displayOrder = (data['DisplayOrder'] as num?)?.toInt() ?? 0,
        _isActive = data['IsActive'] as bool? ?? true,
        _visibleToGuests = data['VisibleToGuests'] as bool? ?? true,
        _description = _normalizeDescription(data['Description'] as String?),
        _imageUrl = _normalizeImageUrl(data['ImageUrl'] as String?);

  Map<String, dynamic> toJson() {
    return {
      'Name': _name,
      'DisplayOrder': _displayOrder,
      'IsActive': _isActive,
      'VisibleToGuests': _visibleToGuests,
      'Description': _description ?? '',
      'ImageUrl': _imageUrl ?? '',
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

  String get id => _id;
  String get name => _name;
  String? get color => _color;
  int get displayOrder => _displayOrder;
  bool get isActive => _isActive;

  /// When false, guests do not see this label. Missing Firestore values stay true.
  bool get visibleToGuests => _visibleToGuests;

  /// Short public explanation of the team. Empty values stay null.
  String? get description => _description;

  /// Single main graphic. Empty values stay null.
  String? get imageUrl => _imageUrl;

  void setName(final String name) => _name = name;
  void setColor(final String? color) => _color = color;
  void setDisplayOrder(final int order) => _displayOrder = order;
  void setActive(final bool active) => _isActive = active;
  void setVisibleToGuests(final bool visible) => _visibleToGuests = visible;
  void setDescription(final String? description) =>
      _description = _normalizeDescription(description);
  void setImageUrl(final String? imageUrl) =>
      _imageUrl = _normalizeImageUrl(imageUrl);
}
