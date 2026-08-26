import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../utility/notification_token_resolver.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../firebase/functions_manager.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/event_heads_repository.dart';
import '../../utility/local_data_manager.dart';
import 'update_log_dialog.dart';

class EventLogDialog extends StatefulWidget {
  const EventLogDialog(
      {super.key,
      required this.eventContext,
      required this.updatePage,
      required this.originalTitle,
      required this.topic});
  final EventContext eventContext;
  final Function() updatePage;
  final String originalTitle;
  final String topic;

  @override
  State<EventLogDialog> createState() => _EventLogDialogState();
}

class _EventLogDialogState extends State<EventLogDialog> {
  late final AppContext _appContext;
  late final String _currentUserName, _currentUID;
  final CloudFunctionManager _cloudFunctionManager = CloudFunctionManager();
  final NotificationTokenResolver _tokenResolver = NotificationTokenResolver();

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    _currentUID = _appContext.currentUser.id;
    _currentUserName = _appContext.currentUser.forname;
    super.initState();
  }

  Future<void> _cacheTokensForUser(final String uid) async {
    if (_appContext.haveTokensForUserID(uid)) return;
    final authID = _appContext.authIdByUserId(uid);
    if (authID == null || authID.isEmpty) return;
    final tokens = await _tokenResolver.resolveForAuthID(authID);
    _appContext.addTokensToUserID(uid, tokens);
  }

  @override
  Widget build(BuildContext context) {
    return UpdateLogDialog(
      title: 'Save changes',
      subtitle:
          'Add a short update. People who bookmarked this post will be notified.',
      hintText: 'e.g. Added new images',
      confirmLabel: 'Save post',
      onSave: _saveClick,
    );
  }

  Future<void> _saveClick(String log) async {
    final confirmation = await DialogManager.showConfirmationDialog(
        context: context,
        title: 'Confirm save?',
        content:
            'This note will be sent to everyone who bookmarked this post. Continue?',
        confirmText: 'Save',
        cancelText: 'Cancel',
        icon: Icons.notifications_active_outlined);

    if (!confirmation || !mounted) return;

    final saved = await DialogManager.runWithSteppedProgressDialog(
      context: context,
      title: 'Uploading Changes',
      initialMessage: 'Saving post…',
      errorTitle: 'Could not save changes',
      action: (onProgress) =>
          _performUpdate(_appContext.currentUser.id, log, onProgress),
    );
    if (!mounted || !saved) return;
    _appContext.setMetadata(
        widget.eventContext.id, widget.eventContext.metadata);
    for (final entry in widget.eventContext.lastParentLinkSync.entries) {
      _appContext.setMetadata(entry.key, entry.value);
    }
    widget.eventContext.resetSavingOfTheEdit();
    _appContext.addOrUpdatePostHead(widget.eventContext.head);
    widget.updatePage();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Changes Saved!'), behavior: SnackBarBehavior.floating));
  }

  Future<void> _performUpdate(final String uid, final String log,
      LoadProgressReporter onProgress) async {
    const total = 3;
    onProgress(completed: 0, total: total, message: 'Saving post…');
    final LocalDataManager localDataManager = LocalDataManager();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await widget.eventContext.updatePost(log: log, uid: uid);
    final content =
        widget.eventContext.transformPostToTxtFile(packageInfo.version);
    localDataManager.writePostData(widget.eventContext.id, content);
    try {
      await persistEventHeadsLocalCache(List.of(_appContext.eventHeads));
    } catch (e) {
      debugPrint('Could not persist event heads after post save: $e');
    }

    try {
      if (widget.eventContext.head.eventDate != null) {
        onProgress(
            completed: 1, total: total, message: 'Syncing schedule roles…');
        await _cloudFunctionManager.syncUserRolesForPost(
          postId: widget.eventContext.id,
          removedUserIds: widget.eventContext.collectRoleRemovalUserIds(),
        );
      } else {
        onProgress(
            completed: 1, total: total, message: 'Sending notifications…');
      }

      onProgress(completed: 2, total: total, message: 'Sending notifications…');
      final List<Future<void>> tasks = [
        _sendContributorAdditionNotificaitons(),
        _sendContributorRemovalNotificaitons(),
        _updateAllUserPostInvolvement(),
      ];
      if (widget.eventContext.head.eventDate != null) {
        tasks.add(_sortRoleAdditions());
        tasks.add(_sendRoleRemovals());
      }
      await Future.wait(tasks);
      _sendPostNotification(log);
    } catch (e, stack) {
      debugPrint(
          'Post saved but follow-up notifications/sync failed: $e\n$stack');
    }
  }

  Future<void> _sendPostNotification(String log) async {
    // message to topic
    // message to author + contributors
    // hmm basically both will use the same title-subtitle but we should mention who updated it

    final String adminSubtitle = '$_currentUserName updated: $log';
    final String? keyGraphic = widget.eventContext.head.getKeyGraphic();

    final List<String> deviceTokens = await _getAdminContactTokens();

    if (deviceTokens.isNotEmpty) {
      await _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: deviceTokens,
          title: widget.originalTitle,
          body: adminSubtitle,
          data: _notificationdata);
    }

    await _cloudFunctionManager.sendToTopic(
        topic: widget.topic,
        title: widget.originalTitle,
        body: log,
        data: _notificationdata,
        iOSImage: keyGraphic,
        androidImage: keyGraphic);
  }

  Future<List<String>> _getAdminContactTokens() async {
    // Fetching all the contacts for the admins
    // Remember to remove the current user from this list
    // Fetch all the contributor device tokens (unless it's the current user)

    final List<String> missingContacts = widget
        .eventContext.metadata.contributorUIDs
        .where((contributorID) =>
            contributorID.compareTo(_currentUID) != 0 &&
            !_appContext.haveTokensForUserID(contributorID))
        .toList();

    // fetch the author contact (if the current user isn't already the author)
    if (_currentUID.compareTo(widget.eventContext.metadata.authorUID) != 0 &&
        !_appContext
            .haveTokensForUserID(widget.eventContext.metadata.authorUID)) {
      missingContacts.add(widget.eventContext.metadata.authorUID);
    }

    // fetch and add any missing contacts we need for this operation
    debugPrint('missing contacts are: $missingContacts');
    for (final String uid in missingContacts) {
      await _cacheTokensForUser(uid);
    }

    // create token list of contributors
    final List<String> deviceTokens = List<String>.empty(growable: true);
    for (final String contributorID
        in widget.eventContext.metadata.contributorUIDs) {
      if (_appContext.currentUser.id.compareTo(contributorID) != 0) {
        deviceTokens.addAll(_appContext.getTokensFromUserID(contributorID));
      }
    }

    // add the author tokens
    if (_appContext.currentUser.id
            .compareTo(widget.eventContext.metadata.authorUID) !=
        0) {
      deviceTokens.addAll(_appContext
          .getTokensFromUserID(widget.eventContext.metadata.authorUID));
    }

    return deviceTokens;
  }

  // sends notifications and handles the user roles document for addition of role
  Future<void> _sortRoleAdditions() async {
    final DateFormat dateFormat = DateFormat('EEE, MMM d'),
        timeFormat = DateFormat('HH:mm');
    final String title =
        "📣 $_currentUserName has assinged you to a task for ${dateFormat.format(widget.eventContext.head.eventDate!)}";

    for (final additionEntry in widget.eventContext.roleAdditions.entries) {
      debugPrint('----- this addition entry looks like: $additionEntry');
      final roleEntry = widget.eventContext.program.roles
          .firstWhere((e) => e['id'] == additionEntry.key);
      final DateTime start = roleEntry['start'];
      final String body =
          "You are assigned to '${roleEntry['title']!}' for ${widget.originalTitle} at ${timeFormat.format(start)}";

      final List<String> tokens = [];
      for (final thisUID in additionEntry.value) {
        if (thisUID != _currentUID) {
          if (!_appContext.haveTokensForUserID(thisUID)) {
            debugPrint('fetching tokens for UID: $thisUID');
            await _cacheTokensForUser(thisUID);
          }

          tokens.addAll(_appContext.getTokensFromUserID(thisUID));
        }
      }
      _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: tokens, title: title, body: body, data: _notificationdata);
    }
  }

  // sends notifications and handles the user roles document for removal of role
  Future<void> _sendRoleRemovals() async {
    final String title = "$_currentUserName has removed you from a role";

    debugPrint(
        'on the removals: the entries look like:${widget.eventContext.roleRemovalals.entries}');
    for (final removalEntry in widget.eventContext.roleRemovalals.entries) {
      final String roleTitle =
          widget.eventContext.deletedRoleTitle(removalEntry.key);
      final String body =
          "You are no longer assigned to '$roleTitle' for ${widget.originalTitle}";

      final List<String> tokens = [];
      for (final thisUID in removalEntry.value) {
        if (thisUID != _currentUID) {
          if (!_appContext.haveTokensForUserID(thisUID)) {
            debugPrint('fetching tokens for UID: $thisUID');
            await _cacheTokensForUser(thisUID);
          }

          tokens.addAll(_appContext.getTokensFromUserID(thisUID));
        }
      }
      await _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: tokens, title: title, body: body, data: _notificationdata);
    }
  }

  Future<void> _sendContributorAdditionNotificaitons() async {
    const String title = "Contributor update";
    final String body =
        "You can modify aspects of the post: '${widget.originalTitle}'";
    final List<String> allTokens = List<String>.empty(growable: true);

    for (final String thisUID in widget.eventContext.contributorAdditionUIDs) {
      if (thisUID != _currentUID) {
        if (!_appContext.haveTokensForUserID(thisUID)) {
          await _cacheTokensForUser(thisUID);
        }

        allTokens.addAll(_appContext.getTokensFromUserID(thisUID));
      }
    }

    if (allTokens.isNotEmpty) {
      _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: allTokens, title: title, body: body, data: _notificationdata);
    }
  }

  Future<void> _sendContributorRemovalNotificaitons() async {
    const String title = "Contributor update";
    final String body =
        "You have been removed as a contributor for '${widget.originalTitle}'";
    final List<String> allTokens = List<String>.empty(growable: true);

    for (final String thisUID in widget.eventContext.contributorRemovalUIDs) {
      if (thisUID != _currentUID) {
        if (!_appContext.haveTokensForUserID(thisUID)) {
          await _cacheTokensForUser(thisUID);
        }

        allTokens.addAll(_appContext.getTokensFromUserID(thisUID));
      }
    }

    if (allTokens.isNotEmpty) {
      _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: allTokens, title: title, body: body, data: _notificationdata);
    }
  }

  Future<void> _updateAllUserPostInvolvement() async {
    final String postID = widget.eventContext.id;
    final UserDBManager userDBManager = UserDBManager();

    // then add the new contributors
    for (final String contributorID
        in widget.eventContext.contributorAdditionUIDs) {
      await userDBManager.addPostToUser(contributorID, postID, 'contributor');
    }

    // then remove the old contributors
    for (final String contributorID
        in widget.eventContext.contributorRemovalUIDs) {
      await userDBManager.removePostFromUser(contributorID, postID);
    }
  }

  Map<String, String> get _notificationdata =>
      {'PostID': widget.eventContext.id};
}
