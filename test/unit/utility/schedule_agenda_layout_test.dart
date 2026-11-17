import 'package:ctrim_app/utility/schedule_agenda_layout.dart';
import 'package:ctrim_app/utility/team_rota.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> role({
  required int id,
  required String title,
  DateTime? start,
  DateTime? end,
  List<String> uids = const [],
  bool standing = false,
  List<String> tagIDs = const [],
}) {
  return <String, dynamic>{
    'uids': uids,
    'detail': '',
    'title': title,
    'start': start,
    'end': end,
    'for_guests': true,
    'id': id,
    'tagIDs': tagIDs,
    'standing': standing,
  };
}

void main() {
  group('ScheduleAgendaLayout', () {
    final day = DateTime(2026, 10, 18);

    DateTime at(int hour, [int minute = 0]) =>
        DateTime(day.year, day.month, day.day, hour, minute);

    test('standing duties sit above back-to-back turns', () {
      final layout = ScheduleAgendaLayout.build([
        role(
          id: 1,
          title: 'Intercessory Prayer',
          start: at(9),
          end: at(9, 50),
          tagIDs: ['speakers'],
        ),
        role(
          id: 2,
          title: 'Technical Sound',
          start: at(9),
          standing: true,
          uids: ['sound'],
          tagIDs: ['tech'],
        ),
        role(
          id: 3,
          title: 'Opening Praise',
          start: at(10, 10),
          end: at(10, 35),
          uids: ['worship'],
          tagIDs: ['worship'],
        ),
      ]);

      expect(layout.duties.map((duty) => duty.roleId), [2]);
      expect(layout.clusters.map((cluster) => cluster.start), [
        at(9),
        at(10, 10),
      ]);
      expect(
        layout.clusters.expand((cluster) => cluster.turns).map((t) => t.roleId),
        [1, 3],
      );
    });

    test('overlapping turns share one cluster and the earlier start', () {
      final layout = ScheduleAgendaLayout.build([
        role(id: 1, title: 'A', start: at(10), end: at(10, 30)),
        role(id: 2, title: 'B', start: at(10, 15), end: at(10, 45)),
        role(id: 3, title: 'C', start: at(12), end: at(12, 10)),
      ]);

      expect(layout.clusters.length, 2);
      expect(layout.clusters.first.start, at(10));
      expect(layout.clusters.first.turns.map((t) => t.roleId), [1, 2]);
      expect(layout.clusters.last.start, at(12));
    });

    test('a long coverage role leaves the running order', () {
      final layout = ScheduleAgendaLayout.build([
        role(
          id: 1,
          title: 'Technical Sound',
          start: at(9),
          end: at(12),
          uids: ['a', 'b'],
        ),
        role(
          id: 2,
          title: 'Praise',
          start: at(10, 10),
          end: at(10, 35),
          uids: ['a', 'b'],
        ),
        role(
          id: 3,
          title: 'Word',
          start: at(10, 45),
          end: at(11, 45),
          uids: ['c'],
        ),
      ]);

      expect(layout.duties.single.title, 'Technical Sound');
      final praise = layout.clusters
          .expand((cluster) => cluster.turns)
          .firstWhere((turn) => turn.roleId == 2);
      final word = layout.clusters
          .expand((cluster) => cluster.turns)
          .firstWhere((turn) => turn.roleId == 3);
      expect(praise.sameAsDutyTitle, 'Technical Sound');
      expect(word.sameAsDutyTitle, isNull);
      expect(praise.durationFraction, closeTo(25 / 60, 0.001));
      expect(word.durationFraction, 1);
    });

    test('empty assignee lists do not count as the same team', () {
      final layout = ScheduleAgendaLayout.build([
        role(
          id: 1,
          title: 'Praise and Worship',
          start: at(9),
          standing: true,
        ),
        role(
          id: 2,
          title: 'Opening Praise',
          start: at(10, 10),
          end: at(10, 35),
        ),
        role(
          id: 3,
          title: 'Word',
          start: at(10, 35),
          end: at(11, 35),
          uids: ['speaker'],
        ),
      ]);

      final opening = layout.clusters
          .expand((cluster) => cluster.turns)
          .firstWhere((turn) => turn.roleId == 2);
      expect(opening.sameAsDutyTitle, isNull);
    });

    test('a short turn keeps a visible duration bar', () {
      final layout = ScheduleAgendaLayout.build([
        role(id: 1, title: 'Song', start: at(11, 40), end: at(11, 45)),
        role(id: 2, title: 'Meeting', start: at(13), end: at(15)),
      ]);

      final song = layout.clusters.first.turns.single;
      final meeting = layout.clusters.last.turns.single;
      expect(song.durationFraction, ScheduleAgendaLayout.minDurationFraction);
      expect(meeting.durationFraction, 1);
    });

    test('titlesAssignedTo follows start time, whole-event first', () {
      final layout = ScheduleAgendaLayout.build([
        role(
          id: 1,
          title: 'Closing Song',
          start: at(11, 40),
          end: at(11, 45),
          uids: ['me'],
        ),
        role(
          id: 2,
          title: 'Praise and Worship',
          start: at(9),
          standing: true,
          uids: ['me'],
        ),
        role(
          id: 3,
          title: 'Opening Praise',
          start: at(10, 10),
          end: at(10, 35),
          uids: ['me'],
        ),
        role(
          id: 4,
          title: 'Word',
          start: at(10, 35),
          end: at(11, 35),
          uids: ['other'],
        ),
      ]);

      expect(layout.titlesAssignedTo('me'), [
        'Praise and Worship',
        'Opening Praise',
        'Closing Song',
      ]);
      expect(layout.titlesAssignedTo(''), isEmpty);
    });

    test('first gap follows visual order and the include filter', () {
      final layout = ScheduleAgendaLayout.build([
        role(
          id: 1,
          title: 'Sound',
          start: at(9),
          standing: true,
          tagIDs: ['tech'],
        ),
        role(
          id: 2,
          title: 'Prayer',
          start: at(9),
          end: at(9, 20),
          tagIDs: ['speakers'],
        ),
        role(id: 3, title: 'Host'),
      ]);

      expect(
        layout.firstGapRoleId(
          (role) => TeamRotaQuery.roleMatchesTeamTags(
            role: role,
            selectedTagIDs: {'speakers'},
          ),
        ),
        2,
      );
      expect(
        layout.firstGapRoleId(
          (role) => TeamRotaQuery.roleMatchesTeamTags(
            role: role,
            selectedTagIDs: const {},
          ),
        ),
        1,
      );
      expect(layout.untimedRoles.single['id'], 3);
    });
  });
}
