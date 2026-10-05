import 'package:ctrim_app/utility/post_share_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostShareText', () {
    test('link is the public post address', () {
      expect(PostShareText.link('abc'), 'https://ctrim.app/post/abc');
    });

    test('write-up starts with the title and link, then the plain text', () {
      final text = PostShareText.writeUp(
        title: 'Sunday',
        postId: 'abc',
        body: [
          {'insert': 'Welcome everyone\n'},
        ],
      );

      expect(
        text,
        'Sunday\nhttps://ctrim.app/post/abc\n---\n\nWelcome everyone',
      );
    });

    test('write-up drops image markers', () {
      final text = PostShareText.writeUp(
        title: 'Sunday',
        postId: 'abc',
        body: [
          {
            'insert': {'image': 'https://example.com/a.jpg'}
          },
          {'insert': 'Caption\n'},
        ],
      );

      expect(text.contains('\uFFFC'), isFalse);
      expect(text, contains('Caption'));
      expect(text, isNot(contains('https://example.com/a.jpg')));
    });

    test('write-up uses the fallback when the body is not Quill JSON', () {
      final text = PostShareText.writeUp(
        title: 'Sunday',
        postId: 'abc',
        body: ['not a delta'],
        extractFailedMessage: 'failed',
      );

      expect(text, contains('failed'));
      expect(text, startsWith('Sunday\nhttps://ctrim.app/post/abc\n---'));
    });
  });
}
