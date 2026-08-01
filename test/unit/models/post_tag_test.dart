import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/post_tag.dart';

void main() {
  group('PostTag', () {
    test('creates tag with defaults', () {
      final tag = PostTag(id: 't1', name: 'Sunday Worship');

      expect(tag.id, 't1');
      expect(tag.name, 'Sunday Worship');
      expect(tag.color, isNull);
      expect(tag.streamKind, isNull);
      expect(tag.isNotifiable, false);
      expect(tag.displayOrder, 0);
      expect(tag.isActive, true);
    });

    test('fromMap parses Firestore fields', () {
      final tag = PostTag.fromMap('abc', {
        'Name': 'Sunday Worship',
        'Color': '#6B4EAA',
        'StreamKind': 'sunday-service',
        'DisplayOrder': 2,
        'IsActive': false,
      });

      expect(tag.id, 'abc');
      expect(tag.name, 'Sunday Worship');
      expect(tag.color, '#6B4EAA');
      expect(tag.streamKind, 'sunday-service');
      expect(tag.isNotifiable, true);
      expect(tag.displayOrder, 2);
      expect(tag.isActive, false);
    });

    test('toJson omits empty optional fields', () {
      final tag = PostTag(id: 't1', name: 'Announcement', displayOrder: 3);
      final json = tag.toJson();

      expect(json['Name'], 'Announcement');
      expect(json['DisplayOrder'], 3);
      expect(json['IsActive'], true);
      expect(json.containsKey('Color'), false);
      expect(json.containsKey('StreamKind'), false);
    });

    test('toJson includes stream kind when set', () {
      final tag = PostTag(
        id: 't1',
        name: 'Sunday',
        streamKind: 'sunday-service',
      );
      expect(tag.toJson()['StreamKind'], 'sunday-service');
    });

    test('setters update fields', () {
      final tag = PostTag(id: 't1', name: 'Old');
      tag.setName('New');
      tag.setColor('#FFFFFF');
      tag.setStreamKind('midweek-service');
      tag.setDisplayOrder(5);
      tag.setActive(false);

      expect(tag.name, 'New');
      expect(tag.color, '#FFFFFF');
      expect(tag.streamKind, 'midweek-service');
      expect(tag.isNotifiable, true);
      expect(tag.displayOrder, 5);
      expect(tag.isActive, false);
    });
  });
}
