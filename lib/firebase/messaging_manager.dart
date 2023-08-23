import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class MessagingManager {
  static final FirebaseMessaging _instance = FirebaseMessaging.instance;
  static const String _ctrimBelfast = 'ctrim-belfast';
  static const String _vapidKey =
      'BCV6Yz5C4xwZlwWt104ss7BFwIcHI8_GVgsRh0S_-sXwPOyskvjifqkaPGMXn9T3zyIdHGnX4w7w9x6cmpTcZq0';

  Future<String?> requestPermissionAndToken() async {
    await _instance.requestPermission();

    final String? token = await _instance.getToken(vapidKey: kIsWeb ? _vapidKey : null);
    return token;
  }

  Future<String?> getToken() async {
    return await _instance.getToken();
  }

  Future<void> subscribeToCTRIMBelfast() {
    return _instance.subscribeToTopic(_ctrimBelfast);
  }

  Future<void> unsubscribeFromCTRIMBelfast() {
    return _instance.unsubscribeFromTopic(_ctrimBelfast);
  }

  Future<void> subscribeToTopic(final String topic) {
    return _instance.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(final String topic) {
    return _instance.unsubscribeFromTopic(topic);
  }
}
