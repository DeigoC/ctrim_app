import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_body.dart';

void main() {
  group('EventBody', () {
    test('has a default JSON string on creation', () {
      final body = EventBody();
      expect(body.json, isNotEmpty);
    });

    test('decodedJson returns a list', () {
      final body = EventBody();
      expect(body.decodedJson, isA<List>());
    });

    test('setJson updates the stored JSON string', () {
      final body = EventBody();
      const newJson = r'[{"insert":"New content\n"}]';
      body.setJson(newJson);
      expect(body.json, newJson);
    });

    test('encodeJson encodes a list to a JSON string', () {
      final body = EventBody();
      final content = [
        {'insert': 'Hello world\n'}
      ];
      body.encodeJson(content);
      // After encoding, decodedJson should round-trip back to the same structure
      expect(body.decodedJson, isA<List>());
      expect((body.decodedJson.first as Map)['insert'], 'Hello world\n');
    });

    group('compareTo', () {
      test('returns 0 when comparing with the same content', () {
        final body = EventBody();
        final decoded = body.decodedJson;
        expect(body.compareTo(decoded), 0);
      });

      test('returns non-zero when comparing with different content', () {
        final body = EventBody();
        final differentContent = [
          {'insert': 'Different text\n'}
        ];
        expect(body.compareTo(differentContent), isNot(0));
      });
    });
  });
}
