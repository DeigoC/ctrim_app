import 'package:ctrim_app/utility/broadcast_audience.dart';
import 'package:ctrim_app/utility/notification_topics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BroadcastAudience', () {
    test('includesBelfastUmbrella detects umbrella topic', () {
      expect(
        BroadcastAudience.includesBelfastUmbrella(['belfast-sunday-service']),
        isFalse,
      );
      expect(
        BroadcastAudience.includesBelfastUmbrella(
          ['belfast-sunday-service', NotificationTopics.belfastUmbrella],
        ),
        isTrue,
      );
    });

    test('resolve keeps post topics and optionally adds Belfast', () {
      expect(
        BroadcastAudience.resolve(
          postTopics: ['belfast-sunday-service'],
          includeBelfastUmbrella: false,
        ),
        ['belfast-sunday-service'],
      );
      expect(
        BroadcastAudience.resolve(
          postTopics: ['belfast-sunday-service'],
          includeBelfastUmbrella: true,
        ),
        ['belfast-sunday-service', NotificationTopics.belfastUmbrella],
      );
    });

    test('resolve strips Belfast when include is false', () {
      expect(
        BroadcastAudience.resolve(
          postTopics: [
            NotificationTopics.belfastUmbrella,
            'belfast-sunday-service',
          ],
          includeBelfastUmbrella: false,
        ),
        ['belfast-sunday-service'],
      );
    });

    test('resolve dedupes topics', () {
      expect(
        BroadcastAudience.resolve(
          postTopics: [
            'belfast-sunday-service',
            'belfast-sunday-service',
            NotificationTopics.belfastUmbrella,
          ],
          includeBelfastUmbrella: true,
        ),
        ['belfast-sunday-service', NotificationTopics.belfastUmbrella],
      );
    });

    test('resolve can be Belfast-only', () {
      expect(
        BroadcastAudience.resolve(
          postTopics: const [],
          includeBelfastUmbrella: true,
        ),
        [NotificationTopics.belfastUmbrella],
      );
    });

    test('describe uses friendly labels', () {
      expect(BroadcastAudience.describe(const []), 'No topics selected');
      expect(
        BroadcastAudience.describe([NotificationTopics.belfastUmbrella]),
        NotificationTopics.belfastUmbrellaLabel,
      );
      expect(
        BroadcastAudience.describe([
          NotificationTopics.sundayService,
          NotificationTopics.belfastUmbrella,
        ]),
        '${NotificationTopics.labelFor(NotificationTopics.sundayService)}, '
        '${NotificationTopics.belfastUmbrellaLabel}',
      );
    });
  });
}
