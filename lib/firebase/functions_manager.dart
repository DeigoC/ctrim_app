import 'package:cloud_functions/cloud_functions.dart';

import '../utility/notification_debug.dart';
import '../utility/notification_send_result.dart';
import 'messaging_manager.dart';

class CloudFunctionManager {
  static final _inst = FirebaseFunctions.instanceFor(region: 'europe-west1');

  CloudFunctionManager();

  /// Send to native topic subscribers plus web tokens stored for [topic] in Firestore.
  Future<NotificationSendResult> sendToTopic({
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
    final webResult = await _sendToWebTokens(
      topic: topic,
      title: title,
      body: body,
      data: data,
      androidImage: androidImage,
      iOSImage: iOSImage,
    );

    return NotificationSendResult(
      topicSent: true,
      successCount: webResult.successCount,
      failureCount: webResult.failureCount,
      invalidTokenCount: webResult.invalidTokenCount,
      webRecipientCount: webResult.webRecipientCount,
    );
  }

  Future<NotificationSendResult> sendMessageToSelectedTokens({
    required List<String> tokens,
    required String title,
    required String body,
    required Map<String, String> data,
    String? androidImage,
    String? iOSImage,
  }) async {
    if (tokens.isEmpty) {
      NotificationDebug.warn('sendMessageToSelectedTokens: empty token list');
      return const NotificationSendResult(skippedEmpty: true);
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

    final raw = await _callCloudFunction('send_notification_to_multiple_tokens', callParams);
    return _parseSendResult(raw, fallbackSuccess: uniqueTokens.length);
  }

  Future<NotificationSendResult> _sendToWebTokens({
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
        return const NotificationSendResult();
      }

      final result = await sendMessageToSelectedTokens(
        tokens: webTokens,
        title: title,
        body: body,
        data: data,
        androidImage: androidImage,
        iOSImage: iOSImage,
      );
      return NotificationSendResult(
        successCount: result.successCount,
        failureCount: result.failureCount,
        invalidTokenCount: result.invalidTokenCount,
        webRecipientCount: webTokens.length,
        skippedEmpty: result.skippedEmpty,
      );
    } catch (e) {
      NotificationDebug.error('Error sending to web tokens', e);
      return const NotificationSendResult(failureCount: 1);
    }
  }

  Future<Map<String, dynamic>> _callCloudFunction(
    String name,
    Map<String, String> callParams,
  ) async {
    try {
      final callable = _inst.httpsCallable(name);
      final result = await callable.call(callParams);
      NotificationDebug.log('$name result: ${result.data}');
      final data = result.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {};
    } catch (e) {
      NotificationDebug.error('$name failed', e);
      rethrow;
    }
  }

  NotificationSendResult _parseSendResult(
    Map<String, dynamic> raw, {
    required int fallbackSuccess,
  }) {
    final success = _asInt(raw['success_count']) ?? fallbackSuccess;
    final failure = _asInt(raw['failure_count']) ?? 0;
    final invalid = _asInt(raw['invalid_token_count']) ?? 0;
    return NotificationSendResult(
      successCount: success,
      failureCount: failure,
      invalidTokenCount: invalid,
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  /// Sync supplemental user roles from the saved event program (Phase 4 CF).
  Future<void> syncUserRolesForPost({
    required String postId,
    List<String> removedUserIds = const [],
  }) async {
    try {
      NotificationDebug.section('syncUserRolesForPost');
      NotificationDebug.log('postId=$postId removed=${removedUserIds.length}');
      final callable = _inst.httpsCallable('sync_user_roles_for_post');
      final result = await callable.call({
        'PostID': postId,
        'RemovedUIDs': removedUserIds.join(','),
      });
      NotificationDebug.log('sync_user_roles_for_post result: ${result.data}');
    } catch (e) {
      NotificationDebug.error('sync_user_roles_for_post failed', e);
    }
  }

  /// Creates a placeholder volunteer profile via Admin SDK (server-enforced fields).
  Future<Map<String, dynamic>> createPlaceholderUser({
    required String forename,
    required String surname,
    String location = 'Belfast',
    String? postId,
    String? cellGroupId,
  }) async {
    final callable = _inst.httpsCallable('create_placeholder_user');
    final result = await callable.call({
      'Forename': forename,
      'Surname': surname,
      'Location': location,
      if (postId != null && postId.isNotEmpty) 'PostID': postId,
      if (cellGroupId != null && cellGroupId.isNotEmpty) 'CellGroupID': cellGroupId,
    });
    final data = result.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw StateError('create_placeholder_user returned no data');
  }

  /// Links Auth on a volunteer profile; clears [IsPlaceholder]. Creator or area admin.
  Future<Map<String, dynamic>> linkUserAuth({
    required String userId,
    required String authId,
    bool isLeader = false,
    bool isAreaAdmin = false,
  }) async {
    final callable = _inst.httpsCallable('link_user_auth');
    final result = await callable.call({
      'UserID': userId,
      'AuthID': authId,
      'IsLeader': isLeader,
      'IsAreaAdmin': isAreaAdmin,
    });
    final data = result.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw StateError('link_user_auth returned no data');
  }

  /// One-shot: empty AuthID users → IsPlaceholder true (area admin). Remove UI after use.
  Future<int> backfillPlaceholderFlags() async {
    final callable = _inst.httpsCallable('backfill_placeholder_flags');
    final result = await callable.call(<String, dynamic>{});
    final data = result.data;
    if (data is Map) {
      final updated = data['updated'];
      if (updated is int) return updated;
      if (updated is num) return updated.toInt();
    }
    return 0;
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
