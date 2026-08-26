import 'package:ctrim_app/pages/events/view_event_notify_helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  late DateFormat dateFormat;
  late DateFormat timeFormat;

  setUpAll(() async {
    await initializeDateFormatting('en_US');
    dateFormat = DateFormat('EEE, MMM d', 'en_US');
    timeFormat = DateFormat('HH:mm', 'en_US');
  });
  final eventDate = DateTime(2026, 8, 26, 19, 30);

  group('scheduledMemberReminderTitle', () {
    test('includes the event date', () {
      expect(
        scheduledMemberReminderTitle(eventDate, dateFormat: dateFormat),
        '📣 Reminder of your task - Wed, Aug 26!',
      );
    });
  });

  group('scheduledMemberReminderBody', () {
    test('includes role, post title, and start time', () {
      expect(
        scheduledMemberReminderBody(
          roleTitle: 'Usher',
          postTitle: 'Sunday Service',
          startingTime: eventDate,
          timeFormat: timeFormat,
        ),
        "'Usher' for Sunday Service.\nStarting 19:30",
      );
    });
  });

  group('scheduledRoleRemindersFromProgram', () {
    test('skips roles without a start time and the current user', () {
      final reminders = scheduledRoleRemindersFromProgram(
        roles: [
          {
            'title': 'Missing start',
            'uids': ['a', 'b'],
          },
          {
            'title': 'Usher',
            'start': eventDate,
            'uids': ['current', 'other', 42],
          },
          {
            'start': eventDate,
            'uids': ['current'],
          },
        ],
        postTitle: 'Sunday Service',
        currentUid: 'current',
        timeFormat: timeFormat,
      );

      expect(reminders, hasLength(2));
      expect(reminders[0].roleTitle, 'Usher');
      expect(reminders[0].recipientUids, ['other']);
      expect(reminders[0].body, contains('Starting 19:30'));
      expect(reminders[1].roleTitle, 'Untitled Role');
      expect(reminders[1].recipientUids, isEmpty);
    });
  });
}
