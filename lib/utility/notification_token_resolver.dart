import '../firebase/db_managers/everyone_db_manager.dart';
import '../firebase/messaging_manager.dart';
import 'notification_debug.dart';

/// Merges native device tokens (everyone/supplemental) with web FCM tokens.
class NotificationTokenResolver {
  final EveryoneDBManager _everyoneDBManager = EveryoneDBManager();

  Future<List<String>> resolveForAuthID(String authID) async {
    final tokens = <String>{};

    final deviceTokens = await _everyoneDBManager.fetchTokensFromAuthID(authID);
    tokens.addAll(deviceTokens);

    final webTokens = await MessagingManager.getWebTokensForAuthId(authID);
    tokens.addAll(webTokens);

    NotificationDebug.log(
      'resolveForAuthID($authID): ${deviceTokens.length} device + ${webTokens.length} web → ${tokens.length} total',
    );
    return tokens.toList();
  }
}
