import 'package:ctrim_app/utility/event_notification_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventNotificationCopy', () {
    final now = DateTime(2026, 7, 9, 12, 0);
    final upcoming = DateTime(2026, 7, 12, 10, 0);
    final past = DateTime(2026, 7, 1, 10, 0);

    test('defaultSource prefers preset for upcoming events', () {
      expect(
        EventNotificationCopy.defaultSource(
          subtitle: 'A normal subtitle',
          eventDate: upcoming,
          now: now,
        ),
        BroadcastBodySource.preset,
      );
    });

    test('defaultSource uses subtitle when no upcoming date', () {
      expect(
        EventNotificationCopy.defaultSource(
          subtitle: 'A normal subtitle',
          eventDate: past,
          now: now,
        ),
        BroadcastBodySource.subtitle,
      );
      expect(
        EventNotificationCopy.defaultSource(
          subtitle: 'A normal subtitle',
          eventDate: null,
          now: now,
        ),
        BroadcastBodySource.subtitle,
      );
    });

    test('defaultSource falls back to custom when subtitle empty', () {
      expect(
        EventNotificationCopy.defaultSource(
          subtitle: '  ',
          eventDate: null,
          now: now,
        ),
        BroadcastBodySource.custom,
      );
    });

    test('presetBodies for dated events include reminder wording', () {
      final presets = EventNotificationCopy.presetBodies(
        title: 'Sunday Service',
        eventDate: upcoming,
        now: now,
      );
      expect(presets, isNotEmpty);
      expect(presets.first, contains('Coming up'));
      expect(presets.first, contains('Jul 12'));
      expect(presets.any((p) => p.contains('Reminder')), isTrue);
      expect(presets.any((p) => p.contains('Sunday Service')), isTrue);
    });

    test('presetBodies without date are generic', () {
      final presets = EventNotificationCopy.presetBodies(
        title: 'Update',
        eventDate: null,
      );
      expect(presets, contains('Check out this update'));
    });

    test('resolveBody returns the selected source text', () {
      expect(
        EventNotificationCopy.resolveBody(
          source: BroadcastBodySource.subtitle,
          subtitle: ' Post subtitle ',
          customBody: 'custom',
          selectedPreset: 'preset',
        ),
        'Post subtitle',
      );
      expect(
        EventNotificationCopy.resolveBody(
          source: BroadcastBodySource.preset,
          subtitle: 'subtitle',
          customBody: 'custom',
          selectedPreset: ' Coming up ',
        ),
        'Coming up',
      );
      expect(
        EventNotificationCopy.resolveBody(
          source: BroadcastBodySource.custom,
          subtitle: 'subtitle',
          customBody: ' Edited body ',
          selectedPreset: 'preset',
        ),
        'Edited body',
      );
    });

    test('relativePhrase for upcoming and past', () {
      expect(
        EventNotificationCopy.relativePhrase(upcoming, now: now),
        'In 2 days',
      );
      expect(
        EventNotificationCopy.relativePhrase(past, now: now),
        '8 days ago',
      );
    });
  });
}
