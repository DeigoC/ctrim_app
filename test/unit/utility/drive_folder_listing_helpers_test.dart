import 'package:ctrim_app/pages/events/add_media_drive_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractDriveFolderId', () {
    test('reads folder share links and bare ids', () {
      expect(
        extractDriveFolderId(
          'https://drive.google.com/drive/folders/1KpLl_1tcK0eeehzN980zbG-3M2nhbVks',
        ),
        '1KpLl_1tcK0eeehzN980zbG-3M2nhbVks',
      );
      expect(
        extractDriveFolderId(
          'https://drive.google.com/drive/u/0/folders/1KpLl_1tcK0eeehzN980zbG-3M2nhbVks?usp=sharing',
        ),
        '1KpLl_1tcK0eeehzN980zbG-3M2nhbVks',
      );
      expect(
        extractDriveFolderId('1KpLl_1tcK0eeehzN980zbG-3M2nhbVks'),
        '1KpLl_1tcK0eeehzN980zbG-3M2nhbVks',
      );
    });

    test('rejects file share links and empty text', () {
      expect(
        extractDriveFolderId(
          'https://drive.google.com/file/d/abc123_XYZ/view?usp=sharing',
        ),
        isNull,
      );
      expect(extractDriveFolderId(''), isNull);
      expect(extractDriveFolderId('not-a-link'), isNull);
    });
  });

  group('parseDriveEmbeddedFolderView', () {
    test('extracts files, mime types, and folders from flip-entry HTML', () {
      const html = '''
<div class="flip-entries">
<div class="flip-entry" id="entry-folderId12345" tabindex="0" role="link">
  <div class="flip-entry-info">
    <a href="https://drive.google.com/drive/folders/folderId12345">
      <div class="flip-entry-title">nested</div>
    </a>
  </div>
</div>
<div class="flip-entry" id="entry-imageId1234567890" tabindex="0" role="link">
  <div class="flip-entry-info">
    <a href="https://drive.google.com/file/d/imageId1234567890/view?usp=drive_web">
      <img src="https://drive-thirdparty.googleusercontent.com/16/type/image%2Fjpeg" alt=""/>
      <div class="flip-entry-title">fractal.jpg</div>
    </a>
  </div>
</div>
<div class="flip-entry" id="entry-videoId1234567890" tabindex="0" role="link">
  <div class="flip-entry-info">
    <a href="https://drive.google.com/file/d/videoId1234567890/view?usp=drive_web">
      <img src="https://drive-thirdparty.googleusercontent.com/16/type/video%2Fmp4" alt=""/>
      <div class="flip-entry-title">clip.mp4</div>
    </a>
  </div>
</div>
</div>
''';

      final entries = parseDriveEmbeddedFolderView(html);
      expect(entries, hasLength(3));

      expect(entries[0].isFolder, isTrue);
      expect(entries[0].name, 'nested');
      expect(entries[0].isImportableMedia, isFalse);

      expect(entries[1].id, 'imageId1234567890');
      expect(entries[1].name, 'fractal.jpg');
      expect(entries[1].mimeType, 'image/jpeg');
      expect(entries[1].isImage, isTrue);
      expect(entries[1].isImportableMedia, isTrue);
      expect(entries[1].directMediaUrl,
          'https://drive.google.com/uc?id=imageId1234567890');

      expect(entries[2].isVideo, isTrue);
      expect(entries[2].mediaType, 'vid');
    });

    test('returns empty for unrelated HTML', () {
      expect(parseDriveEmbeddedFolderView('<html></html>'), isEmpty);
    });
  });

  group('splitMediaUrlList', () {
    test('splits lines and whitespace', () {
      expect(
        splitMediaUrlList(
          'https://a.example/a.jpg\n'
          'https://b.example/b.png  https://c.example/c.gif\n\n',
        ),
        [
          'https://a.example/a.jpg',
          'https://b.example/b.png',
          'https://c.example/c.gif',
        ],
      );
    });
  });
}
