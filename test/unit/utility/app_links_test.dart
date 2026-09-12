import 'package:ctrim_app/utility/app_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLinks.postPath', () {
    test('encodes the id in /post/:id', () {
      expect(AppLinks.postPath('post-42'), '/post/post-42');
      expect(AppLinks.postPath('a b'), '/post/a%20b');
    });
  });

  group('AppLinks paths', () {
    test('builds shareable record paths', () {
      expect(AppLinks.cellGroupPath('cg-1'), '/cell-groups/cg-1');
      expect(AppLinks.churchPath('belfast'), '/churches/belfast');
      expect(
        AppLinks.churchPagePath('belfast', 'getting-here'),
        '/churches/belfast/pages/getting-here',
      );
      expect(
        AppLinks.churchPastorsPath('belfast'),
        '/churches/belfast/pastors',
      );
      expect(AppLinks.infoPath('core_values'), '/info/core_values');
      expect(AppLinks.testimonialPath('t-1'), '/testimonials/t-1');
      expect(AppLinks.personPath('u-1'), '/people/u-1');
    });

    test('uses the public web origin', () {
      expect(AppLinks.postUrl('post-42'), 'https://ctrim.app/post/post-42');
      expect(
        AppLinks.cellGroupUrl('cg-1'),
        'https://ctrim.app/cell-groups/cg-1',
      );
      expect(
          AppLinks.churchUrl('belfast'), 'https://ctrim.app/churches/belfast');
      expect(AppLinks.infoUrl('core_values'),
          'https://ctrim.app/info/core_values');
      expect(
        AppLinks.testimonialUrl('t-1'),
        'https://ctrim.app/testimonials/t-1',
      );
      expect(AppLinks.personUrl('u-1'), 'https://ctrim.app/people/u-1');
    });
  });

  group('AppLinks.infoDocumentIdFromPayload', () {
    test('maps legacy JSON paths and passes through document ids', () {
      expect(
        AppLinks.infoDocumentIdFromPayload(
            'assets/info/ctrim_info/core_values.json'),
        'core_values',
      );
      expect(AppLinks.infoDocumentIdFromPayload('4xd'), '4xd');
    });
  });

  group('AppLinks.redirectFromUri', () {
    test('maps postId query to /post/:id', () {
      expect(
        AppLinks.redirectFromUri(
            Uri.parse('https://ctrim.app/?postId=post-42')),
        '/post/post-42',
      );
    });

    test('maps infoPage query to /info/:id', () {
      expect(
        AppLinks.redirectFromUri(
            Uri.parse('https://ctrim.app/?infoPage=core_values')),
        '/info/core_values',
      );
      expect(
        AppLinks.redirectFromUri(Uri.parse(
            'https://ctrim.app/?infoPage=assets/info/ctrim_info/4xd.json')),
        '/info/4xd',
      );
    });

    test('returns null when there is no known query', () {
      expect(
        AppLinks.redirectFromUri(Uri.parse('https://ctrim.app/')),
        isNull,
      );
    });

    test('prefers postId when both query params are present', () {
      expect(
        AppLinks.redirectFromUri(
          Uri.parse('https://ctrim.app/?postId=p1&infoPage=core_values'),
        ),
        '/post/p1',
      );
    });

    test('ignores empty postId', () {
      expect(
        AppLinks.redirectFromUri(Uri.parse('https://ctrim.app/?postId=')),
        isNull,
      );
    });

    test('encodes ids in the redirected path', () {
      expect(
        AppLinks.redirectFromUri(Uri.parse('https://ctrim.app/?postId=a b')),
        '/post/a%20b',
      );
    });
  });
}
