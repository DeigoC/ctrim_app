import 'package:ctrim_app/utility/app_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLinks.postPath', () {
    test('encodes the id in /post/:id', () {
      expect(AppLinks.postPath('post-42'), '/post/post-42');
      expect(AppLinks.postPath('a b'), '/post/a%20b');
    });
  });

  group('AppLinks.postUrl', () {
    test('uses the public web origin', () {
      expect(AppLinks.postUrl('post-42'), 'https://ctrim.app/post/post-42');
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

    test('returns null when there is no postId', () {
      expect(
        AppLinks.redirectFromUri(Uri.parse('https://ctrim.app/')),
        isNull,
      );
      expect(
        AppLinks.redirectFromUri(
            Uri.parse('https://ctrim.app/?infoPage=core_values')),
        isNull,
      );
    });

    test('ignores empty postId', () {
      expect(
        AppLinks.redirectFromUri(Uri.parse('https://ctrim.app/?postId=')),
        isNull,
      );
    });
  });
}
