import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrim_app/models/info/church_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChurchInfo', () {
    test('fromMap migrates legacy imgSrc to heroImageSrc', () {
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
      expect(info.heroImageSrc, 'https://example.com/hero.png');
      expect(info.imgSrc, 'https://example.com/hero.png');
      expect(info.galleryImageSources, isEmpty);
      expect(info.summary, 'Welcome');
      expect(info.location, '');
      expect(info.mapLink, '');
      expect(info.address, '');
      expect(info.hasLocation, isFalse);
      expect(info.hasMapLink, isFalse);
      expect(info.hasHeroImage, isTrue);
      expect(info.pastorUserIds, isEmpty);
      expect(info.hasPastors, isFalse);
      expect(info.updatedBy, 'user-1');
      expect(info.displayOrder, 2);
    });

    test('fromMap migrates legacy imageSources to hero and gallery', () {
      final info = ChurchInfo.fromMap('belfast', {
        'title': 'Belfast',
        'analyticTitle': 'Belfast',
        'body': [
          {'insert': 'Hello\n'}
        ],
        'imageSources': [
          'https://example.com/hero.png',
          'https://example.com/gallery.png',
        ],
      });

      expect(info.heroImageSrc, 'https://example.com/hero.png');
      expect(info.galleryImageSources, ['https://example.com/gallery.png']);
    });

    test('fromMap reads hub fields and pastorUserIds', () {
      final info = ChurchInfo.fromMap('belfast', {
        'title': 'Belfast',
        'analyticTitle': 'Belfast',
        'body': [
          {'insert': 'Hello\n'}
        ],
        'heroImageSrc': 'https://example.com/hero.png',
        'pastorsImageSrc': 'https://example.com/pastors.png',
        'galleryImageSources': ['https://example.com/gallery.png'],
        'location': 'Belfast',
        'mapLink': 'https://maps.google.com/?q=belfast',
        'address': '8A Princes Dr',
        'pastorUserIds': ['user-a', 'user-b'],
      });

      expect(info.heroImageSrc, 'https://example.com/hero.png');
      expect(info.pastorsImageSrc, 'https://example.com/pastors.png');
      expect(info.galleryImageSources, ['https://example.com/gallery.png']);
      expect(info.location, 'Belfast');
      expect(info.mapLink, 'https://maps.google.com/?q=belfast');
      expect(info.address, '8A Princes Dr');
      expect(info.hasLocation, isTrue);
      expect(info.hasMapLink, isTrue);
      expect(info.hasAddress, isTrue);
      expect(info.hasPastorsImage, isTrue);
      expect(info.pastorUserIds, ['user-a', 'user-b']);
      expect(info.hasPastors, isTrue);
      expect(info.hasPastorsSection, isTrue);
    });

    test('gallery excludes hero image duplicates', () {
      final info = ChurchInfo(
        id: 'belfast',
        title: 'Belfast',
        analyticsTitle: 'Belfast',
        body: const [
          {'insert': 'Body\n'}
        ],
        heroImageSrc: 'https://example.com/hero.png',
        galleryImageSources: const [
          'https://example.com/hero.png',
          'https://example.com/gallery.png',
        ],
      );

      expect(info.galleryImageSources, ['https://example.com/gallery.png']);
    });

    test('toJson writes Firestore friendly shape', () {
      final info = ChurchInfo(
        id: 'portadown',
        title: 'Portadown',
        analyticsTitle: 'Portadown',
        body: const [
          {'insert': 'Body\n'}
        ],
        heroImageSrc: 'https://example.com/hero.png',
        pastorsImageSrc: 'https://example.com/pastors.png',
        galleryImageSources: const ['https://example.com/gallery.png'],
        summary: 'Summary',
        location: 'Portadown',
        mapLink: 'https://maps.example/p',
        address: 'High St',
        pastorUserIds: const ['pastor-1', 'pastor-2'],
        updatedBy: 'admin-1',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        displayOrder: 1,
      );

      final json = info.toJson();

      expect(json['title'], 'Portadown');
      expect(json['analyticTitle'], 'Portadown');
      expect(json['heroImageSrc'], 'https://example.com/hero.png');
      expect(json['pastorsImageSrc'], 'https://example.com/pastors.png');
      expect(json['galleryImageSources'], ['https://example.com/gallery.png']);
      expect(json['summary'], 'Summary');
      expect(json['location'], 'Portadown');
      expect(json['mapLink'], 'https://maps.example/p');
      expect(json['address'], 'High St');
      expect(json['pastorUserIds'], ['pastor-1', 'pastor-2']);
      expect(json['updatedBy'], 'admin-1');
      expect(json['updatedAt'], isA<Timestamp>());
      expect(json['displayOrder'], 1);
      expect(json.containsKey('imageSources'), isFalse);
    });

    test('toCacheJson includes hub fields', () {
      final info = ChurchInfo(
        id: 'nc',
        title: 'North Coast',
        analyticsTitle: 'North Coast',
        body: const [
          {'insert': 'Body\n'}
        ],
        heroImageSrc: 'https://example.com/hero.png',
        pastorsImageSrc: 'https://example.com/pastors.png',
        galleryImageSources: const ['https://example.com/gallery.png'],
        location: 'North Coast',
        mapLink: 'https://maps.example/nc',
        pastorUserIds: const ['pastor-1'],
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final cache = info.toCacheJson();
      expect(cache['heroImageSrc'], 'https://example.com/hero.png');
      expect(cache['pastorsImageSrc'], 'https://example.com/pastors.png');
      expect(cache['galleryImageSources'], ['https://example.com/gallery.png']);
      expect(cache['location'], 'North Coast');
      expect(cache['mapLink'], 'https://maps.example/nc');
      expect(cache['address'], '');
      expect(cache['pastorUserIds'], ['pastor-1']);
      expect(cache['updatedAt'], 1700000000000);
    });

    test('galleryImageSources getter is unmodifiable', () {
      final info = ChurchInfo(
        id: 'north_coast',
        title: 'North Coast',
        analyticsTitle: 'North Coast',
        body: const [
          {'insert': 'Body\n'}
        ],
        galleryImageSources: const ['https://example.com/a.png'],
      );

      expect(() => info.galleryImageSources.add('https://example.com/b.png'),
          throwsUnsupportedError);
    });

    test('pastorUserIds getter is unmodifiable', () {
      final info = ChurchInfo(
        id: 'belfast',
        title: 'Belfast',
        analyticsTitle: 'Belfast',
        body: const [
          {'insert': 'Body\n'}
        ],
        pastorUserIds: const ['pastor-1'],
      );

      expect(() => info.pastorUserIds.add('pastor-2'), throwsUnsupportedError);
    });

    test('fromMap normalizes empty body payloads to a valid quill delta', () {
      final info = ChurchInfo.fromMap('empty_body', {
        'title': 'Empty',
        'analyticTitle': 'Empty',
        'body': const [],
      });

      expect(info.body, [
        {'insert': '\n'}
      ]);
    });

    test('fromMap accepts numeric displayOrder from Firestore', () {
      final info = ChurchInfo.fromMap('order_num', {
        'title': 'Order',
        'analyticTitle': 'Order',
        'body': [
          {'insert': 'Hi\n'}
        ],
        'displayOrder': 3.0,
      });

      expect(info.displayOrder, 3);
    });
  });
}
