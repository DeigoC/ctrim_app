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
      expect(
        AppLinks.churchStatisticsPath('belfast'),
        '/churches/belfast/statistics',
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
        AppLinks.redirectFromUri(Uri.parse('https://ctrim.app/bulletin')),
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

  group('AppLinks home tabs', () {
    test('builds a path for each main section', () {
      expect(AppLinks.homeTabPath(AppLinks.bulletinTab), '/bulletin');
      expect(AppLinks.homeTabPath(AppLinks.ctrimTab), '/ctrim');
      expect(AppLinks.homeTabPath(AppLinks.cellGroupsTab), '/cell-groups');
      expect(AppLinks.homeTabPath(AppLinks.personalTab), '/personal');
    });

    test('clamps an unknown startup tab to CTRIM', () {
      expect(AppLinks.homeTabPath(99), '/ctrim');
      expect(AppLinks.clampHomeTab(-1), AppLinks.ctrimTab);
    });

    test('reads a section path and ignores record links', () {
      expect(AppLinks.homeTabIndexForPath('/personal'), AppLinks.personalTab);
      expect(
        AppLinks.homeTabIndexForPath('/cell-groups'),
        AppLinks.cellGroupsTab,
      );
      expect(AppLinks.homeTabIndexForPath('/cell-groups/cg-1'), isNull);
      expect(AppLinks.homeTabIndexForPath('/post/post-42'), isNull);
      expect(AppLinks.homeTabIndexForPath('/'), isNull);
    });

    test('sends / to the startup tab and leaves a section link', () {
      expect(
        AppLinks.redirectLocation(
          Uri.parse('https://ctrim.app/'),
          preferredHomeTab: AppLinks.personalTab,
        ),
        '/personal',
      );
      expect(
        AppLinks.redirectLocation(
          Uri.parse('https://ctrim.app/bulletin'),
          preferredHomeTab: AppLinks.ctrimTab,
        ),
        isNull,
      );
    });

    test('still prefers a legacy post query over the startup tab', () {
      expect(
        AppLinks.redirectLocation(
          Uri.parse('https://ctrim.app/?postId=post-42'),
          preferredHomeTab: AppLinks.personalTab,
        ),
        '/post/post-42',
      );
    });

    test('steps a root permalink up to its section', () {
      expect(AppLinks.upPath('/post/post-42'), '/bulletin');
      expect(AppLinks.upPath('/cell-groups/cg-1'), '/cell-groups');
      expect(AppLinks.upPath('/churches/belfast'), '/ctrim');
      expect(AppLinks.upPath('/info/core_values'), '/ctrim');
      expect(AppLinks.upPath('/testimonials/t-1'), '/ctrim');
      expect(AppLinks.upPath('/people/u-1'), '/personal');
    });

    test('steps a nested church page up to that church', () {
      expect(
        AppLinks.upPath('/churches/belfast/pages/getting-here'),
        '/churches/belfast',
      );
      expect(AppLinks.upPath('/churches/belfast/pastors'), '/churches/belfast');
      expect(
        AppLinks.upPath('/churches/belfast/statistics'),
        '/churches/belfast',
      );
      expect(
        AppLinks.upPath('/churches/north%20coast/pastors'),
        '/churches/north%20coast',
      );
    });

    test('sends an unknown section segment to the startup tab', () {
      expect(
        AppLinks.redirectHomeTabSegment(
          'personal',
          preferredHomeTab: AppLinks.bulletinTab,
        ),
        isNull,
      );
      expect(
        AppLinks.redirectHomeTabSegment(
          'nope',
          preferredHomeTab: AppLinks.cellGroupsTab,
        ),
        '/cell-groups',
      );
    });
  });
}
