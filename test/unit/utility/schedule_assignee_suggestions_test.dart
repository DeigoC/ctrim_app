import 'package:ctrim_app/utility/schedule_assignee_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> role({
  required int id,
  required String title,
  List<String> uids = const [],
  List<String> tagIDs = const [],
  DateTime? start,
  bool standing = false,
}) {
  return {
    'id': id,
    'title': title,
    'uids': uids,
    'tagIDs': tagIDs,
    'start': start,
    'standing': standing,
  };
}

void main() {
  group('ScheduleAssigneeSuggestions', () {
    final media = role(
      id: 1,
      title: 'Technical Media',
      uids: ['jane', 'sam'],
      tagIDs: ['media'],
      standing: true,
    );
    final video = role(
      id: 2,
      title: 'Countdown Video',
      tagIDs: ['media'],
      start: DateTime(2026, 6, 14, 9, 50),
    );
    final worship = role(
      id: 3,
      title: 'Praise and Worship',
      uids: ['ada', 'ben'],
      tagIDs: ['worship'],
      start: DateTime(2026, 6, 14, 10, 10),
    );
    final closing = role(
      id: 4,
      title: 'Closing Song',
      tagIDs: ['worship'],
      start: DateTime(2026, 6, 14, 12, 20),
    );
    final roles = [media, video, worship, closing];

    test('a timed item suggests the standing role that shares a ministry', () {
      final suggestions = ScheduleAssigneeSuggestions.forRole(
        role: video,
        roles: roles,
      );

      expect(suggestions.map((s) => s.sourceTitle), ['Technical Media']);
      expect(suggestions.single.uids, ['jane', 'sam']);
    });

    test('a later timed item suggests an earlier one with the same ministry',
        () {
      final suggestions = ScheduleAssigneeSuggestions.forRole(
        role: closing,
        roles: roles,
      );

      expect(suggestions.map((s) => s.sourceTitle), ['Praise and Worship']);
    });

    test('does not suggest itself or a line with no shared ministry', () {
      final suggestions = ScheduleAssigneeSuggestions.forRole(
        role: media,
        roles: roles,
      );

      expect(suggestions, isEmpty);
    });

    test('skips a source whose people are already on the line', () {
      final filled = role(
        id: 2,
        title: 'Countdown Video',
        uids: ['jane', 'sam', 'extra'],
        tagIDs: ['media'],
        start: DateTime(2026, 6, 14, 9, 50),
      );

      final suggestions = ScheduleAssigneeSuggestions.forRole(
        role: filled,
        roles: [media, filled],
      );

      expect(suggestions, isEmpty);
    });

    test('union adds missing people and keeps extras', () {
      final next = ScheduleAssigneeSuggestions.unionAssignees(
        current: ['extra', 'jane'],
        adding: ['jane', 'sam'],
      );

      expect(next, ['extra', 'jane', 'sam']);
    });
  });
}
