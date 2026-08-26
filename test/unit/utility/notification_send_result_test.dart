import 'package:ctrim_app/utility/notifications/notification_send_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationSendResult', () {
    test('feedbackMessage for empty skip', () {
      const result = NotificationSendResult(skippedEmpty: true);
      expect(result.feedbackMessage, 'No registered devices to notify');
    });

    test('feedbackMessage for topic + deliveries', () {
      const result = NotificationSendResult(
        topicSent: true,
        successCount: 3,
        failureCount: 1,
        invalidTokenCount: 1,
      );
      expect(
        result.feedbackMessage,
        'Broadcast sent · delivered to 3 devices · 1 failed · 1 stale token removed',
      );
    });

    test('merge accumulates counts', () {
      const a = NotificationSendResult(successCount: 2, topicSent: true);
      const b = NotificationSendResult(successCount: 1, failureCount: 1);
      final merged = a.merge(b);
      expect(merged.successCount, 3);
      expect(merged.failureCount, 1);
      expect(merged.topicSent, true);
    });
  });
}
