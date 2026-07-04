/// Admin-managed volunteer tag definition stored in `user_tags/{tagId}`.
class UserTag {
  late String _id, _name;
  String? _color;
  late int _displayOrder;
  late bool _isActive;

  UserTag({
    required String id,
    required String name,
    String? color,
    int displayOrder = 0,
    bool isActive = true,
  }) {
    _id = id;
    _name = name;
    _color = color;
    _displayOrder = displayOrder;
    _isActive = isActive;
  }

  UserTag.fromMap(final String id, final Map<String, dynamic> data)
      : _id = id,
        _name = data['Name'] as String,
        _color = data['Color'] as String?,
        _displayOrder = (data['DisplayOrder'] as num?)?.toInt() ?? 0,
        _isActive = data['IsActive'] as bool? ?? true;

  Map<String, dynamic> toJson() {
    return {
      'Name': _name,
      'DisplayOrder': _displayOrder,
      'IsActive': _isActive,
      if (_color != null && _color!.isNotEmpty) 'Color': _color,
    };
  }

  String get id => _id;
  String get name => _name;
  String? get color => _color;
  int get displayOrder => _displayOrder;
  bool get isActive => _isActive;

  void setName(final String name) => _name = name;
  void setColor(final String? color) => _color = color;
  void setDisplayOrder(final int order) => _displayOrder = order;
  void setActive(final bool active) => _isActive = active;
}
