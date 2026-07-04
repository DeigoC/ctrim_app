import 'package:cloud_functions/cloud_functions.dart';

import '../utility/notification_debug.dart';
import '../utility/notification_token_resolver.dart';
import 'messaging_manager.dart';

class CloudFunctionManager {
  static final _inst = FirebaseFunctions.instanceFor(region: 'europe-west1');
  final NotificationTokenResolver _tokenResolver = NotificationTokenResolver();

  CloudFunctionManager();

  /// Send to native topic subscribers plus web tokens stored for [topic] in Firestore.
  Future<void> sendToTopic({
    required String topic,
    required String title,
    required String body,
    required Map<String, String> data,
    String? androidImage,
    String? iOSImage,
  }) async {
    NotificationDebug.section('sendToTopic → send_to_topic');
    NotificationDebug.log('topic=$topic title=$title');

    final dataStrings = _convertMapToKeyValueStrings(data);
    final callParams = {
      'Title': title,
      'Body': body,
      'DataKeys': dataStrings[0],
      'DataValues': dataStrings[1],
      'Topic': topic,
      'iOSImage': iOSImage ?? '',
      'AndroidImage': androidImage ?? '',
    };

    await _callCloudFunction('send_to_topic', callParams);
    await _sendToWebTokens(
      topic: topic,
      title: title,
      body: body,
      data: data,
      androidImage: androidImage,
      iOSImage: iOSImage,
    );
  }

  /// Direct send: merges everyone device_tokens + web tokens per auth ID.
  Future<void> sendMessageToAuthUsers({
    required List<String> authIDs,
    required String title,
    required String body,
    required Map<String, String> data,
    String? androidImage,
    String? iOSImage,
  }) async {
    NotificationDebug.section('sendMessageToAuthUsers');
    NotificationDebug.log('authIDs=$authIDs title=$title');

    final tokens = <String>{};
    for (final authID in authIDs) {
      if (authID.isEmpty) continue;
      tokens.addAll(await _tokenResolver.resolveForAuthID(authID));
    }

    if (tokens.isEmpty) {
      NotificationDebug.warn('sendMessageToAuthUsers: no tokens');
      return;
    }

    await sendMessageToSelectedTokens(
      tokens: tokens.toList(),
      title: title,
      body: body,
      data: data,
      androidImage: androidImage,
      iOSImage: iOSImage,
    );
  }

  Future<void> sendMessageToSelectedTokens({
    required List<String> tokens,
    required String title,
    required String body,
    required Map<String, String> data,
    String? androidImage,
    String? iOSImage,
  }) async {
    if (tokens.isEmpty) {
      NotificationDebug.warn('sendMessageToSelectedTokens: empty token list');
      return;
    }

    final uniqueTokens = tokens.toSet().toList();
    final dataStrings = _convertMapToKeyValueStrings(data);
    final callParams = {
      'Title': title,
      'Body': body,
      'DataKeys': dataStrings[0],
      'DataValues': dataStrings[1],
      'Tokens': uniqueTokens.join(','),
      'iOSImage': iOSImage ?? '',
      'AndroidImage': androidImage ?? '',
    };

    NotificationDebug.section('sendMessageToSelectedTokens');
    NotificationDebug.log('${uniqueTokens.length} token(s), title=$title');
    for (final t in uniqueTokens) {
      NotificationDebug.token('  recipient', t);
    }

    await _callCloudFunction('send_notification_to_multiple_tokens', callParams);
  }

  Future<void> _sendToWebTokens({
    required String topic,
    required String title,
    required String body,
    required Map<String, String> data,
    String? androidImage,
    String? iOSImage,
  }) async {
    try {
      NotificationDebug.section('_sendToWebTokens');
      NotificationDebug.log('topic=$topic');

      final webTokens = await MessagingManager.getWebTokensForTopic(topic);
      if (webTokens.isEmpty) {
        NotificationDebug.warn('No web tokens for topic "$topic"');
        return;
      }

      await sendMessageToSelectedTokens(
        tokens: webTokens,
        title: title,
        body: body,
        data: data,
        androidImage: androidImage,
        iOSImage: iOSImage,
      );
    } catch (e) {
      NotificationDebug.error('Error sending to web tokens', e);
    }
  }

  Future<void> _callCloudFunction(String name, Map<String, String> callParams) async {
    try {
      final callable = _inst.httpsCallable(name);
      final result = await callable.call(callParams);
      NotificationDebug.log('$name result: ${result.data}');
    } catch (e) {
      NotificationDebug.error('$name failed', e);
      rethrow;
    }
  }

  List<String> _convertMapToKeyValueStrings(Map<String, String> data) {
    if (data.isEmpty) {
      return ['', ''];
    }

    String dataKeys = '';
    String dataValues = '';
    for (final element in data.entries) {
      dataKeys += '${element.key},';
      dataValues += '${element.value},';
    }
    return [
      dataKeys.substring(0, dataKeys.length - 1),
      dataValues.substring(0, dataValues.length - 1),
    ];
  }
}
