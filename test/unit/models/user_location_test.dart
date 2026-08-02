import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user_location.dart';

void main() {
  group('UserLocation', () {
    test('creates location with defaults', () {
      final location = UserLocation(id: 'l1', name: 'Belfast');

      expect(location.id, 'l1');
      expect(location.name, 'Belfast');
      expect(location.displayOrder, 0);
      expect(location.isActive, true);
    });

    test('fromMap parses Firestore fields', () {
      final location = UserLocation.fromMap('abc', {
        'Name': 'Portadown',
        'DisplayOrder': 2,
        'IsActive': false,
      });

      expect(location.id, 'abc');
      expect(location.name, 'Portadown');
      expect(location.displayOrder, 2);
      expect(location.isActive, false);
    });

    test('toJson serializes fields', () {
      final location = UserLocation(id: 'l1', name: 'North Coast', displayOrder: 3);
      final json = location.toJson();

      expect(json['Name'], 'North Coast');
      expect(json['DisplayOrder'], 3);
      expect(json['IsActive'], true);
    });

    test('setters update fields', () {
      final location = UserLocation(id: 'l1', name: 'Old');
      location.setName('New');
      location.setDisplayOrder(5);
      location.setActive(false);

      expect(location.name, 'New');
      expect(location.displayOrder, 5);
      expect(location.isActive, false);
    });
  });
}
