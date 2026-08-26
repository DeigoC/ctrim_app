import 'package:ctrim_app/utility/network_image_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkImageHelper.needsCorsProxy', () {
    test('is true for Drive share and uc links', () {
      expect(
        NetworkImageHelper.needsCorsProxy(
          'https://drive.google.com/file/d/1abc/view?usp=drivesdk',
        ),
        isTrue,
      );
      expect(
        NetworkImageHelper.needsCorsProxy(
          'https://drive.google.com/uc?id=1abc',
        ),
        isTrue,
      );
      expect(
        NetworkImageHelper.needsCorsProxy(
          'https://drive.usercontent.google.com/download?id=1abc',
        ),
        isTrue,
      );
    });

    test('is false for public image hosts', () {
      expect(
        NetworkImageHelper.needsCorsProxy('https://example.com/photo.jpg'),
        isFalse,
      );
      expect(
        NetworkImageHelper.needsCorsProxy(
          'https://lh3.googleusercontent.com/d/1abc',
        ),
        isFalse,
      );
      expect(
        NetworkImageHelper.needsCorsProxy(
          'https://images.unsplash.com/photo-123',
        ),
        isFalse,
      );
    });

    test('is false for empty or invalid urls', () {
      expect(NetworkImageHelper.needsCorsProxy(''), isFalse);
      expect(NetworkImageHelper.needsCorsProxy('   '), isFalse);
      expect(NetworkImageHelper.needsCorsProxy('not a url'), isFalse);
    });
  });

  group('NetworkImageHelper.getImageUrl', () {
    test('returns original url on VM (non-web)', () {
      const drive = 'https://drive.google.com/uc?id=1abc';
      const public = 'https://example.com/photo.jpg';
      expect(NetworkImageHelper.getImageUrl(drive), drive);
      expect(NetworkImageHelper.getImageUrl(public), public);
    });
  });

  group('NetworkImageHelper.sanitizeMediaUrl', () {
    test('converts Drive file share links to uc?id=', () {
      expect(
        NetworkImageHelper.sanitizeMediaUrl(
          'https://drive.google.com/file/d/1abcXYZ/view?usp=sharing',
        ),
        'https://drive.google.com/uc?id=1abcXYZ',
      );
      expect(
        NetworkImageHelper.sanitizeMediaUrl(
          'https://drive.google.com/file/d/1abcXYZ/view?usp=drive_link',
        ),
        'https://drive.google.com/uc?id=1abcXYZ',
      );
    });

    test('leaves direct and non-Drive urls trimmed only', () {
      expect(
        NetworkImageHelper.sanitizeMediaUrl(
          '  https://drive.google.com/uc?id=1abc  ',
        ),
        'https://drive.google.com/uc?id=1abc',
      );
      expect(
        NetworkImageHelper.sanitizeMediaUrl(' https://example.com/a.png '),
        'https://example.com/a.png',
      );
      expect(NetworkImageHelper.sanitizeMediaUrl(''), '');
    });
  });
}
