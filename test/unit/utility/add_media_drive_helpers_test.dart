import 'package:ctrim_app/pages/events/add_media_drive_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const imageUrl = 'https://example.com/photo.jpg';
  const driveShare =
      'https://drive.google.com/file/d/abc123_XYZ/view?usp=sharing';

  group('isTestableMediaUrl', () {
    test('accepts https links and Drive share links', () {
      expect(isTestableMediaUrl(imageUrl), isTrue);
      expect(isTestableMediaUrl('  $driveShare  '), isTrue);
      expect(isTestableMediaUrl('drive.google.com/file/d/abc123'), isTrue);
    });

    test('rejects empty text and bare words', () {
      expect(isTestableMediaUrl(''), isFalse);
      expect(isTestableMediaUrl('   '), isFalse);
      expect(isTestableMediaUrl('photo.jpg'), isFalse);
    });
  });

  group('shouldAutoTestMediaUrlNow', () {
    test('checks a pasted link immediately', () {
      expect(shouldAutoTestMediaUrlNow('', imageUrl), isTrue);
      expect(shouldAutoTestMediaUrlNow('', driveShare), isTrue);
      expect(
        shouldAutoTestMediaUrlNow('https://old.example/a.png', imageUrl),
        isTrue,
      );
    });

    test('waits while the link is still a keystroke', () {
      expect(
        shouldAutoTestMediaUrlNow(
          'https://example.com/photo.jp',
          imageUrl,
        ),
        isFalse,
      );
      expect(shouldAutoTestMediaUrlNow(imageUrl, imageUrl), isFalse);
      expect(shouldAutoTestMediaUrlNow('', 'https:/'), isFalse);
      expect(shouldAutoTestMediaUrlNow('', 'not a url'), isFalse);
    });
  });

  group('shouldAutoTestMediaUrlAfterPause', () {
    test('checks after a pause when one character completes the link', () {
      expect(
        shouldAutoTestMediaUrlAfterPause(
          'https://example.com/photo.jp',
          imageUrl,
        ),
        isTrue,
      );
    });

    test('does not pause-check a paste or text that is not a link yet', () {
      expect(shouldAutoTestMediaUrlAfterPause('', imageUrl), isFalse);
      expect(shouldAutoTestMediaUrlAfterPause('photo', 'photo.'), isFalse);
    });
  });

  group('isSingleCharacterMediaUrlEdit', () {
    test('detects one inserted, replaced, or deleted character', () {
      expect(
        isSingleCharacterMediaUrlEdit('https://a.co/b', 'https://a.co/bc'),
        isTrue,
      );
      expect(
        isSingleCharacterMediaUrlEdit('https://a.co/bc', 'https://a.co/b'),
        isTrue,
      );
      expect(
        isSingleCharacterMediaUrlEdit('https://a.co/b', 'https://a.co/c'),
        isTrue,
      );
    });

    test('treats a paste as more than one character', () {
      expect(isSingleCharacterMediaUrlEdit('', imageUrl), isFalse);
      expect(
        isSingleCharacterMediaUrlEdit(imageUrl, '$imageUrl?size=2'),
        isFalse,
      );
    });
  });
}
