import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrim_app/models/info/church_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChurchPage', () {
    test('fromMap reads nested page fields and churchId from the path', () {
      final page = ChurchPage.fromMap('sunday_service', 'belfast', {
        'title': 'Sunday service',
        'body': [
          {'insert': '10am\n'}
        ],
        'imgSrc': 'https://example.com/hero.png',
        'summary': 'What to expect',
        'updatedBy': 'user-1',
        'updatedAt': Timestamp.fromMillisecondsSinceEpoch(1700000000000),
        'displayOrder': 2,
      });

      expect(page.id, 'sunday_service');
      expect(page.churchId, 'belfast');
      expect(page.title, 'Sunday service');
      expect(page.summary, 'What to expect');
      expect(page.imageSources, ['https://example.com/hero.png']);
      expect(page.imgSrc, 'https://example.com/hero.png');
      expect(page.updatedBy, 'user-1');
      expect(page.displayOrder, 2);
      expect(page.body, [
        {'insert': '10am\n'}
      ]);
    });

    test('fromMap prefers churchId stored in cache json', () {
      final page = ChurchPage.fromMap('getting_here', 'ignored', {
        'churchId': 'portadown',
        'title': 'Getting here',
        'body': [
          {'insert': 'Park on High St\n'}
        ],
      });

      expect(page.churchId, 'portadown');
    });

    test('toJson writes Firestore friendly shape without churchId', () {
      final page = ChurchPage(
        id: 'getting_here',
        churchId: 'belfast',
        title: 'Getting here',
        body: const [
          {'insert': 'Body\n'}
        ],
        imageSources: const [
          'https://example.com/a.png',
          'https://example.com/b.png'
        ],
        summary: 'Directions',
        updatedBy: 'admin-1',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        displayOrder: 1,
      );

      final json = page.toJson();

      expect(json.containsKey('churchId'), isFalse);
      expect(json.containsKey('id'), isFalse);
      expect(json['title'], 'Getting here');
      expect(json['imageSources'],
          ['https://example.com/a.png', 'https://example.com/b.png']);
      expect(json['summary'], 'Directions');
      expect(json['updatedBy'], 'admin-1');
      expect(json['updatedAt'], isA<Timestamp>());
      expect(json['displayOrder'], 1);
    });

    test('toCacheJson includes id and churchId', () {
      final page = ChurchPage(
        id: 'sunday',
        churchId: 'nc',
        title: 'Sunday',
        body: const [
          {'insert': 'Body\n'}
        ],
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final cache = page.toCacheJson();
      expect(cache['id'], 'sunday');
      expect(cache['churchId'], 'nc');
      expect(cache['title'], 'Sunday');
      expect(cache['updatedAt'], 1700000000000);
    });

    test('imageSources getter is unmodifiable', () {
      final page = ChurchPage(
        id: 'page',
        churchId: 'belfast',
        title: 'Page',
        body: const [
          {'insert': 'Body\n'}
        ],
        imageSources: const ['https://example.com/a.png'],
      );

      expect(() => page.imageSources.add('https://example.com/b.png'),
          throwsUnsupportedError);
    });

    test('fromMap normalizes empty body payloads to a valid quill delta', () {
      final page = ChurchPage.fromMap('empty', 'belfast', {
        'title': 'Empty',
        'body': const [],
      });

      expect(page.body, [
        {'insert': '\n'}
      ]);
    });

    test('fromMap accepts numeric displayOrder from Firestore', () {
      final page = ChurchPage.fromMap('order_num', 'belfast', {
        'title': 'Order',
        'body': [
          {'insert': 'Hi\n'}
        ],
        'displayOrder': 3.0,
      });

      expect(page.displayOrder, 3);
    });
  });
}
