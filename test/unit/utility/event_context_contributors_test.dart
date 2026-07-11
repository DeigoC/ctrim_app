import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventContext.applyContributorUIDs', () {
    test('tracks additions and removals for save notifications', () {
      final context = EventContext.adding(currentUserID: 'author-1');
      context.metadata.contributorUIDs.addAll(['user-a', 'user-b']);

      context.applyContributorUIDs(['user-b', 'user-c']);

      expect(context.metadata.contributorUIDs, ['user-b', 'user-c']);
      expect(context.contributorAdditionUIDs, ['user-c']);
      expect(context.contributorRemovalUIDs, ['user-a']);
    });

    test('re-adding a removed contributor clears removal tracking', () {
      final context = EventContext.adding(currentUserID: 'author-1');
      context.metadata.contributorUIDs.add('user-a');

      context.applyContributorUIDs([]);
      expect(context.contributorRemovalUIDs, ['user-a']);

      context.applyContributorUIDs(['user-a']);
      expect(context.contributorRemovalUIDs, isEmpty);
      expect(context.contributorAdditionUIDs, ['user-a']);
    });
  });
}
