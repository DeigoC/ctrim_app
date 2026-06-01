import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_media.dart';

void main() {
  group('EventMedia', () {
    group('constructor', () {
      test('creates with an empty media list', () {
        final media = EventMedia();
        expect(media.allMedia, isEmpty);
      });
    });

    group('fromMap', () {
      test('creates from a map with media entries', () {
        final map = {
          'Media': [
            {'src': 'photo.jpg', 'type': 'img', 'title': 'Photo 1', 'thumbnailSrc': null},
            {'src': 'clip.mp4', 'type': 'video', 'title': 'Clip 1', 'thumbnailSrc': 'thumb.jpg'},
          ]
        };

        final media = EventMedia.fromMap(map);

        expect(media.allMedia.length, 2);
        expect(media.allMedia[0]['src'], 'photo.jpg');
        expect(media.allMedia[1]['src'], 'clip.mp4');
      });

      test('creates from a map with an empty media list', () {
        final map = {'Media': <Map<String, dynamic>>[]};
        final media = EventMedia.fromMap(map);
        expect(media.allMedia, isEmpty);
      });
    });

    group('toJson', () {
      test('serialises media list under "Media" key', () {
        final media = EventMedia();
        media.addMediaFile({'src': 'img.jpg', 'type': 'img', 'title': '', 'thumbnailSrc': null});

        final json = media.toJson() as Map<String, dynamic>;

        expect(json.containsKey('Media'), true);
        expect((json['Media'] as List).length, 1);
      });
    });

    group('addMediaFile', () {
      test('appends a single file', () {
        final media = EventMedia();
        media.addMediaFile({'src': 'a.jpg', 'type': 'img', 'title': '', 'thumbnailSrc': null});

        expect(media.allMedia.length, 1);
        expect(media.allMedia.first['src'], 'a.jpg');
      });
    });

    group('addAllMediaFiles', () {
      test('appends multiple files', () {
        final media = EventMedia();
        media.addAllMediaFiles([
          {'src': 'a.jpg', 'type': 'img', 'title': '', 'thumbnailSrc': null},
          {'src': 'b.jpg', 'type': 'img', 'title': '', 'thumbnailSrc': null},
        ]);

        expect(media.allMedia.length, 2);
      });
    });

    group('removeMediaFile', () {
      test('removes matching entry by reference', () {
        final media = EventMedia();
        final file = {'src': 'a.jpg', 'type': 'img', 'title': '', 'thumbnailSrc': null};
        media.addMediaFile(file);
        media.removeMediaFile(file);

        expect(media.allMedia, isEmpty);
      });
    });

    group('clearAllMedia', () {
      test('removes all media entries', () {
        final media = EventMedia();
        media.addMediaFile({'src': 'a.jpg', 'type': 'img', 'title': '', 'thumbnailSrc': null});
        media.addMediaFile({'src': 'b.jpg', 'type': 'img', 'title': '', 'thumbnailSrc': null});
        media.clearAllMedia();

        expect(media.allMedia, isEmpty);
      });
    });

    group('allMedia getter', () {
      test('returns an unmodifiable view', () {
        final media = EventMedia();
        expect(() => media.allMedia.add({}), throwsUnsupportedError);
      });
    });
  });
}
