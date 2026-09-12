import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/cell_group.dart';
import 'package:ctrim_app/utility/cell_group_nearest.dart';

CellGroup _group({
  required String id,
  required String name,
  String summary = '',
  double? lat,
  double? lng,
}) {
  return CellGroup(
    id: id,
    name: name,
    summary: summary,
    postcode: lat == null ? null : 'BT1 1AA',
    latitude: lat,
    longitude: lng,
  );
}

void main() {
  group('CellGroupNearestQuery.rank', () {
    test('skips groups without coordinates and sorts by miles then name', () {
      // Origin near Belfast city centre.
      const originLat = 54.597;
      const originLng = -5.930;

      final nearer = _group(id: '1', name: 'Zoo', lat: 54.598, lng: -5.931);
      final farther = _group(id: '2', name: 'Alpha', lat: 54.65, lng: -5.93);
      final alsoNear = _group(id: '3', name: 'Ark', lat: 54.598, lng: -5.931);
      final noPin = _group(id: '4', name: 'No pin');

      final ranked = CellGroupNearestQuery.rank(
        groups: [farther, noPin, nearer, alsoNear],
        originLat: originLat,
        originLng: originLng,
      );

      expect(ranked.map((m) => m.group.id), ['3', '1', '2']);
      expect(ranked.first.miles, lessThan(ranked.last.miles));
      expect(ranked[0].group.name, 'Ark');
      expect(ranked[1].group.name, 'Zoo');
    });
  });

  group('CellGroupNearestQuery.filterByText', () {
    test('matches name or summary case-insensitively', () {
      final groups = [
        _group(id: '1', name: 'East Side', summary: 'Families'),
        _group(id: '2', name: 'North', summary: 'Young adults'),
      ];
      expect(
        CellGroupNearestQuery.filterByText(groups: groups, query: 'east')
            .map((g) => g.id),
        ['1'],
      );
      expect(
        CellGroupNearestQuery.filterByText(groups: groups, query: 'YOUNG')
            .map((g) => g.id),
        ['2'],
      );
      expect(
        CellGroupNearestQuery.filterByText(groups: groups, query: '  '),
        hasLength(2),
      );
    });
  });

  group('CellGroupNearestQuery.formatMiles', () {
    test('uses a floor for very short distances', () {
      expect(CellGroupNearestQuery.formatMiles(0.04), '< 0.1 miles');
      expect(CellGroupNearestQuery.formatMiles(1.24), '1.2 miles');
    });
  });
}
