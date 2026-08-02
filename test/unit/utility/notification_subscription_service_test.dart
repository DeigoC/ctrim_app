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

    test('labelFor returns display names for managed topics', () {
      expect(NotificationTopics.labelFor(NotificationTopics.belfastUmbrella),
          'All Belfast updates');
      expect(
        NotificationTopics.labelFor(NotificationTopics.sundayService),
        'Sunday Worship Service',
      );
      expect(NotificationTopics.labelFor('unknown-topic'), 'unknown-topic');
    });

    test('serviceTopicLabels covers every service topic', () {
      for (final topic in NotificationTopics.serviceTopics) {
        expect(
            NotificationTopics.serviceTopicLabels.containsKey(topic), isTrue);
        expect(NotificationTopics.labelFor(topic), isNotEmpty);
      }
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

    test(
        'topicsFromPrefs includes opted-in service topics and Belfast umbrella',
        () {
      prefs.setSubscribedToTopic(NotificationTopics.sundayService, true);
      prefs.setSubscribedToTopic(NotificationTopics.midweekService, false);
      prefs.setSubscribedToBelfast(true);

      final topics = NotificationSubscriptionService.topicsFromPrefs(prefs);

      expect(topics, contains(NotificationTopics.sundayService));
      expect(topics, isNot(contains(NotificationTopics.midweekService)));
      expect(topics, contains(NotificationTopics.belfastUmbrella));
    });

    test('topicsFromPrefs supports non-Belfast locations', () {
      prefs.setSubscribedToTopic('portadown-sunday-service', true);
      prefs.setSubscribedToTopic('Portadown', true);
      prefs.setSubscribedToBelfast(false);

      final topics = NotificationSubscriptionService.topicsFromPrefs(
        prefs,
        locationNames: const ['Portadown'],
      );

      expect(topics, contains('portadown-sunday-service'));
      expect(topics, contains('Portadown'));
      expect(topics, isNot(contains(NotificationTopics.belfastUmbrella)));
    });

    test('allSubscribedTopics adds bookmark post topics', () {
      prefs.setSubscribedToTopic(NotificationTopics.sundayService, true);
      prefs.addPostBookmark('event-42');

      final topics = NotificationSubscriptionService.allSubscribedTopics(prefs);

      expect(topics, contains(NotificationTopics.postTopic('event-42')));
    });
  });
}
