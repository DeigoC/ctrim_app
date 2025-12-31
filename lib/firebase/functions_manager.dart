import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'messaging_manager.dart';

class CloudFunctionManager {
  static final _inst = FirebaseFunctions.instanceFor(region: 'europe-west1');

  CloudFunctionManager() {
    if (kDebugMode) {
      _inst.useFunctionsEmulator('localhost', 5001);
    }
  }

  Future<void> sendMessageToSelectedTokens(
      {required List<String> tokens,
      required String title,
      required String body,
      required Map<String, String> data,
      String? androidImage,
      String? iOSImage}) async {
    String tokensStr = '';
    for (String token in tokens) {
      tokensStr += '$token,';
    }
    if (tokensStr.isNotEmpty) {
      tokensStr = tokensStr.substring(0, tokensStr.length - 1);
    }

    final List<String> dataStrings = _convertMapToKeyValueStrings(data);
    final Map<String, String> callParams = {
      'Title': title,
      'Body': body,
      'DataKeys': dataStrings[0],
      'DataValues': dataStrings[1],
      'Tokens': tokensStr,
      'iOSImage': iOSImage ?? '',
      'AndroidImage': androidImage ?? '',
    };

    if (!kDebugMode) {
      final HttpsCallable callable = _inst.httpsCallable('send_notification_to_multiple_tokens');
      final result = await callable.call(callParams);
      debugPrint(result.data.toString());
    } else {
      debugPrint('------------------------');
      debugPrint('in debug - send_notification_to_multiple_tokens was meant to be called');
      debugPrint('title: $title');
      debugPrint('body: $body');
      debugPrint('data is: $data');
      debugPrint('tokens are: $tokens');
      debugPrint('ios and android image is: ${iOSImage ?? 'null'}');
      debugPrint('------------------------');
    }
  }

  /// Send notification to topic and also to all web tokens
  /// This ensures web users receive topic notifications too
  Future<void> sendToTopic(
      {required String topic,
      required String title,
      required String body,
      required Map<String, String> data,
      String? androidImage,
      String? iOSImage}) async {
    final List<String> dataStrings = _convertMapToKeyValueStrings(data);
    final Map<String, String> callParams = {
      'Title': title,
      'Body': body,
      'DataKeys': dataStrings[0],
      'DataValues': dataStrings[1],
      'Topic': topic,
      'iOSImage': iOSImage ?? '',
      'AndroidImage': androidImage ?? '',
    };

    if (!kDebugMode) {
      // Send to topic (iOS/Android)
      final HttpsCallable topicCallable = _inst.httpsCallable('send_to_topic');
      final topicResult = await topicCallable.call(callParams);
      debugPrint('Topic notification sent: ${topicResult.data}');

      // Get web tokens for general notifications
      final webTokens = await MessagingManager.getWebTokens();

      // Get web tokens subscribed to this specific topic
      final webTopicTokens = await MessagingManager.getWebTokensForTopic(topic);

      // Combine and deduplicate tokens
      final allWebTokens = {...webTokens, ...webTopicTokens}.toList();

      if (allWebTokens.isNotEmpty) {
        debugPrint('Sending to ${allWebTokens.length} web tokens (${webTopicTokens.length} topic-specific)...');
        await sendMessageToSelectedTokens(
          tokens: allWebTokens,
          title: title,
          body: body,
          data: data,
          androidImage: androidImage,
          iOSImage: iOSImage,
        );
      }
    } else {
      debugPrint('------------------------');
      debugPrint('in debug - send_to_topic was meant to be called. The following are the details to be sent:');
      debugPrint('title: $title');
      debugPrint('body: $body');
      debugPrint('data is: $data');
      debugPrint('topic is: $topic');
      debugPrint('ios and android image is: ${iOSImage ?? 'null'}');
      debugPrint('------------------------');
    }
  }

  List<String> _convertMapToKeyValueStrings(final Map<String, String> data) {
    String dataKeys = '', dataValues = '';
    if (data.isNotEmpty) {
      for (final element in data.entries) {
        dataKeys += '${element.key},';
        dataValues += '${element.value},';
      }
      dataKeys = dataKeys.substring(0, dataKeys.length - 1);
      dataValues = dataValues.substring(0, dataValues.length - 1);
    }

    return [dataKeys, dataValues];
  }
}
