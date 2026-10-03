import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/utility/bulletin_listing.dart';
import 'package:ctrim_app/utility/bulletin_undated_top_up.dart';

void main() {
  EventHead head(String id, {DateTime? recentDate}) {
    final result = EventHead(id: id, title: id);
    if (recentDate != null) result.setRecentDate(recentDate);
    return result;
  }

  group('BulletinUndatedTopUp.needsSnippet', () {
    test('asks for more when No date is shorter than the thin count', () {
      expect(
        BulletinUndatedTopUp.needsSnippet(
          timeFilter: BulletinTimeFilter.undated,
          filteredCount: 5,
          alreadyFetched: false,
        ),
        isTrue,
      );
    });

    test('skips when the filtered list is already long enough', () {
      expect(
        BulletinUndatedTopUp.needsSnippet(
          timeFilter: BulletinTimeFilter.undated,
          filteredCount: BulletinUndatedTopUp.thinCount,
          alreadyFetched: false,
        ),
        isFalse,
      );
    });

    test('skips other time filters and a second fetch', () {
      expect(
        BulletinUndatedTopUp.needsSnippet(
          timeFilter: BulletinTimeFilter.all,
          filteredCount: 0,
          alreadyFetched: false,
        ),
        isFalse,
      );
      expect(
        BulletinUndatedTopUp.needsSnippet(
          timeFilter: BulletinTimeFilter.undated,
          filteredCount: 1,
          alreadyFetched: true,
        ),
        isFalse,
      );
    });
  });

  group('BulletinUndatedTopUp.merge', () {
    test('keeps the session copy and appends new ids', () {
      final session = head('a', recentDate: DateTime(2026, 8, 2));
      final olderSnippetCopy = head('a', recentDate: DateTime(2026, 8, 1));
      final extra = head('b');
      final merged = BulletinUndatedTopUp.merge(
        sessionHeads: [session],
        snippet: [olderSnippetCopy, extra],
      );
      expect(merged.map((e) => e.id), ['a', 'b']);
      expect(merged.first.recentDate, DateTime(2026, 8, 2));
    });
  });
}
