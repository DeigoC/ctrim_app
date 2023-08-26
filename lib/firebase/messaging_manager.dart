import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class MessagingManager {
  static final FirebaseMessaging _instance = FirebaseMessaging.instance;
  static const String _ctrimBelfast = 'ctrim-belfast';
  // static const String _vapidKey =
  //     'BCV6Yz5C4xwZlwWt104ss7BFwIcHI8_GVgsRh0S_-sXwPOyskvjifqkaPGMXn9T3zyIdHGnX4w7w9x6cmpTcZq0';

  Future<String?> requestPermissionAndToken() async {
    // let's disable requesting for notifications since it's quite broken at the moment
    if (kIsWeb) {
      return null;
    }
    await _instance.requestPermission();

    final String? token = await _instance.getToken(vapidKey: kIsWeb ? '_vapidKey' : null);
    debugPrint('token generated is $token');
    return token;
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      return null;
    }
    final token = await _instance.getToken(vapidKey: kIsWeb ? '_vapidKey' : null);
    debugPrint('token generated is $token');
    return token;
  }

  Future<void> subscribeToCTRIMBelfast() async {
    if (!kIsWeb) {
      return _instance.subscribeToTopic(_ctrimBelfast);
    }
  }

  Future<void> unsubscribeFromCTRIMBelfast() async {
    if (!kIsWeb) {
      return _instance.unsubscribeFromTopic(_ctrimBelfast);
    }
  }

  Future<void> subscribeToTopic(final String topic) async {
    if (!kIsWeb) {
      return _instance.subscribeToTopic(topic);
    }
  }

  Future<void> unsubscribeFromTopic(final String topic) async {
    if (!kIsWeb) {
      return _instance.unsubscribeFromTopic(topic);
    }
  }
}
