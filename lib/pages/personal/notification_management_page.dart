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
        const Divider(),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Belfast', style: TextStyle(fontSize: 24))),
        SwitchListTile(
            title: const Text('Sunday Worship Service'),
            value: _appContext.sharedPref.isSubscribedToTopic('belfast-sunday-service'),
            onChanged: (newState) => _onTopicClick('belfast-sunday-service', newState)),
        SwitchListTile(
            title: const Text('Midweek Service'),
            value: _appContext.sharedPref.isSubscribedToTopic('belfast-midweek-service'),
            onChanged: (newState) => _onTopicClick('belfast-midweek-service', newState)),
        SwitchListTile(
            title: const Text('Growth Mentoring'),
            value: _appContext.sharedPref.isSubscribedToTopic('belfast-growth-mentoring'),
            onChanged: (newState) => _onTopicClick('belfast-growth-mentoring', newState)),
        SwitchListTile(
            title: const Text('Youth Online Caregroup'),
            value: _appContext.sharedPref.isSubscribedToTopic('belfast-youth-cg'),
            onChanged: (newState) => _onTopicClick('belfast-youth-cg', newState)),
        SwitchListTile(
            title: const Text('Overnight Prayer'),
            value: _appContext.sharedPref.isSubscribedToTopic('belfast-overnight-prayer'),
            onChanged: (newState) => _onTopicClick('belfast-overnight-prayer', newState)),
        const Divider()
      ],
    );
  }

  // * Logic

  void _onTopicClick(final String topic, final bool newState) {
    // update the messaaging manager accordingly, do the same with local storage, update the analytics
    setState(() {
      if (newState) {
        debugPrint('subscribing to: $topic');
        _messagingManager.subscribeToTopic(topic);
        _appContext.sharedPref.setSubscribedToTopic(topic, newState);
        _appContext.analytics.logEvent(name: 'Notification subscribe to: $topic');
      } else {
        debugPrint('unsubscribing to: $topic');
        _messagingManager.unsubscribeFromTopic(topic);
        _appContext.sharedPref.setSubscribedToTopic(topic, newState);
        _appContext.analytics.logEvent(name: 'Notification unsubscribe to: $topic');
      }
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
