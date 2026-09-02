import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/utility/bulletin_listing.dart';
import 'package:ctrim_app/utility/catalog/volunteer_locations.dart';

void main() {
  final now = DateTime(2026, 8, 22, 14, 0);

  EventHead head({
    required String id,
    DateTime? eventDate,
    DateTime? recentDate,
    String location = 'Belfast',
    List<String> tagIDs = const [],
    bool isPeriodParent = false,
  }) {
    final result = EventHead(
      id: id,
      location: location,
      tagIDs: tagIDs,
      isPeriodParent: isPeriodParent,
    );
    if (eventDate != null) result.setEventDate(eventDate);
    if (recentDate != null) result.setRecentDate(recentDate);
    return result;
  }

  List<EventHead> apply(
    List<EventHead> heads, {
    BulletinSort sort = BulletinSort.relevancy,
    BulletinTimeFilter timeFilter = BulletinTimeFilter.all,
    bool bookmarksOnly = false,
    Set<String> bookmarkedIds = const {},
    Set<String> selectedTagIDs = const {},
    String locationFilter = VolunteerLocations.all,
    bool excludePeriodParents = true,
  }) {
    return BulletinListing.apply(
      heads: heads,
      query: BulletinListingQuery(
        sort: sort,
        timeFilter: timeFilter,
        bookmarksOnly: bookmarksOnly,
        bookmarkedIds: bookmarkedIds,
        selectedTagIDs: selectedTagIDs,
        locationFilter: locationFilter,
        excludePeriodParents: excludePeriodParents,
        now: now,
      ),
    );
  }

  group('BulletinListing.uniqueEventHeads', () {
    test('keeps first occurrence of each id', () {
      final first = head(id: 'a', recentDate: DateTime(2026, 8, 1));
      final second = head(id: 'a', recentDate: DateTime(2026, 8, 20));
      final unique =
          BulletinListing.uniqueEventHeads([first, second, head(id: 'b')]);
      expect(unique.map((e) => e.id), ['a', 'b']);
      expect(unique.first.recentDate, DateTime(2026, 8, 1));
    });
  });

  group('BulletinListing.apply filters', () {
    test('excludes period parents by default', () {
      final visible = apply([
        head(
            id: 'term', isPeriodParent: true, eventDate: DateTime(2026, 8, 23)),
        head(id: 'meet', eventDate: DateTime(2026, 8, 23)),
      ]);
      expect(visible.map((e) => e.id), ['meet']);
    });

    test('upcoming keeps events within 12h grace and drops undated', () {
      final visible = apply(
        [
          head(id: 'this-morning', eventDate: DateTime(2026, 8, 22, 8)),
          head(id: 'yesterday', eventDate: DateTime(2026, 8, 21, 10)),
          head(id: 'tomorrow', eventDate: DateTime(2026, 8, 23, 10)),
          head(id: 'undated'),
        ],
        timeFilter: BulletinTimeFilter.upcoming,
      );
      expect(visible.map((e) => e.id), ['this-morning', 'tomorrow']);
    });

    test('past excludes future and undated', () {
      final visible = apply(
        [
          head(id: 'this-morning', eventDate: DateTime(2026, 8, 22, 8)),
          head(id: 'tomorrow', eventDate: DateTime(2026, 8, 23, 10)),
          head(id: 'undated'),
        ],
        timeFilter: BulletinTimeFilter.past,
      );
      expect(visible.map((e) => e.id), ['this-morning']);
    });

    test('bookmarks, location, and tags compose', () {
      final visible = apply(
        [
          head(id: 'keep', location: 'Belfast', tagIDs: ['sun']),
          head(id: 'other-loc', location: 'Portadown', tagIDs: ['sun']),
          head(id: 'other-tag', location: 'Belfast', tagIDs: ['mid']),
          head(id: 'not-bookmarked', location: 'Belfast', tagIDs: ['sun']),
        ],
        bookmarksOnly: true,
        bookmarkedIds: {'keep', 'other-loc', 'other-tag'},
        locationFilter: 'Belfast',
        selectedTagIDs: {'sun'},
      );
      expect(visible.map((e) => e.id), ['keep']);
    });
  });

  group('BulletinListing.apply sort', () {
    test('relevancy is next upcoming, recent past, then the rest', () {
      final visible = apply([
        head(
          id: 'old-update',
          eventDate: DateTime(2026, 8, 10),
          recentDate: DateTime(2026, 8, 21),
        ),
        head(
          id: 'next-week',
          eventDate: DateTime(2026, 8, 29, 10),
          recentDate: DateTime(2026, 8, 1),
        ),
        head(
          id: 'tomorrow',
          eventDate: DateTime(2026, 8, 23, 10),
          recentDate: DateTime(2026, 8, 1),
        ),
        head(
          id: 'today-late',
          eventDate: DateTime(2026, 8, 22, 19),
          recentDate: DateTime(2026, 8, 1),
        ),
        head(
          id: 'today-early',
          eventDate: DateTime(2026, 8, 22, 9),
          recentDate: DateTime(2026, 8, 1),
        ),
        head(
          id: 'fresh-undated',
          recentDate: DateTime(2026, 8, 22, 12),
        ),
      ]);
      expect(visible.map((e) => e.id), [
        'today-early',
        'today-late',
        'tomorrow',
        'old-update',
        'next-week',
        'fresh-undated',
      ]);
    });

    test('relevancy keeps far-future bulk posts after recent past', () {
      final visible = apply([
        head(
          id: 'tomorrow',
          eventDate: DateTime(2026, 8, 23, 10),
        ),
        head(
          id: 'far-future',
          eventDate: DateTime(2026, 10, 1, 10),
          recentDate: DateTime(2026, 8, 22, 12),
        ),
        head(
          id: 'old-update',
          eventDate: DateTime(2026, 8, 21, 10),
          recentDate: DateTime(2026, 8, 21),
        ),
      ]);
      expect(visible.map((e) => e.id), ['tomorrow', 'far-future', 'old-update']);
    });

    test('relevancy caps upcoming head at three before recent past', () {
      final heads = [
        for (var i = 1; i <= 10; i++)
          head(id: 'u$i', eventDate: DateTime(2026, 8, 22 + i, 10)),
        head(id: 'yesterday', eventDate: DateTime(2026, 8, 21, 10)),
        head(id: 'last-week', eventDate: DateTime(2026, 8, 15, 10)),
      ];
      final ids = apply(heads).map((e) => e.id).toList();
      expect(ids.take(8), [
        'u1',
        'u2',
        'u3',
        'yesterday',
        'last-week',
        'u4',
        'u5',
        'u6',
      ]);
      expect(ids.indexOf('yesterday'), lessThan(ids.indexOf('u4')));
    });

    test('soonest puts upcoming before past and undated last', () {
      final visible = apply(
        [
          head(id: 'ancient', eventDate: DateTime(2020, 1, 1)),
          head(id: 'later', eventDate: DateTime(2026, 8, 25)),
          head(id: 'sooner', eventDate: DateTime(2026, 8, 23)),
          head(id: 'undated'),
        ],
        sort: BulletinSort.eventDateSoonest,
      );
      expect(visible.map((e) => e.id), ['sooner', 'later', 'ancient', 'undated']);
    });

    test('latest puts recent past before upcoming, not far future first', () {
      final visible = apply(
        [
          head(id: 'far-future', eventDate: DateTime(2026, 12, 1)),
          head(id: 'older', eventDate: DateTime(2026, 8, 10)),
          head(id: 'newer', eventDate: DateTime(2026, 8, 20)),
        ],
        sort: BulletinSort.eventDateLatest,
      );
      expect(visible.map((e) => e.id), ['newer', 'older', 'far-future']);
    });

    test('does not mutate the source list', () {
      final source = [
        head(id: 'b', eventDate: DateTime(2026, 8, 25)),
        head(id: 'a', eventDate: DateTime(2026, 8, 23)),
      ];
      apply(source, sort: BulletinSort.eventDateSoonest);
      expect(source.map((e) => e.id), ['b', 'a']);
    });
  });

  group('BulletinListingQuery', () {
    test('location-only still counts as an active filter', () {
      final query = BulletinListingQuery(
        locationFilter: 'Belfast',
        now: now,
      );
      expect(query.hasActiveFilters, isTrue);
      expect(query.showsNonDefaultBanner, isTrue);
    });

    test('relevancy with All location is the default view', () {
      final query = BulletinListingQuery(now: now);
      expect(query.hasActiveFilters, isFalse);
      expect(query.showsNonDefaultBanner, isFalse);
    });
  });

  group('fromStorage', () {
    test('unknown values fall back to defaults', () {
      expect(BulletinSort.fromStorage(null), BulletinSort.relevancy);
      expect(BulletinSort.fromStorage('nope'), BulletinSort.relevancy);
      expect(BulletinTimeFilter.fromStorage('past'), BulletinTimeFilter.past);
      expect(BulletinTimeFilter.fromStorage('x'), BulletinTimeFilter.all);
    });
  });
}
