import 'package:ctrim_app/utility/app_shared_preferences.dart';
import 'package:ctrim_app/utility/notification_subscription_service.dart';
import 'package:ctrim_app/utility/notification_topics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationTopics', () {
    test('postTopic prefixes post id', () {
      expect(NotificationTopics.postTopic('abc123'), 'post-abc123');
    });

    test('labelFor returns display names for location umbrellas', () {
      expect(
        NotificationTopics.labelFor(NotificationTopics.belfastUmbrella),
        'All Belfast updates',
      );
      expect(NotificationTopics.labelFor('unknown-topic'), 'unknown-topic');
    });

    test('locationUmbrella slugifies names with spaces', () {
      expect(
        NotificationTopics.locationUmbrella('North Coast'),
        'north-coast',
      );
      expect(NotificationTopics.locationUmbrella('Portadown'), 'Portadown');
    });
  });

  group('NotificationSubscriptionService', () {
    late AppSharedPreferences prefs;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = AppSharedPreferences(
          preferences: await SharedPreferences.getInstance());
    });

    setUp(() async {
      final instance = await SharedPreferences.getInstance();
      await instance.clear();
    });

    test('topicsFromPrefs includes opted-in location umbrellas only', () {
      prefs.setSubscribedToTopic(NotificationTopics.sundayService, true);
      prefs.setSubscribedToBelfast(true);
      prefs.setSubscribedToTopic('Portadown', true);

      final topics = NotificationSubscriptionService.topicsFromPrefs(
        prefs,
        locationNames: const ['Belfast', 'Portadown'],
      );

      expect(topics, contains(NotificationTopics.belfastUmbrella));
      expect(topics, contains('Portadown'));
      expect(topics, isNot(contains(NotificationTopics.sundayService)));
    });

    test('topicsFromPrefs supports non-Belfast locations', () {
      prefs.setSubscribedToTopic('Portadown', true);
      prefs.setSubscribedToBelfast(false);

      final topics = NotificationSubscriptionService.topicsFromPrefs(
        prefs,
        locationNames: const ['Portadown'],
      );

      expect(topics, contains('Portadown'));
      expect(topics, isNot(contains(NotificationTopics.belfastUmbrella)));
    });

    test('allSubscribedTopics adds bookmark post topics', () {
      prefs.setSubscribedToBelfast(true);
      prefs.addPostBookmark('event-42');

      final topics = NotificationSubscriptionService.allSubscribedTopics(prefs);

      expect(topics, contains(NotificationTopics.postTopic('event-42')));
    });
  });
}
