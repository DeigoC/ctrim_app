import 'package:ctrim_app/utility/notification_device_status.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationDeviceStatus', () {
    NotificationDeviceStatus status({
      AuthorizationStatus permission = AuthorizationStatus.authorized,
      bool hasLocalToken = true,
      bool isWeb = false,
      bool isPwaInstalled = true,
      bool isIosBrowser = false,
      int subscribedTopicCount = 1,
    }) {
      return NotificationDeviceStatus(
        permission: permission,
        hasLocalToken: hasLocalToken,
        tokenPreview: hasLocalToken ? 'abc…' : null,
        isWeb: isWeb,
        isPwaInstalled: isPwaInstalled,
        isIosBrowser: isIosBrowser,
        subscribedTopicCount: subscribedTopicCount,
      );
    }

    test('looksHealthy when permission + token and not blocked by iOS tab', () {
      expect(status().looksHealthy, isTrue);
      expect(
        status(
          isWeb: true,
          isIosBrowser: true,
          isPwaInstalled: false,
        ).looksHealthy,
        isFalse,
      );
    });

    test('needsHomeScreenInstall only for iOS web not installed', () {
      expect(
        status(isWeb: true, isIosBrowser: true, isPwaInstalled: false)
            .needsHomeScreenInstall,
        isTrue,
      );
      expect(
        status(isWeb: true, isIosBrowser: true, isPwaInstalled: true)
            .needsHomeScreenInstall,
        isFalse,
      );
      expect(
        status(isWeb: true, isIosBrowser: false, isPwaInstalled: false)
            .needsHomeScreenInstall,
        isFalse,
      );
    });

    test('primaryIssue prioritises iOS home screen, then permission, then token',
        () {
      expect(
        status(
          isWeb: true,
          isIosBrowser: true,
          isPwaInstalled: false,
          permission: AuthorizationStatus.denied,
          hasLocalToken: false,
        ).primaryIssue,
        contains('Home Screen'),
      );
      expect(
        status(permission: AuthorizationStatus.denied, hasLocalToken: false)
            .primaryIssue,
        contains('blocked'),
      );
      expect(
        status(
          permission: AuthorizationStatus.authorized,
          hasLocalToken: false,
        ).primaryIssue,
        contains('No push token'),
      );
      expect(status().primaryIssue, isNull);
    });
  });
}
