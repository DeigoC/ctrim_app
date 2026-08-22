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
      expect(info.location, '');
      expect(info.mapLink, '');
      expect(info.address, '');
      expect(info.hasLocation, isFalse);
      expect(info.hasMapLink, isFalse);
      expect(info.updatedBy, 'user-1');
      expect(info.displayOrder, 2);
    });

    test('fromMap reads location, mapLink, and address', () {
      final info = ChurchInfo.fromMap('belfast', {
        'title': 'Belfast',
        'analyticTitle': 'Belfast',
        'body': [
          {'insert': 'Hello\n'}
        ],
        'location': 'Belfast',
        'mapLink': 'https://maps.google.com/?q=belfast',
        'address': '8A Princes Dr',
      });

      expect(info.location, 'Belfast');
      expect(info.mapLink, 'https://maps.google.com/?q=belfast');
      expect(info.address, '8A Princes Dr');
      expect(info.hasLocation, isTrue);
      expect(info.hasMapLink, isTrue);
      expect(info.hasAddress, isTrue);
    });

    test('toJson writes Firestore friendly shape', () {
      final info = ChurchInfo(
        id: 'portadown',
        title: 'Portadown',
        analyticsTitle: 'Portadown',
        body: const [
          {'insert': 'Body\n'}
        ],
        imageSources: const [
          'https://example.com/a.png',
          'https://example.com/b.png'
        ],
        summary: 'Summary',
        location: 'Portadown',
        mapLink: 'https://maps.example/p',
        address: 'High St',
        updatedBy: 'admin-1',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        displayOrder: 1,
      );

      final json = info.toJson();

      expect(json['title'], 'Portadown');
      expect(json['analyticTitle'], 'Portadown');
      expect(json['imageSources'],
          ['https://example.com/a.png', 'https://example.com/b.png']);
      expect(json['summary'], 'Summary');
      expect(json['location'], 'Portadown');
      expect(json['mapLink'], 'https://maps.example/p');
      expect(json['address'], 'High St');
      expect(json['updatedBy'], 'admin-1');
      expect(json['updatedAt'], isA<Timestamp>());
      expect(json['displayOrder'], 1);
    });

    test('toCacheJson includes hub fields', () {
      final info = ChurchInfo(
        id: 'nc',
        title: 'North Coast',
        analyticsTitle: 'North Coast',
        body: const [
          {'insert': 'Body\n'}
        ],
        location: 'North Coast',
        mapLink: 'https://maps.example/nc',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final cache = info.toCacheJson();
      expect(cache['location'], 'North Coast');
      expect(cache['mapLink'], 'https://maps.example/nc');
      expect(cache['address'], '');
      expect(cache['updatedAt'], 1700000000000);
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

      expect(() => info.imageSources.add('https://example.com/b.png'),
          throwsUnsupportedError);
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
