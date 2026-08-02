import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctrim_app/models/info/testimonial_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TestimonialInfo', () {
    test('fromMap supports legacy imgSrc field', () {
      final info = TestimonialInfo.fromMap('maije', {
        'name': 'Maije',
        'church': 'Northcoast Derry/Londonderry',
        'body': [
          {'insert': 'Body\n'}
        ],
        'imgSrc': 'https://example.com/maije.png',
        'summary': 'Saved by grace.',
        'updatedBy': 'admin-1',
        'updatedAt': Timestamp.fromMillisecondsSinceEpoch(1700000000000),
        'displayOrder': 0,
      });

      expect(info.id, 'maije');
      expect(info.name, 'Maije');
      expect(info.church, 'Northcoast Derry/Londonderry');
      expect(info.imageSources, ['https://example.com/maije.png']);
      expect(info.summary, 'Saved by grace.');
    });

    test('toJson writes array-based imageSources', () {
      final info = TestimonialInfo(
        id: 'ching',
        name: 'Ching',
        church: 'Belfast',
        body: const [
          {'insert': 'Body\n'}
        ],
        imageSources: const ['https://example.com/ching.png', 'https://example.com/ching-2.png'],
        summary: 'Life changed.',
        updatedBy: 'admin-2',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        displayOrder: 2,
      );

      final json = info.toJson();

      expect(json['name'], 'Ching');
      expect(json['church'], 'Belfast');
      expect(json['imageSources'], ['https://example.com/ching.png', 'https://example.com/ching-2.png']);
      expect(json['summary'], 'Life changed.');
      expect(json['updatedAt'], isA<Timestamp>());
      expect(json['displayOrder'], 2);
    });

    test('fromMap falls back to valid quill delta for invalid string body', () {
      final info = TestimonialInfo.fromMap('bad_string_body', {
        'name': 'Bad Body',
        'church': 'Belfast',
        'body': '',
      });

      expect(info.body, [
        {'insert': '\n'}
      ]);
    });

    test('fromMap parses map body with ops field', () {
      final info = TestimonialInfo.fromMap('ops_body', {
        'name': 'Ops',
        'church': 'Belfast',
        'body': {
          'ops': [
            {'insert': 'Mapped ops\n'}
          ]
        },
      });

      expect(info.body, [
        {'insert': 'Mapped ops\n'}
      ]);
    });
  });
}
