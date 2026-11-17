import 'package:ctrim_app/models/event/event_media.dart';
import 'package:ctrim_app/models/event/event_metadata.dart';
import 'package:ctrim_app/models/event/event_program.dart';
import 'package:ctrim_app/pages/events/view_event_remote_load.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fetchPostEssentialsParallel', () {
    test('returns all four parts when futures complete', () async {
      final media = EventMedia();
      final metadata = EventMetadata(authorUID: 'author-1');
      final program = EventProgram();
      const body = '[{"insert":"Hello\\n"}]';

      final result = await fetchPostEssentialsParallel(
        media: Future.value(media),
        metadata: Future.value(metadata),
        program: Future.value(program),
        body: Future.value(body),
      );

      expect(identical(result.media, media), isTrue);
      expect(identical(result.metadata, metadata), isTrue);
      expect(identical(result.program, program), isTrue);
      expect(result.body, body);
    });

    test('waits for the slowest future, not the sum of each', () async {
      final started = DateTime.now();
      Future<T> delayed<T>(T value, int ms) =>
          Future<T>.delayed(Duration(milliseconds: ms), () => value);

      await fetchPostEssentialsParallel(
        media: delayed(EventMedia(), 40),
        metadata: delayed(EventMetadata(authorUID: 'a'), 40),
        program: delayed(EventProgram(), 40),
        body: delayed('[]', 40),
      );

      final elapsed = DateTime.now().difference(started);
      // Sequential would be ~160ms; parallel should stay near one delay.
      expect(elapsed.inMilliseconds, lessThan(120));
    });

    test('propagates the first failure', () async {
      await expectLater(
        fetchPostEssentialsParallel(
          media: Future.value(EventMedia()),
          metadata: Future.error(StateError('metadata missing')),
          program: Future.value(EventProgram()),
          body: Future.value('[]'),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
