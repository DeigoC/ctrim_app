import 'package:ctrim_app/utility/notifications/broadcast_audience.dart';
import 'package:ctrim_app/utility/notifications/notification_topics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BroadcastAudience', () {
    test('includesBelfastUmbrella detects umbrella topic', () {
      expect(
        BroadcastAudience.includesBelfastUmbrella(['north-coast']),
        isFalse,
      );
      expect(
        BroadcastAudience.includesBelfastUmbrella(
          ['north-coast', NotificationTopics.belfastUmbrella],
        ),
        isTrue,
      );
    });

    test('includesLocationUmbrella detects location umbrella', () {
      expect(
        BroadcastAudience.includesLocationUmbrella(
          topics: const ['Belfast'],
          locationName: 'Belfast',
        ),
        isTrue,
      );
      expect(
        BroadcastAudience.includesLocationUmbrella(
          topics: const ['north-coast'],
          locationName: 'North Coast',
        ),
        isTrue,
      );
      expect(
        BroadcastAudience.includesLocationUmbrella(
          topics: const ['belfast-sunday-service'],
          locationName: 'Belfast',
        ),
        isFalse,
      );
    });

    test('resolveFromPost returns location umbrella when enabled', () {
      expect(
        BroadcastAudience.resolveFromPost(
          location: 'Belfast',
          includeLocationUmbrella: true,
        ),
        [NotificationTopics.belfastUmbrella],
      );
      expect(
        BroadcastAudience.resolveFromPost(
          location: 'North Coast',
          includeLocationUmbrella: true,
        ),
        ['north-coast'],
      );
      expect(
        BroadcastAudience.resolveFromPost(
          location: 'Portadown',
          includeLocationUmbrella: false,
        ),
        isEmpty,
      );
    });

    test('describe uses friendly labels', () {
      expect(BroadcastAudience.describe(const []), 'No topics selected');
      expect(
        BroadcastAudience.describe([NotificationTopics.belfastUmbrella]),
        NotificationTopics.belfastUmbrellaLabel,
      );
      expect(
        BroadcastAudience.describe(['north-coast']),
        'north-coast',
      );
    });
  });
}
