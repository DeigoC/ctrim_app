import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrim_app/models/info/ctrim_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CtrimInfo', () {
    test('fromMap reads imageSources and metadata', () {
      final info = CtrimInfo.fromMap('core_values', {
        'title': 'Core Values',
        'description': 'What do we live and work for?',
        'analyticTitle': 'Core Values',
        'body': [
          {'insert': 'Body\n'}
        ],
        'imageSources': ['https://example.com/core.png'],
        'updatedBy': 'admin-1',
        'updatedAt': Timestamp.fromMillisecondsSinceEpoch(1700000000000),
        'displayOrder': 3,
      });

      expect(info.id, 'core_values');
      expect(info.title, 'Core Values');
      expect(info.description, 'What do we live and work for?');
      expect(info.analyticsTitle, 'Core Values');
      expect(info.imageSources, ['https://example.com/core.png']);
      expect(info.updatedBy, 'admin-1');
      expect(info.displayOrder, 3);
    });

    test('toJson writes Firestore friendly shape', () {
      final info = CtrimInfo(
        id: 'devotionals',
        title: 'Devotionals',
        description: 'How do we grow?',
        analyticsTitle: 'Devotionals',
        body: const [
          {'insert': 'Body\n'}
        ],
        imageSources: const ['https://example.com/devotionals.png'],
        updatedBy: 'admin-2',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        displayOrder: 4,
      );

      final json = info.toJson();

      expect(json['title'], 'Devotionals');
      expect(json['description'], 'How do we grow?');
      expect(json['analyticTitle'], 'Devotionals');
      expect(json['imageSources'], ['https://example.com/devotionals.png']);
      expect(json['updatedAt'], isA<Timestamp>());
      expect(json['displayOrder'], 4);
    });
  });
}
