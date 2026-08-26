import 'package:ctrim_app/models/info/info_parsing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InfoParsing.isEmptyBody', () {
    test('treats the default delta as empty', () {
      expect(InfoParsing.isEmptyBody(InfoParsing.defaultBody()), isTrue);
    });

    test('treats an empty list as empty', () {
      expect(InfoParsing.isEmptyBody(const []), isTrue);
    });

    test('treats whitespace-only inserts as empty', () {
      expect(
        InfoParsing.isEmptyBody([
          {'insert': '  \n'}
        ]),
        isTrue,
      );
    });

    test('treats text content as not empty', () {
      expect(
        InfoParsing.isEmptyBody([
          {'insert': 'Hello\n'}
        ]),
        isFalse,
      );
    });

    test('treats embeds as not empty', () {
      expect(
        InfoParsing.isEmptyBody([
          {
            'insert': {'image': 'https://example.com/a.png'}
          }
        ]),
        isFalse,
      );
    });
  });
}
