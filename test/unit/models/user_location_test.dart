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
      final location =
          UserLocation(id: 'l1', name: 'North Coast', displayOrder: 3);
      final json = location.toJson();

      expect(json['Name'], 'North Coast');
      expect(json['DisplayOrder'], 3);
      expect(json['IsActive'], true);
      expect(json['Media'], isEmpty);
      expect(json['KeyGraphicSrc'], isNull);
    });

    test('fromMap parses media and keeps a cover that is in the gallery', () {
      final location = UserLocation.fromMap('abc', {
        'Name': 'Belfast',
        'Media': [
          {'src': 'cover.jpg', 'type': 'img', 'title': 'Hall'},
          {'src': '', 'type': 'img'},
          'not-a-map',
        ],
        'KeyGraphicSrc': 'cover.jpg',
      });

      expect(location.media, hasLength(1));
      expect(location.media.single['title'], 'Hall');
      expect(location.media.single['type'], 'img');
      expect(location.keyGraphicSrc, 'cover.jpg');
      expect(location.hasKeyGraphic, isTrue);
    });

    test('fromMap drops a cover that is not in the gallery', () {
      final location = UserLocation.fromMap('abc', {
        'Name': 'Belfast',
        'Media': [
          {'src': 'hall.jpg', 'type': 'img'},
        ],
        'KeyGraphicSrc': 'missing.jpg',
      });

      expect(location.keyGraphicSrc, isNull);
      expect(location.hasKeyGraphic, isFalse);
    });

    test('media list is unmodifiable and cover must be a gallery src', () {
      final location = UserLocation(id: 'l1', name: 'Belfast');

      expect(() => location.media.add({'src': 'x'}), throwsUnsupportedError);
      expect(location.addMediaItem({'src': ''}), isFalse);
      expect(
          location.addMediaItem({'src': 'a.jpg', 'type': 'img', 'title': 'A'}),
          isTrue);
      expect(location.addMediaItem({'src': 'a.jpg'}), isFalse);
      expect(location.setKeyGraphicSrc('missing.jpg'), isFalse);
      expect(location.setKeyGraphicSrc('a.jpg'), isTrue);
      expect(location.keyGraphicSrc, 'a.jpg');

      location.removeMediaItem('a.jpg');
      expect(location.media, isEmpty);
      expect(location.keyGraphicSrc, isNull);
      expect(location.setKeyGraphicSrc(null), isTrue);
    });

    test('addMediaItem stops at the gallery cap', () {
      final location = UserLocation(id: 'l1', name: 'Belfast');
      for (var i = 0; i < UserLocation.maxMediaItems; i++) {
        expect(location.addMediaItem({'src': 'src-$i', 'type': 'img'}), isTrue);
      }
      expect(
          location.addMediaItem({'src': 'overflow', 'type': 'img'}), isFalse);
      expect(location.media, hasLength(UserLocation.maxMediaItems));
    });

    test('setMedia copies items and clears a cover that left the gallery', () {
      final location = UserLocation(
        id: 'l1',
        name: 'Belfast',
        media: [
          {'src': 'old.jpg', 'type': 'img'},
        ],
        keyGraphicSrc: 'old.jpg',
      );
      final replacement = [
        {'src': 'new.jpg', 'type': 'img', 'title': 'New'},
      ];
      location.setMedia(replacement);
      replacement.clear();

      expect(location.media.single['src'], 'new.jpg');
      expect(location.keyGraphicSrc, isNull);
      expect(location.setKeyGraphicSrc('new.jpg'), isTrue);

      final json = location.toJson();
      expect(json['KeyGraphicSrc'], 'new.jpg');
      expect((json['Media'] as List).single['src'], 'new.jpg');
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
