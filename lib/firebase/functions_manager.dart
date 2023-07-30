import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

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

    final HttpsCallable callable = _inst.httpsCallable('send_notification_to_multiple_tokens');
    final result = await callable.call(callParams);

    debugPrint(result.data.toString());
  }

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

    final HttpsCallable callable = _inst.httpsCallable('send_to_topic');
    final result = await callable.call(callParams);

    debugPrint(result.data.toString());
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

  Future<void> helloWorld() async {
    final HttpsCallable callable = _inst.httpsCallable('hello_world');
    final result = await callable.call({'Message': 'Hello World'});
    debugPrint(result.data.toString());
  }
}
