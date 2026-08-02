/// Admin-managed volunteer location definition stored in `user_locations/{locationId}`.
///
/// Users store the location **name** on `users/{uid}.Location` (legacy string field).
class UserLocation {
  late String _id, _name;
  late int _displayOrder;
  late bool _isActive;

  UserLocation({
    required String id,
    required String name,
    int displayOrder = 0,
    bool isActive = true,
  }) {
    _id = id;
    _name = name;
    _displayOrder = displayOrder;
    _isActive = isActive;
  }

  UserLocation.fromMap(final String id, final Map<String, dynamic> data)
      : _id = id,
        _name = data['Name'] as String,
        _displayOrder = (data['DisplayOrder'] as num?)?.toInt() ?? 0,
        _isActive = data['IsActive'] as bool? ?? true;

  Map<String, dynamic> toJson() {
    return {
      'Name': _name,
      'DisplayOrder': _displayOrder,
      'IsActive': _isActive,
    };
  }

  String get id => _id;
  String get name => _name;
  int get displayOrder => _displayOrder;
  bool get isActive => _isActive;

  void setName(final String name) => _name = name;
  void setDisplayOrder(final int order) => _displayOrder = order;
  void setActive(final bool active) => _isActive = active;
}
