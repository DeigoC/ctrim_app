/// Result of a push notification send (topic and/or token multicast).
class NotificationSendResult {
  const NotificationSendResult({
    this.successCount = 0,
    this.failureCount = 0,
    this.invalidTokenCount = 0,
    this.topicSent = false,
    this.webRecipientCount = 0,
    this.skippedEmpty = false,
  });

  final int successCount;
  final int failureCount;
  final int invalidTokenCount;
  final bool topicSent;
  final int webRecipientCount;
  final bool skippedEmpty;

  bool get hasFailures => failureCount > 0;
  bool get hasSuccess => topicSent || successCount > 0;

  NotificationSendResult merge(NotificationSendResult other) {
    return NotificationSendResult(
      successCount: successCount + other.successCount,
      failureCount: failureCount + other.failureCount,
      invalidTokenCount: invalidTokenCount + other.invalidTokenCount,
      topicSent: topicSent || other.topicSent,
      webRecipientCount: webRecipientCount + other.webRecipientCount,
      skippedEmpty: skippedEmpty && other.skippedEmpty,
    );
  }

  /// Short message for leader snackbars.
  String get feedbackMessage {
    if (skippedEmpty && !topicSent) {
      return 'No registered devices to notify';
    }

    final parts = <String>[];
    if (topicSent) {
      parts.add('Broadcast sent');
    }
    if (successCount > 0) {
      parts.add(
        'delivered to $successCount device${successCount == 1 ? '' : 's'}',
      );
    }
    if (webRecipientCount > 0 && !topicSent) {
      // web-only path already counted in successCount
    }
    if (failureCount > 0) {
      parts.add('$failureCount failed');
    }
    if (invalidTokenCount > 0) {
      parts.add(
          '$invalidTokenCount stale token${invalidTokenCount == 1 ? '' : 's'} removed');
    }

    if (parts.isEmpty) {
      return topicSent ? 'Broadcast sent' : 'Notification send finished';
    }
    return parts.join(' · ');
  }
}
