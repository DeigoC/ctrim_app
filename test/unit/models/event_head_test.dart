import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_head.dart';

void main() {
  group('EventHead', () {
    group('constructor', () {
      test('creates with required id and default values', () {
        final head = EventHead(id: 'event-1');

        expect(head.id, 'event-1');
        expect(head.title, '');
        expect(head.subtitle, '');
        expect(head.location, 'Belfast');
        expect(head.tagIDs, isEmpty);
        expect(head.eventDate, isNull);
        expect(head.hasEventDate, false);
        expect(head.hasMedia, false);
        expect(head.mediaCount, 0);
        expect(head.interestedCount, 0);
        expect(head.attendeeCount, 0);
        expect(head.hasAttendanceCounts, false);
      });

      test('creates with all parameters', () {
        final head = EventHead(
          id: 'event-2',
          title: 'Youth Camp',
          subtitle: 'Annual gathering',
          location: 'Dublin',
        );

        expect(head.title, 'Youth Camp');
        expect(head.subtitle, 'Annual gathering');
        expect(head.location, 'Dublin');
      });
    });

    group('fromMap', () {
      test('creates from a map with Timestamps', () {
        final now = DateTime(2024, 6, 15, 10, 0);
        final eventDate = DateTime(2024, 7, 20, 14, 0);

        final map = {
          'Title': 'Summer Event',
          'Subtitle': 'A great event',
          'Location': 'Belfast',
          'Media': <Map<String, dynamic>>[],
          'RecentDate': Timestamp.fromDate(now),
          'EventDate': Timestamp.fromDate(eventDate),
          'InterestedCount': 3,
          'AttendeeCount': 5,
        };

        final head = EventHead.fromMap('event-3', map);

        expect(head.id, 'event-3');
        expect(head.title, 'Summer Event');
        expect(head.subtitle, 'A great event');
        expect(head.location, 'Belfast');
        expect(head.recentDate, now);
        expect(head.eventDate, eventDate);
        expect(head.interestedCount, 3);
        expect(head.attendeeCount, 5);
        expect(head.hasAttendanceCounts, true);
      });

      test('fromMap defaults missing attendance counts to zero', () {
        final map = {
          'Title': 'Legacy Event',
          'Subtitle': '',
          'Location': 'Belfast',
          'Media': <Map<String, dynamic>>[],
          'RecentDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'EventDate': null,
        };

        final head = EventHead.fromMap('legacy-1', map);
        expect(head.interestedCount, 0);
        expect(head.attendeeCount, 0);
      });

      test('creates from a map with null EventDate', () {
        final map = {
          'Title': 'No Date Event',
          'Subtitle': '',
          'Location': 'Belfast',
          'Media': <Map<String, dynamic>>[],
          'RecentDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'EventDate': null,
        };

        final head = EventHead.fromMap('event-4', map);

        expect(head.eventDate, isNull);
        expect(head.hasEventDate, false);
      });

      test('fromMap preserves media entries', () {
        final map = {
          'Title': 'Media Event',
          'Subtitle': '',
          'Location': 'Belfast',
          'Media': [
            {'src': 'img1.jpg', 'type': 'img', 'title': 'Photo 1', 'thumbnailSrc': null},
          ],
          'RecentDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'EventDate': null,
        };

        final head = EventHead.fromMap('event-5', map);

        expect(head.mediaCount, 1);
        expect(head.media.first['src'], 'img1.jpg');
      });
    });

    group('setters', () {
      test('setTitle updates title', () {
        final head = EventHead(id: 'e1', title: 'Old');
        head.setTitle('New Title');
        expect(head.title, 'New Title');
      });

      test('setSubtitle updates subtitle', () {
        final head = EventHead(id: 'e1', subtitle: 'Old Sub');
        head.setSubtitle('New Sub');
        expect(head.subtitle, 'New Sub');
      });

      test('setLocation updates location', () {
        final head = EventHead(id: 'e1');
        head.setLocation('Cork');
        expect(head.location, 'Cork');
      });

      test('setRecentDate updates recentDate', () {
        final head = EventHead(id: 'e1');
        final date = DateTime(2024, 3, 10);
        head.setRecentDate(date);
        expect(head.recentDate, date);
      });

      test('setEventDate updates eventDate', () {
        final head = EventHead(id: 'e1');
        final date = DateTime(2025, 12, 25);
        head.setEventDate(date);
        expect(head.eventDate, date);
        expect(head.hasEventDate, true);
      });

      test('removeEventDate sets eventDate to null', () {
        final head = EventHead(id: 'e1');
        head.setEventDate(DateTime(2025, 12, 25));
        head.removeEventDate();
        expect(head.eventDate, isNull);
        expect(head.hasEventDate, false);
      });

      test('setInterestedCount and setAttendeeCount clamp negatives', () {
        final head = EventHead(id: 'e1');
        head.setInterestedCount(4);
        head.setAttendeeCount(2);
        expect(head.interestedCount, 4);
        expect(head.attendeeCount, 2);
        head.setInterestedCount(-1);
        head.setAttendeeCount(-3);
        expect(head.interestedCount, 0);
        expect(head.attendeeCount, 0);
      });
    });

    group('event status', () {
      test('isUpcoming is true when eventDate is in the future', () {
        final head = EventHead(id: 'e1');
        head.setEventDate(DateTime.now().add(const Duration(days: 5)));
        expect(head.isUpcoming, true);
        expect(head.isRecent, false);
      });

      test('isRecent is true when eventDate is in the past', () {
        final head = EventHead(id: 'e1');
        head.setEventDate(DateTime.now().subtract(const Duration(days: 5)));
        expect(head.isRecent, true);
        expect(head.isUpcoming, false);
      });

      test('eventStatusText returns "No date set" when no event date', () {
        final head = EventHead(id: 'e1');
        expect(head.eventStatusText, 'No date set');
      });

      test('eventStatusText returns "Upcoming" for future events', () {
        final head = EventHead(id: 'e1');
        head.setEventDate(DateTime.now().add(const Duration(days: 3)));
        expect(head.eventStatusText, 'Upcoming');
      });

      test('eventStatusText returns "Recent" for past events', () {
        final head = EventHead(id: 'e1');
        head.setEventDate(DateTime.now().subtract(const Duration(days: 3)));
        expect(head.eventStatusText, 'Recent');
      });

      test('eventStatusColor returns grey when no event date', () {
        final head = EventHead(id: 'e1');
        expect(head.eventStatusColor, Colors.grey);
      });

      test('eventStatusColor returns green for upcoming events', () {
        final head = EventHead(id: 'e1');
        head.setEventDate(DateTime.now().add(const Duration(days: 3)));
        expect(head.eventStatusColor, Colors.green);
      });

      test('eventStatusColor returns orange for recent events', () {
        final head = EventHead(id: 'e1');
        head.setEventDate(DateTime.now().subtract(const Duration(days: 3)));
        expect(head.eventStatusColor, Colors.orange);
      });

      test('timeUntilEvent returns null when no event date', () {
        final head = EventHead(id: 'e1');
        expect(head.timeUntilEvent, isNull);
      });

      test('timeUntilEvent is positive for upcoming events', () {
        final head = EventHead(id: 'e1');
        head.setEventDate(DateTime.now().add(const Duration(days: 2)));
        expect(head.timeUntilEvent!.inDays, greaterThan(0));
      });

      test('formattedTimeUntilEvent returns empty string when no date', () {
        final head = EventHead(id: 'e1');
        expect(head.formattedTimeUntilEvent, '');
      });

      test('formattedTimeUntilEvent returns "In X days" for upcoming events', () {
        final head = EventHead(id: 'e1');
        head.setEventDate(DateTime.now().add(const Duration(days: 5)));
        expect(head.formattedTimeUntilEvent, startsWith('In '));
        expect(head.formattedTimeUntilEvent, contains('days'));
      });

      test('formattedTimeUntilEvent returns "X days ago" for past events', () {
        final head = EventHead(id: 'e1');
        head.setEventDate(DateTime.now().subtract(const Duration(days: 5)));
        expect(head.formattedTimeUntilEvent, endsWith('days ago'));
      });
    });

    group('media management', () {
      test('addMediaItem adds an entry', () {
        final head = EventHead(id: 'e1');
        head.addMediaItem(type: 'img', src: 'photo.jpg', title: 'Photo');

        expect(head.hasMedia, true);
        expect(head.mediaCount, 1);
        expect(head.imageCount, 1);
        expect(head.videoCount, 0);
      });

      test('addMediaItem adds a video entry', () {
        final head = EventHead(id: 'e1');
        head.addMediaItem(type: 'video', src: 'clip.mp4');

        expect(head.videoCount, 1);
        expect(head.imageCount, 0);
      });

      test('containsMediaItem returns true when src exists', () {
        final head = EventHead(id: 'e1');
        head.addMediaItem(type: 'img', src: 'photo.jpg');

        expect(head.containsMediaItem('photo.jpg'), true);
        expect(head.containsMediaItem('other.jpg'), false);
      });

      test('removeMediaItem removes the entry', () {
        final head = EventHead(id: 'e1');
        head.addMediaItem(type: 'img', src: 'photo.jpg');
        final entry = head.media.first;
        head.removeMediaItem(entry);

        expect(head.mediaCount, 0);
        expect(head.hasMedia, false);
      });

      test('clearMedia removes all entries', () {
        final head = EventHead(id: 'e1');
        head.addMediaItem(type: 'img', src: 'a.jpg');
        head.addMediaItem(type: 'img', src: 'b.jpg');
        head.clearMedia();

        expect(head.mediaCount, 0);
      });

      test('resetMediaWithOriginal restores given entries', () {
        final head = EventHead(id: 'e1');
        head.addMediaItem(type: 'img', src: 'old.jpg');
        final original = [
          {'src': 'restored.jpg', 'type': 'img', 'title': '', 'thumbnailSrc': null}
        ];
        head.resetMediaWithOriginal(original);

        expect(head.mediaCount, 1);
        expect(head.media.first['src'], 'restored.jpg');
      });

      test('getKeyGraphic returns first image src', () {
        final head = EventHead(id: 'e1');
        head.addMediaItem(type: 'video', src: 'clip.mp4');
        head.addMediaItem(type: 'img', src: 'photo.jpg');

        expect(head.getKeyGraphic(), 'photo.jpg');
      });

      test('getKeyGraphic returns null when no images exist', () {
        final head = EventHead(id: 'e1');
        head.addMediaItem(type: 'video', src: 'clip.mp4');

        expect(head.getKeyGraphic(), isNull);
      });

      test('getKeyGraphic falls back to lead speaker image', () {
        final head = EventHead(id: 'e1');
        head.setLeadSpeaker(uid: 'u1', imgSrc: 'speaker.jpg', name: 'Alex');

        expect(head.getKeyGraphic(), 'speaker.jpg');
        expect(head.hasLeadSpeakerPortrait, true);
      });

      test('clearLeadSpeaker removes denormalized fields', () {
        final head = EventHead(id: 'e1');
        head.setLeadSpeaker(uid: 'u1', imgSrc: 'speaker.jpg', name: 'Alex');
        head.clearLeadSpeaker();

        expect(head.hasLeadSpeaker, false);
        expect(head.leadSpeakerImgSrc, isNull);
        expect(head.getKeyGraphic(), isNull);
      });

      test('media getter returns an unmodifiable view', () {
        final head = EventHead(id: 'e1');
        expect(() => head.media.add({}), throwsUnsupportedError);
      });
    });

    group('toJson', () {
      test('serialises to a map with correct keys', () {
        final head = EventHead(id: 'e1', title: 'Test', subtitle: 'Sub', location: 'Belfast');

        final json = head.toJson() as Map<String, dynamic>;

        expect(json['ID'], 'e1');
        expect(json['Title'], 'Test');
        expect(json['Subtitle'], 'Sub');
        expect(json['Location'], 'Belfast');
        expect(json['Media'], isA<List>());
        expect(json['RecentDate'], isA<Timestamp>());
        expect(json['EventDate'], isNull);
        expect(json['InterestedCount'], 0);
        expect(json['AttendeeCount'], 0);
        expect(json['LeadSpeakerUID'], isNull);
        expect(json['LeadSpeakerImgSrc'], isNull);
        expect(json['LeadSpeakerName'], isNull);
      });

      test('toJson includes EventDate when set', () {
        final head = EventHead(id: 'e1');
        final eventDate = DateTime(2025, 6, 1);
        head.setEventDate(eventDate);

        final json = head.toJson() as Map<String, dynamic>;

        expect(json['EventDate'], isA<Timestamp>());
      });
    });
  });
}
