import '../models/info/church_info.dart';

/// 1:1 church ↔ location-catalogue name helpers.
class ChurchLocation {
  ChurchLocation._();

  /// Another church already using [location], or null if the name is free.
  static ChurchInfo? otherChurchUsingLocation({
    required Iterable<ChurchInfo> churches,
    required String location,
    String? excludingId,
  }) {
    final name = location.trim();
    if (name.isEmpty) return null;
    for (final church in churches) {
      if (excludingId != null && church.id == excludingId) continue;
      if (church.location.trim() == name) return church;
    }
    return null;
  }

  /// Location names already assigned to a church, excluding [excludingId].
  static Set<String> occupiedLocationNames({
    required Iterable<ChurchInfo> churches,
    String? excludingId,
  }) {
    final occupied = <String>{};
    for (final church in churches) {
      if (excludingId != null && church.id == excludingId) continue;
      final name = church.location.trim();
      if (name.isNotEmpty) occupied.add(name);
    }
    return occupied;
  }
}
