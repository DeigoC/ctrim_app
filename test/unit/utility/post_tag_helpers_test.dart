import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/post_tag.dart';
import 'package:ctrim_app/utility/catalog/post_tag_helpers.dart';

void main() {
  group('PostTagHelpers', () {
    final tags = [
      PostTag(id: 'a', name: 'Sunday', displayOrder: 1),
      PostTag(id: 'b', name: 'Youth', displayOrder: 2, isActive: false),
      PostTag(id: 'c', name: 'Prayer', displayOrder: 0),
    ];

    EventHead headWith(List<String> tagIDs) {
      return EventHead(id: 'p1', tagIDs: tagIDs);
    }

    test('resolveTags respects order and activeOnly', () {
      final resolved = PostTagHelpers.resolveTags(
        tagIDs: ['a', 'b', 'c'],
        allTags: tags,
      );
      expect(resolved.map((t) => t.id), ['c', 'a']);
    });

    test('headMatchesTagFilter match any', () {
      final head = headWith(['a', 'c']);
      expect(
        PostTagHelpers.headMatchesTagFilter(
          head: head,
          selectedTagIDs: {'a'},
        ),
        isTrue,
      );
      expect(
        PostTagHelpers.headMatchesTagFilter(
          head: head,
          selectedTagIDs: {'missing'},
        ),
        isFalse,
      );
      expect(
        PostTagHelpers.headMatchesTagFilter(
          head: head,
          selectedTagIDs: {},
        ),
        isTrue,
      );
    });

    test('EventHead fromMap parses TagIDs', () {
      final head = EventHead.fromMap('e1', {
        'Title': 'T',
        'Subtitle': '',
        'Location': 'Belfast',
        'TagIDs': ['a', 'c'],
        'Media': <Map<String, dynamic>>[],
        'RecentDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'EventDate': null,
      });
      expect(head.tagIDs, ['a', 'c']);
      expect(head.hasTag('a'), isTrue);
      expect(head.hasAnyTag(['c', 'x']), isTrue);
    });
  });
}
