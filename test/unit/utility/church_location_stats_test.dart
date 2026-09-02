import 'package:ctrim_app/models/cell_group.dart';
import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/church_location_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChurchLocationStats', () {
    final now = DateTime(2026, 8, 22, 15, 30);

    EventHead post({
      required String id,
      required DateTime eventDate,
      String location = 'Belfast',
      bool isPeriodParent = false,
    }) {
      return EventHead(
        id: id,
        title: id,
        location: location,
        isPeriodParent: isPeriodParent,
      )..setEventDate(eventDate);
    }

    test('empty location yields empty stats', () {
      final stats = ChurchLocationStats.compute(
        location: '  ',
        heads: [
          post(id: '1', eventDate: DateTime(2026, 8, 20)),
        ],
        groups: [CellGroup(id: 'cg1', name: 'A', location: 'Belfast')],
        users: [
          User(id: 'u1', forname: 'A', surname: 'B', location: 'Belfast'),
        ],
        now: now,
      );
      expect(stats.postCount, 0);
      expect(stats.cellGroupCount, 0);
      expect(stats.peopleCount, 0);
    });

    test('counts posts in the 90-day window for the location', () {
      final stats = ChurchLocationStats.compute(
        location: 'Belfast',
        heads: [
          post(id: 'today', eventDate: DateTime(2026, 8, 22, 10)),
          post(
              id: 'online',
              eventDate: DateTime(2026, 8, 1),
              location: 'Belfast (Online)'),
          post(id: 'old', eventDate: DateTime(2026, 5, 23, 23)),
          post(id: 'included-edge', eventDate: DateTime(2026, 5, 24, 0)),
          post(
              id: 'portadown',
              eventDate: DateTime(2026, 8, 20),
              location: 'Portadown'),
          post(
              id: 'series',
              eventDate: DateTime(2026, 8, 10),
              isPeriodParent: true),
          EventHead(id: 'undated', title: 'No date', location: 'Belfast'),
        ],
        groups: const [],
        users: const [],
        now: now,
      );

      expect(stats.postCount, 3);
      expect(
          stats.posts.map((h) => h.id), ['today', 'online', 'included-edge']);
    });

    test('counts non-archived cell groups and non-placeholder people', () {
      final stats = ChurchLocationStats.compute(
        location: 'Belfast',
        heads: const [],
        groups: [
          CellGroup(id: 'a', name: 'Active', location: 'Belfast'),
          CellGroup(
            id: 'p',
            name: 'Paused',
            location: 'Belfast',
            status: CellGroupStatus.paused,
          ),
          CellGroup(
            id: 'x',
            name: 'Archived',
            location: 'Belfast',
            status: CellGroupStatus.archived,
          ),
          CellGroup(id: 'other', name: 'Portadown', location: 'Portadown'),
        ],
        users: [
          User(id: '1', forname: 'A', surname: 'B', location: 'Belfast'),
          User(
            id: '2',
            forname: 'P',
            surname: 'H',
            location: 'Belfast',
            isPlaceholder: true,
          ),
          User(id: '3', forname: 'C', surname: 'D', location: 'Portadown'),
          User(
            id: '4',
            forname: 'Hidden',
            surname: 'User',
            location: 'Belfast',
            status: UserStatus.hidden,
          ),
        ],
        now: now,
      );

      expect(stats.cellGroupCount, 2);
      expect(stats.cellGroups.map((g) => g.id), ['a', 'p']);
      expect(stats.peopleCount, 1);
    });

    test('query window is 90 days back through end of today', () {
      expect(
        ChurchLocationStats.queryRangeStart(now),
        DateTime(2026, 5, 24),
      );
      expect(
        ChurchLocationStats.queryRangeEndExclusive(now),
        DateTime(2026, 8, 23),
      );
    });
  });
}
