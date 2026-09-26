import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user_location.dart';
import 'package:ctrim_app/utility/catalog/volunteer_locations.dart';

void main() {
  group('VolunteerLocations', () {
    test('assignableFrom falls back when empty', () {
      expect(
        VolunteerLocations.assignableFrom(const []),
        VolunteerLocations.fallbackAssignable,
      );
    });

    test('assignableFrom uses active location names', () {
      final locations = [
        UserLocation(id: '1', name: 'Belfast', displayOrder: 1),
        UserLocation(id: '2', name: 'Dublin', displayOrder: 2, isActive: false),
        UserLocation(id: '3', name: 'Cork', displayOrder: 3),
      ];

      expect(VolunteerLocations.assignableFrom(locations), ['Belfast', 'Cork']);
      expect(
        VolunteerLocations.filterOptionsFrom(locations),
        ['All', 'Belfast', 'Cork'],
      );
    });

    test('defaultFilterForUser prefers known location', () {
      expect(
        VolunteerLocations.defaultFilterForUser('Cork', ['Belfast', 'Cork']),
        'Cork',
      );
      expect(
        VolunteerLocations.defaultFilterForUser('Unknown', ['Belfast', 'Cork']),
        'Belfast',
      );
    });

    test('normalizePostLocation strips online suffix', () {
      expect(
        VolunteerLocations.normalizePostLocation('Portadown (Online)'),
        'Portadown',
      );
      expect(VolunteerLocations.normalizePostLocation('Belfast'), 'Belfast');
    });

    test('keyGraphicSrcForName returns the cover for that place only', () {
      final locations = [
        UserLocation(
          id: '1',
          name: 'Belfast',
          media: [
            {'src': 'belfast.jpg', 'type': 'img'},
          ],
          keyGraphicSrc: 'belfast.jpg',
        ),
        UserLocation(id: '2', name: 'Portadown'),
      ];

      expect(
        VolunteerLocations.keyGraphicSrcForName(
          locations: locations,
          name: 'Belfast',
        ),
        'belfast.jpg',
      );
      expect(
        VolunteerLocations.keyGraphicSrcForName(
          locations: locations,
          name: 'Portadown',
        ),
        isNull,
      );
      expect(
        VolunteerLocations.keyGraphicSrcForName(
          locations: locations,
          name: VolunteerLocations.all,
        ),
        isNull,
      );
    });

    test('postLocationMatchesFilter compares base location', () {
      expect(
        VolunteerLocations.postLocationMatchesFilter(
          postLocation: 'North Coast (Online)',
          locationFilter: VolunteerLocations.all,
        ),
        isTrue,
      );
      expect(
        VolunteerLocations.postLocationMatchesFilter(
          postLocation: 'North Coast (Online)',
          locationFilter: 'North Coast',
        ),
        isTrue,
      );
      expect(
        VolunteerLocations.postLocationMatchesFilter(
          postLocation: 'Belfast',
          locationFilter: 'Portadown',
        ),
        isFalse,
      );
    });
  });
}
