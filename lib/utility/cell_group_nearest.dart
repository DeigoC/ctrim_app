import 'dart:math' as math;

import '../models/cell_group.dart';

/// A catalogue group with distance from a postcode origin.
class CellGroupNearestMatch {
  const CellGroupNearestMatch({
    required this.group,
    required this.miles,
  });

  final CellGroup group;
  final double miles;
}

/// Client-side nearest ranking and name filter for the Groups catalogue.
class CellGroupNearestQuery {
  CellGroupNearestQuery._();

  static const double _earthRadiusMiles = 3958.8;

  /// Groups that have coordinates, nearest first; name tie-break.
  static List<CellGroupNearestMatch> rank({
    required List<CellGroup> groups,
    required double originLat,
    required double originLng,
  }) {
    final matches = <CellGroupNearestMatch>[];
    for (final group in groups) {
      if (!group.hasCoordinates) continue;
      matches.add(CellGroupNearestMatch(
        group: group,
        miles: milesBetween(
          lat1: originLat,
          lng1: originLng,
          lat2: group.latitude!,
          lng2: group.longitude!,
        ),
      ));
    }
    matches.sort((a, b) {
      final byMiles = a.miles.compareTo(b.miles);
      if (byMiles != 0) return byMiles;
      return a.group.name.toLowerCase().compareTo(b.group.name.toLowerCase());
    });
    return matches;
  }

  /// Case-insensitive name or summary contains [query].
  static List<CellGroup> filterByText({
    required List<CellGroup> groups,
    required String query,
  }) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return List<CellGroup>.from(groups);
    return groups
        .where((group) =>
            group.name.toLowerCase().contains(needle) ||
            group.summary.toLowerCase().contains(needle))
        .toList();
  }

  static double milesBetween({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMiles * c;
  }

  /// Display string for a distance in miles.
  static String formatMiles(final double miles) {
    if (miles < 0.1) return '< 0.1 miles';
    return '${miles.toStringAsFixed(1)} miles';
  }

  static double _toRadians(final double degrees) => degrees * math.pi / 180;
}
