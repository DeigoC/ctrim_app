import 'package:firebase_messaging/firebase_messaging.dart';

class MessagingManager {
  static final FirebaseMessaging _instance = FirebaseMessaging.instance;
  static const String _ctrimBelfast = 'ctrim-belfast';

  Future<String?> requestPermissionAndToken() async {
    await _instance.requestPermission();

    // doesn't matter the result, we still want to get the token
    final String? token = await _instance.getToken();
    return token;
  }

  Future<void> subscribeToCTRIMBelfast() {
    return _instance.subscribeToTopic(_ctrimBelfast);
  }
}
