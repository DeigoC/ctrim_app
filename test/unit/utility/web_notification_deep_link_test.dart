import 'package:ctrim_app/utility/notifications/web_notification_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebNotificationDeepLink.paramsFromQuery', () {
    test('maps postId to PostID', () {
      expect(
        WebNotificationDeepLink.paramsFromQuery({'postId': 'post-42'}),
        {'PostID': 'post-42'},
      );
    });

    test('maps infoPage', () {
      expect(
        WebNotificationDeepLink.paramsFromQuery({'infoPage': 'core_values'}),
        {'InfoPage': 'core_values'},
      );
    });

    test('ignores empty values', () {
      expect(
        WebNotificationDeepLink.paramsFromQuery({
          'postId': '',
          'infoPage': '4xd',
        }),
        {'InfoPage': '4xd'},
      );
    });

    test('returns empty map when no known params', () {
      expect(WebNotificationDeepLink.paramsFromQuery({'foo': 'bar'}), isEmpty);
    });
  });

  group('WebNotificationDeepLink.extractAppData', () {
    test('passes through flat PostID payloads', () {
      expect(
        WebNotificationDeepLink.extractAppData({'PostID': 'post-42'}),
        {'PostID': 'post-42'},
      );
    });

    test('unwraps FCM_MSG.data', () {
      expect(
        WebNotificationDeepLink.extractAppData({
          'FCM_MSG': {
            'notification': {'title': 'Updated'},
            'data': {'PostID': 'post-42', 'CloseText': 'Got it'},
          },
        }),
        {'PostID': 'post-42', 'CloseText': 'Got it'},
      );
    });

    test('unwraps FCM_MSG when keys sit on the envelope', () {
      expect(
        WebNotificationDeepLink.extractAppData({
          'FCM_MSG': {'InfoPage': 'core_values'},
        }),
        {'InfoPage': 'core_values'},
      );
    });

    test('returns empty map for null or empty input', () {
      expect(WebNotificationDeepLink.extractAppData(null), isEmpty);
      expect(WebNotificationDeepLink.extractAppData({}), isEmpty);
    });
  });

  group('WebNotificationDeepLink.openActionKind', () {
    test('labels post and info targets', () {
      expect(
        WebNotificationDeepLink.openActionKind({'PostID': 'p'}),
        WebNotificationDeepLink.openKindPost,
      );
      expect(
        WebNotificationDeepLink.openActionKind({'InfoPage': 'core_values'}),
        WebNotificationDeepLink.openKindInfo,
      );
      expect(WebNotificationDeepLink.openActionKind({}), isNull);
    });
  });

  group('WebNotificationDeepLink.pathFromData', () {
    test('builds post and info query paths', () {
      expect(
        WebNotificationDeepLink.pathFromData({'PostID': 'post-42'}),
        '/?postId=post-42',
      );
      expect(
        WebNotificationDeepLink.pathFromData({'InfoPage': 'core values'}),
        '/?infoPage=core%20values',
      );
    });

    test('unwraps FCM_MSG before building the path', () {
      expect(
        WebNotificationDeepLink.pathFromData({
          'FCM_MSG': {
            'data': {'PostID': 'post-42'},
          },
        }),
        '/?postId=post-42',
      );
    });

    test('returns root when there is no target', () {
      expect(WebNotificationDeepLink.pathFromData({'foo': 'bar'}), '/');
    });
  });
}
