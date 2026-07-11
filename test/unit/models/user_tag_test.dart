import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user_tag.dart';

void main() {
  group('UserTag', () {
    test('creates tag with defaults', () {
      final tag = UserTag(id: 't1', name: 'Worship Team');

      expect(tag.id, 't1');
      expect(tag.name, 'Worship Team');
      expect(tag.color, isNull);
      expect(tag.displayOrder, 0);
      expect(tag.isActive, true);
    });

    test('fromMap parses Firestore fields', () {
      final tag = UserTag.fromMap('abc', {
        'Name': 'Technical',
        'Color': '#2E7D6F',
        'DisplayOrder': 2,
        'IsActive': false,
      });

      expect(tag.id, 'abc');
      expect(tag.name, 'Technical');
      expect(tag.color, '#2E7D6F');
      expect(tag.displayOrder, 2);
      expect(tag.isActive, false);
    });

    test('toJson omits empty color', () {
      final tag = UserTag(id: 't1', name: 'Usher', displayOrder: 3);
      final json = tag.toJson();

      expect(json['Name'], 'Usher');
      expect(json['DisplayOrder'], 3);
      expect(json['IsActive'], true);
      expect(json.containsKey('Color'), false);
    });

    test('toJson includes color when set', () {
      final tag = UserTag(id: 't1', name: 'Speaker', color: '#C45B2C');
      expect(tag.toJson()['Color'], '#C45B2C');
    });

    test('setters update fields', () {
      final tag = UserTag(id: 't1', name: 'Old');
      tag.setName('New');
      tag.setColor('#FFFFFF');
      tag.setDisplayOrder(5);
      tag.setActive(false);

      expect(tag.name, 'New');
      expect(tag.color, '#FFFFFF');
      expect(tag.displayOrder, 5);
      expect(tag.isActive, false);
    });
  });
}
