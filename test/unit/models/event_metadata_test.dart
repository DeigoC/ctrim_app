import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/event/event_metadata.dart';

void main() {
  group('EventMetadata', () {
    group('constructor', () {
      test('creates with required authorUID', () {
        final meta = EventMetadata(authorUID: 'user-1');

        expect(meta.authorUID, 'user-1');
        expect(meta.lastUID, 'user-1');
        expect(meta.parentID, isNull);
        expect(meta.hasParent, false);
        expect(meta.hasChildren, false);
        expect(meta.contributorUIDs, isEmpty);
        expect(meta.childrenPostIDs, isEmpty);
        expect(meta.topics, isEmpty);
        expect(meta.tagIDs, isEmpty);
      });

      test('creates with optional parentID', () {
        final meta = EventMetadata(authorUID: 'user-1', parentID: 'parent-post');

        expect(meta.parentID, 'parent-post');
        expect(meta.hasParent, true);
        expect(meta.isPeriodParent, false);
      });

      test('creates with isPeriodParent', () {
        final meta = EventMetadata(authorUID: 'user-1', isPeriodParent: true);
        expect(meta.isPeriodParent, true);
      });
    });

    group('fromMap', () {
      test('creates from a complete map', () {
        final map = {
          'AuthorUID': 'user-1',
          'LastUID': 'user-2',
          'ParentID': null,
          'ContributorUIDs': ['user-2', 'user-3'],
          'ChildrenIDs': ['child-1'],
          'Topics': ['youth', 'music'],
          'IsPeriodParent': true,
        };

        final meta = EventMetadata.fromMap(map);

        expect(meta.authorUID, 'user-1');
        expect(meta.lastUID, 'user-2');
        expect(meta.parentID, isNull);
        expect(meta.hasParent, false);
        expect(meta.hasChildren, true);
        expect(meta.contributorUIDs, ['user-2', 'user-3']);
        expect(meta.childrenPostIDs, ['child-1']);
        expect(meta.topics, ['youth', 'music']);
        expect(meta.isPeriodParent, true);
      });

      test('creates from a map without Topics key (backwards compat)', () {
        final map = {
          'AuthorUID': 'user-1',
          'LastUID': 'user-1',
          'ParentID': null,
          'ContributorUIDs': <String>[],
          'ChildrenIDs': <String>[],
        };

        final meta = EventMetadata.fromMap(map);

        expect(meta.topics, isEmpty);
        expect(meta.tagIDs, isEmpty);
        expect(meta.leadSpeakerUID, isNull);
        expect(meta.hasLeadSpeaker, false);
        expect(meta.isPeriodParent, false);
      });

      test('creates from a map with LeadSpeakerUID', () {
        final map = {
          'AuthorUID': 'user-1',
          'LastUID': 'user-1',
          'ParentID': null,
          'ContributorUIDs': <String>[],
          'ChildrenIDs': <String>[],
          'Topics': <String>[],
          'LeadSpeakerUID': 'speaker-9',
        };

        final meta = EventMetadata.fromMap(map);

        expect(meta.leadSpeakerUID, 'speaker-9');
        expect(meta.hasLeadSpeaker, true);
      });
    });

    group('toJson', () {
      test('serialises all fields correctly', () {
        final meta = EventMetadata(authorUID: 'user-1', parentID: 'parent-1');
        meta.addAllTopics(['youth', 'mission']);
        meta.setLastUID('user-2');
        meta.setLeadSpeakerUID('speaker-1');

        final json = meta.toJson() as Map<String, dynamic>;

        expect(json['AuthorUID'], 'user-1');
        expect(json['LastUID'], 'user-2');
        expect(json['ParentID'], 'parent-1');
        expect(json['Topics'], ['youth', 'mission']);
        expect(json['TagIDs'], isEmpty);
        expect(json['ContributorUIDs'], isEmpty);
        expect(json['ChildrenIDs'], isEmpty);
        expect(json['LeadSpeakerUID'], 'speaker-1');
        expect(json['IsPeriodParent'], false);
      });
    });

    group('parent and period parent', () {
      test('setParentID updates and clearParentID clears', () {
        final meta = EventMetadata(authorUID: 'user-1', parentID: 'p1');
        meta.setParentID('p2');
        expect(meta.parentID, 'p2');
        expect(meta.hasParent, true);
        meta.clearParentID();
        expect(meta.parentID, isNull);
        expect(meta.hasParent, false);
      });

      test('setParentID treats empty string as null', () {
        final meta = EventMetadata(authorUID: 'user-1', parentID: 'p1');
        meta.setParentID('');
        expect(meta.parentID, isNull);
        expect(meta.hasParent, false);
      });

      test('setIsPeriodParent toggles flag', () {
        final meta = EventMetadata(authorUID: 'user-1');
        meta.setIsPeriodParent(true);
        expect(meta.isPeriodParent, true);
        meta.setIsPeriodParent(false);
        expect(meta.isPeriodParent, false);
      });

      test('addChildID is idempotent and removeChildID works', () {
        final meta = EventMetadata(authorUID: 'user-1');
        meta.addChildID('c1');
        meta.addChildID('c1');
        expect(meta.childrenPostIDs, ['c1']);
        meta.removeChildID('c1');
        expect(meta.childrenPostIDs, isEmpty);
      });
    });

    group('hasChildren', () {
      test('returns false when childrenPostIDs is empty', () {
        final meta = EventMetadata(authorUID: 'user-1');
        expect(meta.hasChildren, false);
      });

      test('returns true when childrenPostIDs has entries', () {
        final meta = EventMetadata.fromMap({
          'AuthorUID': 'user-1',
          'LastUID': 'user-1',
          'ParentID': null,
          'ContributorUIDs': <String>[],
          'ChildrenIDs': ['child-1'],
          'Topics': <String>[],
        });
        expect(meta.hasChildren, true);
      });
    });

    group('setLastUID', () {
      test('updates lastUID', () {
        final meta = EventMetadata(authorUID: 'user-1');
        meta.setLastUID('user-99');
        expect(meta.lastUID, 'user-99');
      });
    });

    group('topics management', () {
      test('addAllTopics adds topics', () {
        final meta = EventMetadata(authorUID: 'user-1');
        meta.addAllTopics(['prayer', 'worship']);
        expect(meta.topics, ['prayer', 'worship']);
      });

      test('clearTopics removes all topics', () {
        final meta = EventMetadata(authorUID: 'user-1');
        meta.addAllTopics(['prayer', 'worship']);
        meta.clearTopics();
        expect(meta.topics, isEmpty);
      });

      test('addTopic is idempotent', () {
        final meta = EventMetadata(authorUID: 'user-1');
        meta.addTopic('Belfast');
        meta.addTopic('Belfast');
        expect(meta.topics, ['Belfast']);
      });

      test('removeTopic removes matching topic', () {
        final meta = EventMetadata(authorUID: 'user-1');
        meta.addAllTopics(['Belfast', 'belfast-sunday-service']);
        meta.removeTopic('Belfast');
        expect(meta.topics, ['belfast-sunday-service']);
      });

      test('topics getter returns an unmodifiable view', () {
        final meta = EventMetadata(authorUID: 'user-1');
        meta.addAllTopics(['prayer']);
        expect(() => meta.topics.add('fail'), throwsUnsupportedError);
      });
    });
  });
}
