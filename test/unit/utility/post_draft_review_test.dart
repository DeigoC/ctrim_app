import 'package:ctrim_app/models/post_tag.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:ctrim_app/utility/notification_topics.dart';
import 'package:ctrim_app/utility/post_draft_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildPostDraftReview', () {
    test('flags common missing fields on a minimal draft', () {
      final context = EventContext.adding(currentUserID: 'author-1');

      final review = buildPostDraftReview(
        eventContext: context,
        title: 'Sunday Service',
        subtitle: 'Join us this week',
        allTags: const [],
      );

      expect(review.suggestionCount, greaterThan(0));
      expect(
        review.items.where((item) => item.status == PostDraftReviewStatus.suggestion).map((e) => e.kind),
        containsAll([
          PostDraftReviewKind.eventDate,
          PostDraftReviewKind.scheduleRoles,
          PostDraftReviewKind.coverImage,
          PostDraftReviewKind.leadSpeaker,
          PostDraftReviewKind.postTags,
          PostDraftReviewKind.cellGroups,
          PostDraftReviewKind.expectedAttendees,
          PostDraftReviewKind.contributors,
          PostDraftReviewKind.mediaGallery,
        ]),
      );
      expect(review.sheetSubtitle, contains('optional'));
    });

    test('shows ready summary for title, subtitle, and location', () {
      final context = EventContext.adding(currentUserID: 'author-1');

      final review = buildPostDraftReview(
        eventContext: context,
        title: 'Youth Night',
        subtitle: 'Games and worship',
        allTags: const [],
      );

      final titleItem = review.items.firstWhere((item) => item.kind == PostDraftReviewKind.title);
      final subtitleItem = review.items.firstWhere((item) => item.kind == PostDraftReviewKind.subtitle);
      final locationItem = review.items.firstWhere((item) => item.kind == PostDraftReviewKind.location);

      expect(titleItem.status, PostDraftReviewStatus.ready);
      expect(titleItem.subtitle, 'Youth Night');
      expect(subtitleItem.status, PostDraftReviewStatus.ready);
      expect(locationItem.status, PostDraftReviewStatus.ready);
      expect(locationItem.subtitle, 'Belfast');
    });

    test('broadcast on with audience is informational', () {
      final context = EventContext.adding(currentUserID: 'author-1');
      context.setNotifyBroadcast(true);
      context.applyTagIDs(['youth-tag']);
      context.metadata.addAllTopics([
        NotificationTopics.streamTopic(
          locationName: 'Belfast',
          streamKind: NotificationTopics.kindYouthCaregroup,
        ),
      ]);

      final review = buildPostDraftReview(
        eventContext: context,
        title: 'Youth Night',
        subtitle: 'This Friday',
        allTags: [
          PostTag(
            id: 'youth-tag',
            name: 'Youth',
            streamKind: NotificationTopics.kindYouthCaregroup,
          ),
        ],
      );

      final broadcast = review.items.firstWhere((item) => item.kind == PostDraftReviewKind.broadcastNotify);
      expect(broadcast.status, PostDraftReviewStatus.info);
      expect(broadcast.subtitle, contains('Will notify'));
    });

    test('broadcast on without audience is a suggestion', () {
      final context = EventContext.adding(currentUserID: 'author-1');
      context.setNotifyBroadcast(true);

      final review = buildPostDraftReview(
        eventContext: context,
        title: 'Update',
        subtitle: 'Read this',
        allTags: const [],
      );

      final broadcast = review.items.firstWhere((item) => item.kind == PostDraftReviewKind.broadcastNotify);
      expect(broadcast.status, PostDraftReviewStatus.suggestion);
      expect(broadcast.subtitle, contains('no audience'));
    });

    test('scheduled notify on without assignees is a suggestion', () {
      final context = EventContext.adding(currentUserID: 'author-1');
      context.setNotifyScheduledMembers(true);
      context.program.addRole(
        uids: const [],
        title: 'Worship',
        detail: '',
        start: DateTime(2026, 8, 24, 10),
        end: DateTime(2026, 8, 24, 10, 30),
        forGuests: true,
        id: 1,
      );

      final review = buildPostDraftReview(
        eventContext: context,
        title: 'Service',
        subtitle: 'Sunday',
        allTags: const [],
      );

      final scheduled = review.items.firstWhere((item) => item.kind == PostDraftReviewKind.scheduledNotify);
      expect(scheduled.status, PostDraftReviewStatus.suggestion);
    });

    test('fully filled draft reduces suggestion count', () {
      final context = EventContext.adding(currentUserID: 'author-1');
      context.head.setEventDate(DateTime(2026, 8, 24, 10));
      context.applyTagIDs(['tag-1']);
      context.applyCellGroupIDs(['cg-1']);
      context.head.setLeadSpeaker(uid: 'speaker-1', name: 'Alex', imgSrc: 'img');
      context.head.addMediaItem(type: 'img', src: 'cover.jpg', title: 'Cover');
      context.applyContributorUIDs(['editor-1']);
      context.applyExpectedAttendeeUserIDs(['member-1']);
      context.media.addMediaFile({'type': 'img', 'src': 'gallery.jpg', 'title': 'Photo'});
      context.program.addRole(
        uids: const ['user-a'],
        title: 'Welcome',
        detail: '',
        start: DateTime(2026, 8, 24, 10),
        end: DateTime(2026, 8, 24, 10, 15),
        forGuests: true,
        id: 2,
      );

      final review = buildPostDraftReview(
        eventContext: context,
        title: 'Service',
        subtitle: 'All welcome',
        allTags: [PostTag(id: 'tag-1', name: 'Sunday')],
      );

      expect(review.suggestionCount, 0);
      expect(review.sheetSubtitle, contains('look good'));
    });
  });
}
