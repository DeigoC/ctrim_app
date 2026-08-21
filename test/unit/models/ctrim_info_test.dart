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
        'category': 'teaching',
      });

      expect(info.id, 'core_values');
      expect(info.title, 'Core Values');
      expect(info.description, 'What do we live and work for?');
      expect(info.analyticsTitle, 'Core Values');
      expect(info.imageSources, ['https://example.com/core.png']);
      expect(info.updatedBy, 'admin-1');
      expect(info.displayOrder, 3);
      expect(info.category, CtrimInfoCategory.teaching);
    });

    test('fromMap defaults missing category to principle', () {
      final info = CtrimInfo.fromMap('legacy', {
        'title': 'Legacy Topic',
        'description': 'desc',
        'analyticTitle': 'Legacy Topic',
        'body': [
          {'insert': 'Body\n'}
        ],
      });

      expect(info.category, CtrimInfoCategory.principle);
    });

    test('toJson writes Firestore friendly shape including category', () {
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
        category: CtrimInfoCategory.teaching,
      );

      final json = info.toJson();

      expect(json['title'], 'Devotionals');
      expect(json['description'], 'How do we grow?');
      expect(json['analyticTitle'], 'Devotionals');
      expect(json['imageSources'], ['https://example.com/devotionals.png']);
      expect(json['updatedAt'], isA<Timestamp>());
      expect(json['displayOrder'], 4);
      expect(json['category'], 'teaching');
    });

    test('toCacheJson includes category', () {
      final info = CtrimInfo(
        id: 'cell_group',
        title: 'Cell Group',
        description: 'desc',
        analyticsTitle: 'Cell Group',
        body: const [
          {'insert': 'Body\n'}
        ],
        category: CtrimInfoCategory.principle,
      );

      expect(info.toCacheJson()['category'], 'principle');
    });

    test('fromMap removes invalid empty insert operations', () {
      final info = CtrimInfo.fromMap('bad_delta', {
        'title': 'Bad Delta',
        'description': 'desc',
        'analyticTitle': 'Bad Delta',
        'body': const [
          {'insert': ''}
        ],
      });

      expect(info.body, [
        {'insert': '\n'}
      ]);
    });

    test('fromMap parses double-encoded JSON body strings', () {
      final info = CtrimInfo.fromMap('double_encoded', {
        'title': 'Double',
        'description': 'desc',
        'analyticTitle': 'Double',
        'body': '"[{\\"insert\\":\\"Legacy text\\n\\"}]"',
      });

      expect(info.body, [
        {'insert': 'Legacy text\n'}
      ]);
    });

    test('fromMap parses quill document map with ops', () {
      final info = CtrimInfo.fromMap('ops_map', {
        'title': 'Ops',
        'description': 'desc',
        'analyticTitle': 'Ops',
        'body': {
          'ops': [
            {'insert': 'From ops\n'}
          ]
        },
      });

      expect(info.body, [
        {'insert': 'From ops\n'}
      ]);
    });
  });

  group('CtrimInfoCategory', () {
    test('fromFirestore maps teaching and defaults everything else', () {
      expect(CtrimInfoCategory.fromFirestore('teaching'),
          CtrimInfoCategory.teaching);
      expect(CtrimInfoCategory.fromFirestore('TEACHING'),
          CtrimInfoCategory.teaching);
      expect(CtrimInfoCategory.fromFirestore('principle'),
          CtrimInfoCategory.principle);
      expect(CtrimInfoCategory.fromFirestore(null), CtrimInfoCategory.principle);
      expect(CtrimInfoCategory.fromFirestore(''), CtrimInfoCategory.principle);
      expect(
          CtrimInfoCategory.fromFirestore('other'), CtrimInfoCategory.principle);
    });
  });
}
