import 'dart:math' as math;

import 'uk_postcode_lookup.dart';

/// A circle drawn in metres around a latitude/longitude.
class MapAreaCircle {
  const MapAreaCircle({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;
}

/// A point on the map. [origin] marks the postcode someone searched for.
class MapAreaPin {
  const MapAreaPin({
    required this.latitude,
    required this.longitude,
    this.origin = false,
  });

  final double latitude;
  final double longitude;
  final bool origin;
}

/// Southwest / northeast box covering circles and pins.
class MapAreaBounds {
  const MapAreaBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  bool get isDegenerate =>
      (north - south).abs() < 1e-8 && (east - west).abs() < 1e-8;
}

/// Circle sizes and camera limits for the shared map.
class MapArea {
  MapArea._();

  static const double fullPostcodeRadiusMeters = 400;
  static const double outcodeRadiusMeters = 2000;

  /// Neighbourhood scale. Stops a cell-group circle reading as a house.
  static const double cellGroupMaxZoom = 13;

  /// Street scale for a public church building.
  static const double churchPinZoom = 16;

  static const double _metersPerDegree = 111320;

  /// Radius for a stored cell-group postcode, or null when it is not one.
  static double? cellGroupRadiusMeters(final String? postcode) {
    switch (UkPostcodeLookup.classify(postcode ?? '')) {
      case UkPostcodeKind.full:
        return fullPostcodeRadiusMeters;
      case UkPostcodeKind.outcode:
        return outcodeRadiusMeters;
      case UkPostcodeKind.none:
        return null;
    }
  }

  /// Box covering every circle edge and pin. Null when nothing was given.
  static MapAreaBounds? bounds({
    final List<MapAreaCircle> circles = const [],
    final List<MapAreaPin> pins = const [],
  }) {
    double? south;
    double? north;
    double? west;
    double? east;

    void include(final double lat, final double lng, final double radius) {
      final latDelta = radius / _metersPerDegree;
      final cosLat = math.cos(lat * math.pi / 180).abs();
      final lngScale = _metersPerDegree * (cosLat < 0.01 ? 0.01 : cosLat);
      final lngDelta = radius / lngScale;
      final nextSouth = lat - latDelta;
      final nextNorth = lat + latDelta;
      final nextWest = lng - lngDelta;
      final nextEast = lng + lngDelta;
      south = south == null ? nextSouth : math.min(south!, nextSouth);
      north = north == null ? nextNorth : math.max(north!, nextNorth);
      west = west == null ? nextWest : math.min(west!, nextWest);
      east = east == null ? nextEast : math.max(east!, nextEast);
    }

    for (final circle in circles) {
      include(circle.latitude, circle.longitude, circle.radiusMeters);
    }
    for (final pin in pins) {
      include(pin.latitude, pin.longitude, 0);
    }
    if (south == null || north == null || west == null || east == null) {
      return null;
    }
    return MapAreaBounds(
        south: south!, west: west!, north: north!, east: east!);
  }
}
