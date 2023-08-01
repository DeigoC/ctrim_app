import 'dart:io';

import 'package:ctrim_app/firebase/db_managers/event_db_manager.dart';
import 'package:ctrim_app/firebase/messaging_manager.dart';
import 'package:ctrim_app/models/event/event_head.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utility/app_context.dart';
import '../utility/event_context.dart';
import '../widgets/personal_drawer.dart';
import 'events/add_event_page.dart';
import 'events/view_event_page.dart';
import 'events_home.dart';
import 'information_home.dart';
import 'personal_home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final TabController _informationTabController;
  int _selectedIndex = 0;

  late final AppContext _appContext;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    analytics.logAppOpen();

    _informationTabController = TabController(length: 3, vsync: this);
    if (!kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkIfFirstOpen();
      });
    }

    _setupCloudOnMessage();
    super.initState();
  }

  @override
  void dispose() {
    _informationTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (context, appContext, child) {
      return Scaffold(
          body: _buildSelectedBody(appContext),
          drawer: _buildDrawer(appContext),
          floatingActionButton: _buildFAB(),
          bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => _onNavigationItemTap(index),
              unselectedFontSize: 0,
              selectedFontSize: 0,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark), label: 'Posts'),
                BottomNavigationBarItem(icon: Icon(Icons.church), label: 'CTRIM'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Personal')
              ]));
    });
  }

  Widget _buildSelectedBody(AppContext appContext) {
    if (_selectedIndex == 0) {
      return ViewEventsHome(rebuildFunction: () {
        setState(() {});
      });
    } else if (_selectedIndex == 1) {
      return InformationHome(
        tabController: _informationTabController,
      );
    }
    return PersonalHome(
      appContext: appContext,
    );
  }

  Widget? _buildFAB() {
    if (_selectedIndex == 0 && _appContext.currentUser.isLeader) {
      return FloatingActionButton.extended(
          onPressed: () {
            final String uid = _appContext.currentUser.id;
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => AddEventPage(eventContext: EventContext.adding(uid: uid)))).then((_) {
              setState(() {});
            });
          },
          label: const Text('Add Post'));
    }
    return null;
  }

  Widget? _buildDrawer(AppContext appContext) {
    if (_selectedIndex == 2 && !appContext.isCurrentUserGuest) {
      return const PersonalDrawer();
    }
    return null;
  }

  // * Logic

  void _onNavigationItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _checkIfFirstOpen() async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    if (appContext.dataManager.isFirstOpen) {
      final MessagingManager messagingManager = MessagingManager();
      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
              child: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text('Welcome! 👋',
                                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.start)),
                        const SizedBox(height: 16),
                        const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text('Please allow notifications to keep up with the latest from CTRIM!',
                                textAlign: TextAlign.start, style: TextStyle(fontSize: 16))),
                        const SizedBox(height: 8),
                        Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: TextButton(
                                    onPressed: () => Navigator.pop(_),
                                    child: const Text('Ok', style: TextStyle(fontSize: 16)))))
                      ])))));

      final token = await messagingManager.requestPermissionAndToken();
      if (token != null) {
        debugPrint('Token to save is $token');
        appContext.dataManager.saveToken(token);
      }
      messagingManager.subscribeToCTRIMBelfast();
      appContext.dataManager.nowOpened();
    }
  }

  void _setupCloudOnMessage() {
    // when the app is opened
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('-----------------Hello from on message! Here is the message: ${message.data}');
      _handleOnMessage(message).then((_) {
        _appContext.rebuildPlease();
      });
    });

    // when the app is opened in the background of device
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('-----------------Hello from on message opened app! Here is the message: ${message.data}');
      _handleOnMessageOpenedBackground(message).then((_) {
        _appContext.rebuildPlease();
      });
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((message) => message != null ? () => _handleInitialMessage(message) : null);
  }

  void _handleInitialMessage(final RemoteMessage message) {
    if (message.data.containsKey('PostID')) {
      // open Post Page?
    }
    _showFCMMessage(message);
  }

  Future<void> _handleOnMessage(final RemoteMessage message) async {
    if (message.data.containsKey('PostID')) {
      final String postID = message.data['PostID'];
      await _reloadEventHead(postID);
    }
    _showFCMMessage(message);
  }

  Future<void> _handleOnMessageOpenedBackground(final RemoteMessage message) async {
    if (message.data.containsKey('PostID')) {
      final String postID = message.data['PostID'];
      final head = await _reloadEventHead(postID);
      _openPost(head);
    }
    _showFCMMessage(message);
  }

  Future<EventHead> _reloadEventHead(final String postID) async {
    final EventHeadDBManager eventHeadDBManager = EventHeadDBManager();
    final head = await eventHeadDBManager.fetchHead(postID);
    _appContext.addOrUpdatePostHead(head);
    return head;
  }

  void _openPost(final EventHead thisHead) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ViewEventPage(
                  eventHead: thisHead,
                  viewingChild: false,
                )));
  }

  Future<void> _showFCMMessage(final RemoteMessage message) async {
    final RemoteNotification notification = message.notification!;
    final String? closeText = message.data['CloseText'];
    final String? superImageUrl = message.data['SuperImageUrl'];
    final String? imageUrl =
        superImageUrl ?? (Platform.isAndroid ? notification.android!.imageUrl : notification.apple!.imageUrl);

    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          // TODO wrap this in an orientation builder!
          return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                  child:
                      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                imageUrl != null
                    ? Container(
                        foregroundDecoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                            image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.fill)),
                        child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.network(imageUrl) // so jank lol! It works though
                            ))
                    : Container(),
                const SizedBox(height: 24),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child:
                        Text(notification.title!, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(notification.body!, style: const TextStyle(fontSize: 16))),
                const SizedBox(height: 8),
                Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                        padding: const EdgeInsets.only(right: 24.0),
                        child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(closeText ?? 'Ok', style: const TextStyle(fontSize: 16))))),
                const SizedBox(height: 16)
              ])));
        });
  }
}
