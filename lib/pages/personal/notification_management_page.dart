import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/messaging_manager.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';

class NotificationManagementPage extends StatefulWidget {
  const NotificationManagementPage({super.key});

  @override
  State<NotificationManagementPage> createState() => _NotificationManagementPageState();
}

class _NotificationManagementPageState extends State<NotificationManagementPage> {
  late final AppContext _appContext;
  final MessagingManager _messagingManager = MessagingManager();

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _buildBody(),
        appBar: AppBar(
          title: const Text('Push Notifications'),
          actions: [IconButton(onPressed: _helpClick, icon: const Icon(Icons.help))],
        ));
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        SwitchListTile(
            secondary: const Icon(Icons.church),
            title: const Text('New Belfast Posts'),
            value: _appContext.sharedPref.subscribedToBelfast,
            onChanged: _onSubscribedToBelfastClick)
      ],
    );
  }

  // * Logic
  void _onSubscribedToBelfastClick(final bool newState) {
    if (!newState) {
      DialogManager.showAlertDialog(
          context: context,
          title: 'Unsubscribing to Belfast',
          content: 'You will no longer receive notifications of new posts from Belfast');
      _messagingManager.unsubscribeFromCTRIMBelfast();
      _appContext.analytics.logEvent(name: 'Notification: Unsubscribe from Belfast');
    } else {
      _messagingManager.subscribeToCTRIMBelfast();
      _appContext.analytics.logEvent(name: 'Notification: Subscribe from Belfast');
    }

    setState(() {
      _appContext.sharedPref.setSubscribedToBelfast(newState);
    });
  }

  void _helpClick() {
    DialogManager.showAlertDialog(
        context: context,
        title: 'Notifications',
        content:
            'Please bear in mind that you can still receive push notifications on posts that you bookmarked, are tagged to, or assigned for a task');
  }
}
