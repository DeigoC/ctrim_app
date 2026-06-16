import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrim_app/models/info/church_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChurchInfo', () {
    test('fromMap reads legacy imgSrc as first image source', () {
      final info = ChurchInfo.fromMap('belfast', {
        'title': 'Belfast',
        'analyticTitle': 'Belfast',
        'body': [
          {'insert': 'Hello\n'}
        ],
        'imgSrc': 'https://example.com/hero.png',
        'summary': 'Welcome',
        'updatedBy': 'user-1',
        'updatedAt': Timestamp.fromMillisecondsSinceEpoch(1700000000000),
        'displayOrder': 2,
      });

      expect(info.id, 'belfast');
      expect(info.title, 'Belfast');
      expect(info.analyticsTitle, 'Belfast');
      expect(info.imageSources, ['https://example.com/hero.png']);
      expect(info.imgSrc, 'https://example.com/hero.png');
      expect(info.summary, 'Welcome');
      expect(info.updatedBy, 'user-1');
      expect(info.displayOrder, 2);
    });

    test('toJson writes Firestore friendly shape', () {
      final info = ChurchInfo(
        id: 'portadown',
        title: 'Portadown',
        analyticsTitle: 'Portadown',
        body: const [
          {'insert': 'Body\n'}
        ],
        imageSources: const ['https://example.com/a.png', 'https://example.com/b.png'],
        summary: 'Summary',
        updatedBy: 'admin-1',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        displayOrder: 1,
      );

      final json = info.toJson();

      expect(json['title'], 'Portadown');
      expect(json['analyticTitle'], 'Portadown');
      expect(json['imageSources'], ['https://example.com/a.png', 'https://example.com/b.png']);
      expect(json['summary'], 'Summary');
      expect(json['updatedBy'], 'admin-1');
      expect(json['updatedAt'], isA<Timestamp>());
      expect(json['displayOrder'], 1);
    });

    test('imageSources getter is unmodifiable', () {
      final info = ChurchInfo(
        id: 'north_coast',
        title: 'North Coast',
        analyticsTitle: 'North Coast',
        body: const [
          {'insert': 'Body\n'}
        ],
        imageSources: const ['https://example.com/a.png'],
      );

      expect(() => info.imageSources.add('https://example.com/b.png'), throwsUnsupportedError);
    });
  });
}
