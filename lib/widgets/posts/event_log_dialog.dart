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
import '../../utility/local_data_manager.dart';

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
  final TextEditingController _tecLog = TextEditingController();
  final CloudFunctionManager _cloudFunctionManager = CloudFunctionManager();
  final NotificationTokenResolver _tokenResolver = NotificationTokenResolver();
  bool _canSave = false;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    _currentUID = _appContext.currentUser.id;
    _currentUserName = _appContext.currentUser.forname;
    super.initState();
  }

  @override
  void dispose() {
    _tecLog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _tecLog,
                  decoration: const InputDecoration(hintText: 'e.g. Added new images!', label: Text('Update Log')),
                  maxLength: 128,
                  maxLines: null,
                  onChanged: _onTextChange),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  TextButton.icon(
                      onPressed: _canSave ? _saveClick : null,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Save'))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // * Logic

  void _onTextChange(String newString) {
    if (_canSave && newString.trim().isEmpty) {
      setState(() {
        _canSave = false;
      });
    } else if (!_canSave) {
      setState(() {
        _canSave = true;
      });
    }
  }

  void _saveClick() async {
    final confirmation = await DialogManager.showConfirmationDialog(
        context: context,
        title: 'Confirm Save?',
        content: 'This log will be sent to all who have bookmarked this post. Are you sure you want to continue?',
        confirmText: 'Yes',
        cancelText: 'Cancel');

    if (!confirmation || !mounted) return;

    DialogManager.showProgressDialog(context: context, title: 'Uploading Changes');
    try {
      await _performUpdate(_appContext.currentUser.id);
      if (!mounted) return;
      _appContext.setMetadata(widget.eventContext.id, widget.eventContext.metadata);
      widget.eventContext.resetSavingOfTheEdit();
      widget.updatePage();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Changes Saved!'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      debugPrint('Error saving post: $e');
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss progress dialog
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save changes: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _performUpdate(final String uid) async {
    final LocalDataManager localDataManager = LocalDataManager();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await widget.eventContext.updatePost(log: _tecLog.text.trim(), uid: uid);
    final content = widget.eventContext.transformPostToTxtFile(packageInfo.version);
    localDataManager.writePostData(widget.eventContext.id, content);

    try {
      if (widget.eventContext.head.eventDate != null) {
        await _cloudFunctionManager.syncUserRolesForPost(
          postId: widget.eventContext.id,
          removedUserIds: widget.eventContext.collectRoleRemovalUserIds(),
        );
      }

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
      _sendPostNotification();
    } catch (e, stack) {
      debugPrint('Post saved but follow-up notifications/sync failed: $e\n$stack');
    }
  }

  Future<void> _sendPostNotification() async {
    // message to topic
    // message to author + contributors
    // hmm basically both will use the same title-subtitle but we should mention who updated it

    final String subtitle = _tecLog.text.trim();
    final String adminSubtitle = '$_currentUserName updated: $subtitle';
    final String? keyGraphic = widget.eventContext.head.getKeyGraphic();

    final List<String> deviceTokens = await _getAdminContactTokens();

    if (deviceTokens.isNotEmpty) {
      await _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: deviceTokens, title: widget.originalTitle, body: adminSubtitle, data: _notificationdata);
    }

    await _cloudFunctionManager.sendToTopic(
        topic: widget.topic,
        title: widget.originalTitle,
        body: subtitle,
        data: _notificationdata,
        iOSImage: keyGraphic,
        androidImage: keyGraphic);
  }

  Future<List<String>> _getAdminContactTokens() async {
    // Fetching all the contacts for the admins
    // Remember to remove the current user from this list
    // Fetch all the contributor device tokens (unless it's the current user)

    final List<String> missingContacts = widget.eventContext.metadata.contributorUIDs
        .where((contributorID) =>
            contributorID.compareTo(_currentUID) != 0 && !_appContext.haveTokensForUserID(contributorID))
        .toList();

    // fetch the author contact (if the current user isn't already the author)
    if (_currentUID.compareTo(widget.eventContext.metadata.authorUID) != 0 &&
        !_appContext.haveTokensForUserID(widget.eventContext.metadata.authorUID)) {
      missingContacts.add(widget.eventContext.metadata.authorUID);
    }

    // fetch and add any missing contacts we need for this operation
    debugPrint('missing contacts are: $missingContacts');
    for (final String uid in missingContacts) {
      final tokens = await _tokenResolver.resolveForAuthID(_appContext.getAuthIDFromUID(uid));
      _appContext.addTokensToUserID(uid, tokens);
    }

    // create token list of contributors
    final List<String> deviceTokens = List<String>.empty(growable: true);
    for (final String contributorID in widget.eventContext.metadata.contributorUIDs) {
      if (_appContext.currentUser.id.compareTo(contributorID) != 0) {
        deviceTokens.addAll(_appContext.getTokensFromUserID(contributorID));
      }
    }

    // add the author tokens
    if (_appContext.currentUser.id.compareTo(widget.eventContext.metadata.authorUID) != 0) {
      deviceTokens.addAll(_appContext.getTokensFromUserID(widget.eventContext.metadata.authorUID));
    }

    return deviceTokens;
  }

  // sends notifications and handles the user roles document for addition of role
  Future<void> _sortRoleAdditions() async {
    final DateFormat dateFormat = DateFormat('EEE, MMM d'), timeFormat = DateFormat('HH:mm');
    final String title =
        "📣 $_currentUserName has assinged you to a task for ${dateFormat.format(widget.eventContext.head.eventDate!)}";

    for (final additionEntry in widget.eventContext.roleAdditions.entries) {
      debugPrint('----- this addition entry looks like: $additionEntry');
      final roleEntry = widget.eventContext.program.roles.firstWhere((e) => e['id'] == additionEntry.key);
      final DateTime start = roleEntry['start'];
      final String body =
          "You are assigned to '${roleEntry['title']!}' for ${widget.originalTitle} at ${timeFormat.format(start)}";

      final List<String> tokens = [];
      for (final thisUID in additionEntry.value) {
        if (thisUID != _currentUID) {
          if (!_appContext.haveTokensForUserID(thisUID)) {
            debugPrint('fetching tokens for UID: $thisUID');
            final tokens = await _tokenResolver.resolveForAuthID(_appContext.getAuthIDFromUID(thisUID));
            _appContext.addTokensToUserID(thisUID, tokens);
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

    debugPrint('on the removals: the entries look like:${widget.eventContext.roleRemovalals.entries}');
    for (final removalEntry in widget.eventContext.roleRemovalals.entries) {
      final String roleTitle = widget.eventContext.deletedRoleTitle(removalEntry.key);
      final String body = "You are no longer assigned to '$roleTitle' for ${widget.originalTitle}";

      final List<String> tokens = [];
      for (final thisUID in removalEntry.value) {
        if (thisUID != _currentUID) {
          if (!_appContext.haveTokensForUserID(thisUID)) {
            debugPrint('fetching tokens for UID: $thisUID');
            final tokens = await _tokenResolver.resolveForAuthID(_appContext.getAuthIDFromUID(thisUID));
            _appContext.addTokensToUserID(thisUID, tokens);
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
    final String body = "You can modify aspects of the post: '${widget.originalTitle}'";
    final List<String> allTokens = List<String>.empty(growable: true);

    for (final String thisUID in widget.eventContext.contributorAdditionUIDs) {
      if (thisUID != _currentUID) {
        if (!_appContext.haveTokensForUserID(thisUID)) {
          final tokens = await _tokenResolver.resolveForAuthID(_appContext.getAuthIDFromUID(thisUID));
          _appContext.addTokensToUserID(thisUID, tokens);
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
    final String body = "You have been removed as a contributor for '${widget.originalTitle}'";
    final List<String> allTokens = List<String>.empty(growable: true);

    for (final String thisUID in widget.eventContext.contributorRemovalUIDs) {
      if (thisUID != _currentUID) {
        if (!_appContext.haveTokensForUserID(thisUID)) {
          final tokens = await _tokenResolver.resolveForAuthID(_appContext.getAuthIDFromUID(thisUID));
          _appContext.addTokensToUserID(thisUID, tokens);
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
    for (final String contributorID in widget.eventContext.contributorAdditionUIDs) {
      await userDBManager.addPostToUser(contributorID, postID, 'contributor');
    }

    // then remove the old contributors
    for (final String contributorID in widget.eventContext.contributorRemovalUIDs) {
      await userDBManager.removePostFromUser(contributorID, postID);
    }
  }

  Map<String, String> get _notificationdata => {'PostID': widget.eventContext.id};
}
