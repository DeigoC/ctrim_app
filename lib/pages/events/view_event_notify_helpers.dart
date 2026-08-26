import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../firebase/functions_manager.dart';
import '../../utility/app_context.dart';
import '../../utility/event_context.dart';
import '../../utility/notification_send_result.dart';
import '../../utility/notification_token_resolver.dart';

class ScheduledRoleReminder {
  const ScheduledRoleReminder({
    required this.roleTitle,
    required this.body,
    required this.recipientUids,
  });

  final String roleTitle;
  final String body;
  final List<String> recipientUids;
}

String scheduledMemberReminderTitle(
  DateTime eventDate, {
  DateFormat? dateFormat,
}) {
  final format = dateFormat ?? DateFormat('EEE, MMM d');
  return '📣 Reminder of your task - ${format.format(eventDate)}!';
}

String scheduledMemberReminderBody({
  required String roleTitle,
  required String postTitle,
  required DateTime startingTime,
  DateFormat? timeFormat,
}) {
  final format = timeFormat ?? DateFormat('HH:mm');
  return "'$roleTitle' for $postTitle.\nStarting ${format.format(startingTime)}";
}

/// Builds per-role reminder copy, skipping roles with no start time.
List<ScheduledRoleReminder> scheduledRoleRemindersFromProgram({
  required List<Map<String, dynamic>> roles,
  required String postTitle,
  required String currentUid,
  DateFormat? timeFormat,
}) {
  final reminders = <ScheduledRoleReminder>[];
  for (final roleEntry in roles) {
    final DateTime? startingTime = roleEntry['start'];
    if (startingTime == null) {
      debugPrint('Warning: Role entry missing start time, skipping...');
      continue;
    }

    final String roleTitle = roleEntry['title'] ?? 'Untitled Role';
    final List<dynamic> uidsRaw = roleEntry['uids'] ?? [];
    final recipientUids =
        uidsRaw.whereType<String>().where((uid) => uid != currentUid).toList();

    reminders.add(ScheduledRoleReminder(
      roleTitle: roleTitle,
      body: scheduledMemberReminderBody(
        roleTitle: roleTitle,
        postTitle: postTitle,
        startingTime: startingTime,
        timeFormat: timeFormat,
      ),
      recipientUids: recipientUids,
    ));
  }
  return reminders;
}

class ScheduledMemberNotifyResult {
  const ScheduledMemberNotifyResult({
    required this.combined,
    required this.usersWithoutTokens,
  });

  final NotificationSendResult combined;
  final int usersWithoutTokens;

  String get feedbackMessage {
    var message = combined.feedbackMessage;
    if (usersWithoutTokens > 0) {
      message =
          '$message · $usersWithoutTokens member${usersWithoutTokens == 1 ? '' : 's'} had no device';
    }
    return message;
  }
}

Future<ScheduledMemberNotifyResult> sendScheduledMemberRoleNotifications({
  required AppContext appContext,
  required EventContext eventContext,
  NotificationTokenResolver? tokenResolver,
  CloudFunctionManager? cloudFunctionManager,
}) async {
  final resolver = tokenResolver ?? NotificationTokenResolver();
  final functions = cloudFunctionManager ?? CloudFunctionManager();
  final currentUID = appContext.currentUser.id;
  final title = scheduledMemberReminderTitle(eventContext.head.eventDate!);

  var combined = const NotificationSendResult();
  var usersWithoutTokens = 0;

  final reminders = scheduledRoleRemindersFromProgram(
    roles: eventContext.program.roles,
    postTitle: eventContext.head.title,
    currentUid: currentUID,
  );

  for (final reminder in reminders) {
    try {
      final tokens = <String>[];
      for (final thisUID in reminder.recipientUids) {
        try {
          if (!appContext.haveTokensForUserID(thisUID)) {
            final authID = appContext.authIdByUserId(thisUID);
            if (authID != null && authID.isNotEmpty) {
              final fetchedTokens = await resolver.resolveForAuthID(authID);
              if (fetchedTokens.isNotEmpty) {
                appContext.addTokensToUserID(thisUID, fetchedTokens);
                tokens.addAll(fetchedTokens);
              } else {
                usersWithoutTokens++;
              }
            } else {
              debugPrint(
                  'Warning: Could not get authID for user $thisUID, skipping...');
              usersWithoutTokens++;
            }
          } else {
            tokens.addAll(appContext.getTokensFromUserID(thisUID));
          }
        } catch (e) {
          debugPrint('Error fetching tokens for user $thisUID: $e');
          usersWithoutTokens++;
          continue;
        }
      }

      if (tokens.isNotEmpty) {
        try {
          final result = await functions.sendMessageToSelectedTokens(
            tokens: tokens,
            title: title,
            body: reminder.body,
            data: {'PostID': eventContext.id},
          );
          combined = combined.merge(result);
        } catch (e) {
          debugPrint(
              'Error sending notification for role "${reminder.roleTitle}": $e');
          combined =
              combined.merge(const NotificationSendResult(failureCount: 1));
        }
      }
    } catch (e) {
      debugPrint('Error processing role entry: $e');
      combined = combined.merge(const NotificationSendResult(failureCount: 1));
      continue;
    }
  }

  return ScheduledMemberNotifyResult(
    combined: combined,
    usersWithoutTokens: usersWithoutTokens,
  );
}
