import 'package:ctrim_app/utility/schedule_timeline_layout.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> role({
  required int id,
  required String title,
  DateTime? start,
  DateTime? end,
}) {
  return <String, dynamic>{
    'uids': <String>[],
    'detail': '',
    'title': title,
    'start': start,
    'end': end,
    'for_guests': true,
    'id': id,
  };
}

ScheduleTimelinePlacement placementFor(
  final ScheduleTimelineLayout layout,
  final int roleId,
) {
  return layout.placements.firstWhere((final p) => p.roleId == roleId);
}

void main() {
  group('ScheduleTimelineLayout', () {
    test('empty roles produce an empty layout with no bounds', () {
      final layout = ScheduleTimelineLayout.build(roles: const []);

      expect(layout.isEmpty, isTrue);
      expect(layout.dayStart, isNull);
      expect(layout.dayEnd, isNull);
      expect(layout.totalMinutes, 0);
    });

    test('sequential roles all sit in a single lane', () {
      final layout = ScheduleTimelineLayout.build(roles: [
        role(
          id: 1,
          title: 'Welcome',
          start: DateTime(2026, 6, 14, 10, 0),
          end: DateTime(2026, 6, 14, 10, 15),
        ),
        role(
          id: 2,
          title: 'Worship',
          start: DateTime(2026, 6, 14, 10, 15),
          end: DateTime(2026, 6, 14, 10, 45),
        ),
        role(
          id: 3,
          title: 'Word',
          start: DateTime(2026, 6, 14, 10, 45),
          end: DateTime(2026, 6, 14, 11, 30),
        ),
      ]);

      expect(layout.placements.length, 3);
      expect(layout.hasOverlaps, isFalse);
      expect(layout.placements.every((final p) => p.laneIndex == 0), isTrue);
      expect(layout.placements.every((final p) => p.laneCount == 1), isTrue);
      expect(
        layout.placements.map((final p) => p.clusterIndex).toSet().length,
        3,
      );
    });

    test('bounds round out to whole hours', () {
      final layout = ScheduleTimelineLayout.build(roles: [
        role(
          id: 1,
          title: 'Prayer',
          start: DateTime(2026, 6, 14, 9, 20),
          end: DateTime(2026, 6, 14, 10, 40),
        ),
      ]);

      expect(layout.dayStart, DateTime(2026, 6, 14, 9, 0));
      expect(layout.dayEnd, DateTime(2026, 6, 14, 11, 0));
      expect(layout.totalMinutes, 120);
    });

    test('finishTime extends the axis past the last role', () {
      final layout = ScheduleTimelineLayout.build(
        roles: [
          role(
            id: 1,
            title: 'Prayer',
            start: DateTime(2026, 6, 14, 9, 0),
            end: DateTime(2026, 6, 14, 9, 30),
          ),
        ],
        finishTime: DateTime(2026, 6, 14, 12, 45),
      );

      expect(layout.dayEnd, DateTime(2026, 6, 14, 13, 0));
    });

    test('finishTime earlier than the last role does not shrink the axis', () {
      final layout = ScheduleTimelineLayout.build(
        roles: [
          role(
            id: 1,
            title: 'Prayer',
            start: DateTime(2026, 6, 14, 9, 0),
            end: DateTime(2026, 6, 14, 12, 30),
          ),
        ],
        finishTime: DateTime(2026, 6, 14, 10, 0),
      );

      expect(layout.dayEnd, DateTime(2026, 6, 14, 12, 30));
    });

    test('minutesFromStart is measured from the first tick', () {
      final layout = ScheduleTimelineLayout.build(roles: [
        role(
          id: 1,
          title: 'Sound',
          start: DateTime(2026, 6, 14, 9, 20),
          end: DateTime(2026, 6, 14, 9, 50),
        ),
      ]);

      final placement = placementFor(layout, 1);
      expect(layout.dayStart, DateTime(2026, 6, 14, 9, 0));
      expect(placement.minutesFromStart, 20);
      expect(placement.durationMinutes, 30);
    });

    test('bounds snap to the half hour, not the whole hour', () {
      final layout = ScheduleTimelineLayout.build(roles: [
        role(
          id: 1,
          title: 'Orientation',
          start: DateTime(2026, 6, 14, 9, 55),
          end: DateTime(2026, 6, 14, 10, 5),
        ),
      ]);

      // Flooring to 09:00 would open the canvas on a blank hour.
      expect(layout.dayStart, DateTime(2026, 6, 14, 9, 30));
      expect(layout.dayEnd, DateTime(2026, 6, 14, 10, 30));
    });

    test('two overlapping roles share a cluster in separate lanes', () {
      final layout = ScheduleTimelineLayout.build(roles: [
        role(
          id: 1,
          title: 'Technical Sound',
          start: DateTime(2026, 6, 14, 9, 0),
          end: DateTime(2026, 6, 14, 12, 0),
        ),
        role(
          id: 2,
          title: 'Intercessory Prayer',
          start: DateTime(2026, 6, 14, 9, 0),
          end: DateTime(2026, 6, 14, 9, 50),
        ),
      ]);

      expect(layout.hasOverlaps, isTrue);
      final sound = placementFor(layout, 1);
      final prayer = placementFor(layout, 2);
      expect(sound.clusterIndex, prayer.clusterIndex);
      expect({sound.laneIndex, prayer.laneIndex}, {0, 1});
      expect(sound.laneCount, 2);
      expect(prayer.laneCount, 2);
    });

    test('an all-morning role moves to the band and frees the canvas', () {
      final layout = ScheduleTimelineLayout.build(roles: [
        role(
          id: 1,
          title: 'Technical Sound',
          start: DateTime(2026, 6, 14, 9, 0),
          end: DateTime(2026, 6, 14, 12, 0),
        ),
        role(
          id: 2,
          title: 'Praise and Worship',
          start: DateTime(2026, 6, 14, 10, 10),
          end: DateTime(2026, 6, 14, 10, 35),
        ),
        role(
          id: 3,
          title: 'Word of God',
          start: DateTime(2026, 6, 14, 10, 45),
          end: DateTime(2026, 6, 14, 11, 45),
        ),
      ]);

      expect(layout.coverageRoles.map((final c) => c.roleId), [1]);
      expect(layout.coverageRoles.single.start, DateTime(2026, 6, 14, 9, 0));
      expect(layout.coverageRoles.single.end, DateTime(2026, 6, 14, 12, 0));

      // The running order is left to itself: one lane, no overflow.
      expect(layout.placements.map((final p) => p.roleId), [2, 3]);
      expect(layout.hasOverlaps, isFalse);
      expect(layout.overflows, isEmpty);
      // The axis no longer reserves the hour before the first item.
      expect(layout.dayStart, DateTime(2026, 6, 14, 10, 0));
    });

    test('two duty roles free a crowded running order on a phone', () {
      final layout = ScheduleTimelineLayout.build(
        roles: [
          role(
            id: 1,
            title: 'Technical Sound',
            start: DateTime(2026, 6, 14, 9, 0),
            end: DateTime(2026, 6, 14, 12, 0),
          ),
          role(
            id: 2,
            title: 'Technical Media',
            start: DateTime(2026, 6, 14, 9, 0),
            end: DateTime(2026, 6, 14, 12, 0),
          ),
          role(
            id: 3,
            title: 'Welcome',
            start: DateTime(2026, 6, 14, 10, 0),
            end: DateTime(2026, 6, 14, 10, 10),
          ),
          role(
            id: 4,
            title: 'Worship',
            start: DateTime(2026, 6, 14, 10, 10),
            end: DateTime(2026, 6, 14, 10, 50),
          ),
          role(
            id: 5,
            title: 'Word',
            start: DateTime(2026, 6, 14, 10, 50),
            end: DateTime(2026, 6, 14, 11, 50),
          ),
        ],
        laneCap: ScheduleTimelineLayout.phoneLaneCap,
      );

      expect(layout.coverageRoles.map((final c) => c.roleId), [1, 2]);
      expect(layout.placements.map((final p) => p.roleId), [3, 4, 5]);
      // Previously these three were hidden behind a "+N parallel" marker.
      expect(layout.overflows, isEmpty);
      expect(layout.placements.every((final p) => p.laneIndex == 0), isTrue);
    });

    test('a long role overlapping only one other stays on the canvas', () {
      final layout = ScheduleTimelineLayout.build(roles: [
        role(
          id: 1,
          title: 'Technical Sound',
          start: DateTime(2026, 6, 14, 9, 0),
          end: DateTime(2026, 6, 14, 12, 0),
        ),
        role(
          id: 2,
          title: 'Praise and Worship',
          start: DateTime(2026, 6, 14, 10, 10),
          end: DateTime(2026, 6, 14, 10, 35),
        ),
        role(
          id: 3,
          title: 'Clean up',
          start: DateTime(2026, 6, 14, 12, 0),
          end: DateTime(2026, 6, 14, 12, 30),
        ),
      ]);

      expect(layout.coverageRoles, isEmpty);
      expect(placementFor(layout, 1).laneIndex, 0);
      expect(placementFor(layout, 2).laneIndex, 1);
    });

    test('back-to-back roles are never treated as covering the event', () {
      final layout = ScheduleTimelineLayout.build(roles: [
        role(
          id: 1,
          title: 'First half',
          start: DateTime(2026, 6, 14, 10, 0),
          end: DateTime(2026, 6, 14, 11, 0),
        ),
        role(
          id: 2,
          title: 'Second half',
          start: DateTime(2026, 6, 14, 11, 0),
          end: DateTime(2026, 6, 14, 12, 0),
        ),
        role(
          id: 3,
          title: 'Notices',
          start: DateTime(2026, 6, 14, 12, 0),
          end: DateTime(2026, 6, 14, 12, 10),
        ),
      ]);

      expect(layout.coverageRoles, isEmpty);
      expect(layout.placements.length, 3);
    });

    test('roles too short to matter are not banded on a brief post', () {
      final layout = ScheduleTimelineLayout.build(
        roles: [
          role(
            id: 1,
            title: 'Sound check',
            start: DateTime(2026, 6, 14, 10, 0),
            end: DateTime(2026, 6, 14, 10, 20),
          ),
          role(
            id: 2,
            title: 'Warm up',
            start: DateTime(2026, 6, 14, 10, 0),
            end: DateTime(2026, 6, 14, 10, 8),
          ),
          role(
            id: 3,
            title: 'Briefing',
            start: DateTime(2026, 6, 14, 10, 5),
            end: DateTime(2026, 6, 14, 10, 15),
          ),
        ],
        laneCap: ScheduleTimelineLayout.wideLaneCap,
      );

      // 20 minutes is over half a 20-minute span, but far too short to be duty
      // cover — the minimum duration keeps these in the running order.
      expect(layout.coverageRoles, isEmpty);
      expect(layout.placements.length, 3);
    });

    test('nothing is banded when every role covers the event', () {
      final layout = ScheduleTimelineLayout.build(
        roles: [
          role(
            id: 1,
            title: 'Sound',
            start: DateTime(2026, 6, 14, 9, 0),
            end: DateTime(2026, 6, 14, 12, 0),
          ),
          role(
            id: 2,
            title: 'Media',
            start: DateTime(2026, 6, 14, 9, 0),
            end: DateTime(2026, 6, 14, 12, 0),
          ),
          role(
            id: 3,
            title: 'Stewarding',
            start: DateTime(2026, 6, 14, 9, 0),
            end: DateTime(2026, 6, 14, 12, 0),
          ),
        ],
        laneCap: ScheduleTimelineLayout.wideLaneCap,
      );

      expect(layout.coverageRoles, isEmpty);
      expect(layout.placements.length, 3);
    });

    test('a gap between roles starts a new cluster', () {
      final layout = ScheduleTimelineLayout.build(roles: [
        role(
          id: 1,
          title: 'Setup',
          start: DateTime(2026, 6, 14, 9, 0),
          end: DateTime(2026, 6, 14, 9, 30),
        ),
        role(
          id: 2,
          title: 'Prayer',
          start: DateTime(2026, 6, 14, 9, 0),
          end: DateTime(2026, 6, 14, 9, 30),
        ),
        role(
          id: 3,
          title: 'Service',
          start: DateTime(2026, 6, 14, 10, 0),
          end: DateTime(2026, 6, 14, 11, 0),
        ),
      ]);

      expect(placementFor(layout, 3).clusterIndex,
          isNot(placementFor(layout, 1).clusterIndex));
      expect(placementFor(layout, 3).laneCount, 1);
    });

    test('three-way overlap fills three lanes when the cap allows', () {
      final layout = ScheduleTimelineLayout.build(
        roles: [
          role(
            id: 1,
            title: 'Sound',
            start: DateTime(2026, 6, 14, 9, 0),
            end: DateTime(2026, 6, 14, 12, 0),
          ),
          role(
            id: 2,
            title: 'Media',
            start: DateTime(2026, 6, 14, 9, 0),
            end: DateTime(2026, 6, 14, 12, 0),
          ),
          role(
            id: 3,
            title: 'Sunday School',
            start: DateTime(2026, 6, 14, 9, 0),
            end: DateTime(2026, 6, 14, 12, 0),
          ),
        ],
        laneCap: ScheduleTimelineLayout.wideLaneCap,
      );

      expect(layout.placements.length, 3);
      expect(layout.overflows, isEmpty);
      expect(
        layout.placements.map((final p) => p.laneIndex).toSet(),
        {0, 1, 2},
      );
      expect(layout.placements.every((final p) => p.laneCount == 3), isTrue);
    });

    test('roles beyond the lane cap become an overflow marker', () {
      final layout = ScheduleTimelineLayout.build(
        roles: [
          role(
            id: 1,
            title: 'Sound',
            start: DateTime(2026, 6, 14, 9, 0),
            end: DateTime(2026, 6, 14, 12, 0),
          ),
          role(
            id: 2,
            title: 'Media',
            start: DateTime(2026, 6, 14, 9, 0),
            end: DateTime(2026, 6, 14, 12, 0),
          ),
          role(
            id: 3,
            title: 'Sunday School',
            start: DateTime(2026, 6, 14, 9, 15),
            end: DateTime(2026, 6, 14, 11, 0),
          ),
        ],
        laneCap: ScheduleTimelineLayout.phoneLaneCap,
      );

      expect(layout.placements.length, 2);
      expect(layout.placements.every((final p) => p.laneCount == 2), isTrue);

      final overflow = layout.overflowForCluster(0);
      expect(overflow, isNotNull);
      expect(overflow!.count, 1);
      expect(overflow.roles.single['id'], 3);
      expect(overflow.start, DateTime(2026, 6, 14, 9, 15));
      expect(overflow.end, DateTime(2026, 6, 14, 11, 0));
      expect(overflow.minutesFromStart, 15);
    });

    test('roles without a start or end are reported as untimed', () {
      final layout = ScheduleTimelineLayout.build(roles: [
        role(
          id: 1,
          title: 'Welcome',
          start: DateTime(2026, 6, 14, 10, 0),
          end: DateTime(2026, 6, 14, 10, 15),
        ),
        role(id: 2, title: 'Unscheduled'),
        role(id: 3, title: 'Half set', start: DateTime(2026, 6, 14, 10, 0)),
      ]);

      expect(layout.placements.length, 1);
      expect(layout.untimedRoles.map((final r) => r['id']), [2, 3]);
    });

    test('untimed roles alone leave the timeline empty', () {
      final layout = ScheduleTimelineLayout.build(
        roles: [role(id: 1, title: 'Unscheduled')],
      );

      expect(layout.isEmpty, isTrue);
      expect(layout.dayStart, isNull);
      expect(layout.untimedRoles.length, 1);
    });

    test('an end before its start is clamped rather than dropped', () {
      final layout = ScheduleTimelineLayout.build(roles: [
        role(
          id: 1,
          title: 'Broken',
          start: DateTime(2026, 6, 14, 10, 0),
          end: DateTime(2026, 6, 14, 9, 0),
        ),
      ]);

      final placement = placementFor(layout, 1);
      expect(placement.durationMinutes, 0);
      expect(placement.end, placement.start);
    });

    test('input order does not change lane assignment', () {
      final roles = [
        role(
          id: 2,
          title: 'Prayer',
          start: DateTime(2026, 6, 14, 9, 30),
          end: DateTime(2026, 6, 14, 10, 0),
        ),
        role(
          id: 1,
          title: 'Sound',
          start: DateTime(2026, 6, 14, 9, 0),
          end: DateTime(2026, 6, 14, 12, 0),
        ),
      ];

      final layout = ScheduleTimelineLayout.build(roles: roles);

      expect(placementFor(layout, 1).laneIndex, 0);
      expect(placementFor(layout, 2).laneIndex, 1);
    });
  });
}
