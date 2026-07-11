import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/messaging_manager.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/notification_topics.dart';

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
            title: const Text('All Belfast updates'),
            value: _appContext.sharedPref.subscribedToBelfast,
            onChanged: (newState) => _onBelfastUmbrellaClick(newState)),
        SwitchListTile(
            title: const Text('Sunday Worship Service'),
            value: _appContext.sharedPref.isSubscribedToTopic(NotificationTopics.sundayService),
            onChanged: (newState) => _onTopicClick(NotificationTopics.sundayService, newState)),
        SwitchListTile(
            title: const Text('Midweek Service'),
            value: _appContext.sharedPref.isSubscribedToTopic(NotificationTopics.midweekService),
            onChanged: (newState) => _onTopicClick(NotificationTopics.midweekService, newState)),
        SwitchListTile(
            title: const Text('Growth Mentoring'),
            value: _appContext.sharedPref.isSubscribedToTopic(NotificationTopics.growthMentoring),
            onChanged: (newState) => _onTopicClick(NotificationTopics.growthMentoring, newState)),
        SwitchListTile(
            title: const Text('Dawn Watch'),
            value: _appContext.sharedPref.isSubscribedToTopic(NotificationTopics.dawnWatch),
            onChanged: (newState) => _onTopicClick(NotificationTopics.dawnWatch, newState)),
        SwitchListTile(
            title: const Text('Youth Online Caregroup'),
            value: _appContext.sharedPref.isSubscribedToTopic(NotificationTopics.youthCaregroup),
            onChanged: (newState) => _onTopicClick(NotificationTopics.youthCaregroup, newState)),
        SwitchListTile(
            title: const Text('Overnight Prayer'),
            value: _appContext.sharedPref.isSubscribedToTopic(NotificationTopics.overnightPrayer),
            onChanged: (newState) => _onTopicClick(NotificationTopics.overnightPrayer, newState)),
        const Divider()
      ],
    );
  }

  // * Logic

  void _onBelfastUmbrellaClick(final bool newState) {
    _onTopicClick(NotificationTopics.belfastUmbrella, newState, updateBelfastPref: true);
  }

  void _onTopicClick(final String topic, final bool newState, {bool updateBelfastPref = false}) {
    final authId = kIsWeb ? AuthManager().currentAuthUID : null;
    setState(() {
      if (newState) {
        debugPrint('subscribing to: $topic');
        _messagingManager.subscribeToTopic(topic, authId: authId);
        if (updateBelfastPref) {
          _appContext.sharedPref.setSubscribedToBelfast(true);
        } else {
          _appContext.sharedPref.setSubscribedToTopic(topic, true);
        }
        _appContext.analytics.logEvent(name: 'Notification subscribe to: $topic');
      } else {
        debugPrint('unsubscribing to: $topic');
        _messagingManager.unsubscribeFromTopic(topic, authId: authId);
        if (updateBelfastPref) {
          _appContext.sharedPref.setSubscribedToBelfast(false);
        } else {
          _appContext.sharedPref.setSubscribedToTopic(topic, false);
        }
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
