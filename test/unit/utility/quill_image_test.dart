import 'package:ctrim_app/utility/quill_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuillImage.sanitizeUrl', () {
    test('converts Drive file share links to uc?id=', () {
      expect(
        QuillImage.sanitizeUrl(
          'https://drive.google.com/file/d/1abcXYZ/view?usp=sharing',
        ),
        'https://drive.google.com/uc?id=1abcXYZ',
      );
    });

    test('trims direct HTTPS urls', () {
      expect(
        QuillImage.sanitizeUrl(' https://example.com/a.png '),
        'https://example.com/a.png',
      );
    });
  });

  group('QuillImage.isHttpUrl', () {
    test('accepts http and https with a host', () {
      expect(QuillImage.isHttpUrl('https://example.com/a.png'), isTrue);
      expect(QuillImage.isHttpUrl('http://example.com/a.png'), isTrue);
    });

    test('rejects empty, relative, and non-http schemes', () {
      expect(QuillImage.isHttpUrl(''), isFalse);
      expect(QuillImage.isHttpUrl('  '), isFalse);
      expect(QuillImage.isHttpUrl('/local/path.png'), isFalse);
      expect(QuillImage.isHttpUrl('javascript:alert(1)'), isFalse);
      expect(QuillImage.isHttpUrl('file:///tmp/a.png'), isFalse);
    });
  });

  group('QuillImage.trySanitizeHttpUrl', () {
    test('returns the Drive direct link for a share URL', () {
      expect(
        QuillImage.trySanitizeHttpUrl(
          'https://drive.google.com/file/d/1abcXYZ/view?usp=drive_link',
        ),
        'https://drive.google.com/uc?id=1abcXYZ',
      );
    });

    test('returns null for non-http input', () {
      expect(QuillImage.trySanitizeHttpUrl('not a url'), isNull);
      expect(QuillImage.trySanitizeHttpUrl(''), isNull);
    });
  });

  group('QuillImage.sanitizeDeltaImageUrls', () {
    test('rewrites image embeds and leaves text ops unchanged', () {
      final delta = <dynamic>[
        {'insert': 'Hello\n'},
        {
          'insert': {
            'image':
                'https://drive.google.com/file/d/1abcXYZ/view?usp=sharing',
          }
        },
        {'insert': '\n'},
      ];

      final sanitized = QuillImage.sanitizeDeltaImageUrls(delta);
      expect((sanitized[0] as Map)['insert'], 'Hello\n');
      expect(
        ((sanitized[1] as Map)['insert'] as Map)['image'],
        'https://drive.google.com/uc?id=1abcXYZ',
      );
    });

    test('leaves already-direct image urls unchanged', () {
      const url = 'https://example.com/a.png';
      final delta = <dynamic>[
        {
          'insert': {'image': url}
        },
      ];
      final sanitized = QuillImage.sanitizeDeltaImageUrls(delta);
      expect(((sanitized[0] as Map)['insert'] as Map)['image'], url);
    });
  });

  group('QuillImage.stripEmbedsFromPlainText', () {
    test('removes object-replacement characters', () {
      expect(
        QuillImage.stripEmbedsFromPlainText('Hello\uFFFC world\n'),
        'Hello world',
      );
    });

    test('strips the marker Quill uses for image embeds', () {
      final document = quill.Document.fromJson([
        {'insert': 'Before\n'},
        {
          'insert': {'image': 'https://example.com/a.png'}
        },
        {'insert': 'After\n'},
      ]);
      final stripped =
          QuillImage.stripEmbedsFromPlainText(document.toPlainText());
      expect(stripped.contains('\uFFFC'), isFalse);
      expect(stripped.contains('Before'), isTrue);
      expect(stripped.contains('After'), isTrue);
    });
  });

  group('QuillImage.insertUrl', () {
    test('inserts a sanitised image embed into the document', () {
      final controller = quill.QuillController(
        document: quill.Document(),
        selection: const TextSelection.collapsed(offset: 0),
      );
      QuillImage.insertUrl(
        controller: controller,
        url: 'https://example.com/photo.png',
      );

      final json = controller.document.toDelta().toJson();
      final hasImage = json.any((op) {
        final insert = (op as Map)['insert'];
        return insert is Map &&
            insert['image'] == 'https://example.com/photo.png';
      });
      expect(hasImage, isTrue);
      controller.dispose();
    });
  });
}
