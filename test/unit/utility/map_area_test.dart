import 'package:ctrim_app/utility/map_area.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapArea.cellGroupRadiusMeters', () {
    test(
        'uses a tight circle for a full postcode and a wide one for an outcode',
        () {
      expect(
        MapArea.cellGroupRadiusMeters('BT9 6AB'),
        MapArea.fullPostcodeRadiusMeters,
      );
      expect(
        MapArea.cellGroupRadiusMeters('BT37'),
        MapArea.outcodeRadiusMeters,
      );
      expect(MapArea.cellGroupRadiusMeters(null), isNull);
      expect(MapArea.cellGroupRadiusMeters('Belfast'), isNull);
    });
  });

  group('MapArea.bounds', () {
    test('covers a circle and collapses a lone pin', () {
      final circle = MapArea.bounds(
        circles: const [
          MapAreaCircle(latitude: 54.6, longitude: -5.93, radiusMeters: 2000),
        ],
      );
      expect(circle, isNotNull);
      expect(circle!.south, lessThan(54.6));
      expect(circle.north, greaterThan(54.6));
      expect(circle.west, lessThan(-5.93));
      expect(circle.east, greaterThan(-5.93));
      expect(circle.isDegenerate, isFalse);

      final pin = MapArea.bounds(
        pins: const [MapAreaPin(latitude: 54.6, longitude: -5.93)],
      );
      expect(pin!.isDegenerate, isTrue);
      expect(MapArea.bounds(), isNull);
    });
  });
}
