import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../firebase/db_managers/event_db_manager.dart';
import '../firebase/db_managers/user_db_manager.dart';
import '../firebase/messaging_manager.dart';
import '../models/event/event_head.dart';
import '../utility/app_context.dart';
import '../utility/event_context.dart';
import '../utility/local_data_manager.dart';
import '../widgets/info/timed_button_dialog.dart';
import 'events/select_post_template_page.dart';
import 'events/view_event_page.dart';
import 'events_home.dart';
import 'information/simple_info_page.dart';
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
  final ScrollController _postsScrollController = ScrollController(), _informationScrollController = ScrollController();

  // bool _bottomBarIsVisible = true;

  @override
  void initState() {
    // * initial setup of data
    _appContext = Provider.of<AppContext>(context, listen: false);
    _informationTabController = TabController(length: 4, vsync: this);
    _appContext.sharedPref.setPostRefreshTime();
    _appContext.allUsers.sort(((a, b) {
      final surname = a.surname.compareTo(b.surname);
      if (surname == 0) {
        return a.forname.compareTo(b.forname);
      }
      return surname;
    }));
    _setupCloudOnMessage();

    // * special case where it's the first time opening the app
    if (!kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkIfFirstOpen();
      });
    }

    // * periodic and non-periodic local maintenance
    if (_appContext.sharedPref.shouldFetchUserImages && !kIsWeb) {
      _performLocalUserImgCleanup();
      _removeLocallySavedPosts();
      _appContext.sharedPref.justFetchedUserImages();
    }

    // TODO new feature for notifications (temporary until future updates)
    _setNotificationTopicsTemp();

    super.initState();
  }

  @override
  void dispose() {
    _informationTabController.dispose();
    _postsScrollController.dispose();
    _informationScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (context, appContext, child) {
      return PopScope(
        canPop: false, // safety for the first session
        child: Scaffold(
          body: _buildSelectedBody(appContext),
          floatingActionButton: _buildFAB(),
          bottomNavigationBar: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              currentIndex: _selectedIndex,
              onTap: (index) => _onNavigationItemTap(index),
              unselectedFontSize: 0,
              selectedFontSize: 0,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Posts'),
                BottomNavigationBarItem(icon: Icon(Icons.church), label: 'CTRIM'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Personal')
              ]),
          // ? Check the bottom out for another time
          // bottomNavigationBar: SafeArea(
          //   child: AnimatedContainer(
          //     duration: const Duration(milliseconds: 300),
          //     height: _bottomBarIsVisible ? kBottomNavigationBarHeight : 0,
          //     child: Visibility(
          //       visible: _bottomBarIsVisible,
          //       child: BottomNavigationBar(
          //           backgroundColor: Colors.transparent,
          //           elevation: 0,
          //           currentIndex: _selectedIndex,
          //           onTap: (index) => _onNavigationItemTap(index),
          //           unselectedFontSize: 0,
          //           selectedFontSize: 0,
          //           items: const <BottomNavigationBarItem>[
          //             BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Posts'),
          //             BottomNavigationBarItem(icon: Icon(Icons.church), label: 'CTRIM'),
          //             BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Personal')
          //           ]),
          //     ),
          //   ),
          // ),
        ),
      );
    });
  }

  Widget _buildSelectedBody(AppContext appContext) {
    if (_selectedIndex == 0) {
      return ViewEventsHome(
          scrollController: _postsScrollController,
          rebuildFunction: () {
            setState(() {
              // there's a potential that new posts have been added
              _appContext.sortPostsByIndex();
            });
          });
    } else if (_selectedIndex == 1) {
      return InformationHome(
        tabController: _informationTabController,
        scrollController: _informationScrollController,
      );
    }
    return PersonalHome(appContext: appContext);
  }

  Widget? _buildFAB() {
    if (_selectedIndex == 0 && _appContext.currentUser.isLeader) {
      return FloatingActionButton.extended(
          icon: const Icon(Icons.post_add),
          onPressed: () {
            final String uid = _appContext.currentUser.id;
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SelectPostTemplatePage(eventContext: EventContext.adding(currentUserID: uid))))
                .then((_) {
              setState(() {});
            });
          },
          label: const Text('Add Post'));
    }
    return null;
  }

  // * Logic

  void _onNavigationItemTap(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      // scroll page to top
      if (index == 0) {
        _postsScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      } else if (index == 1) {
        _informationScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      }
    }
  }

  // * Commenting out just in case I need it again in the future
  // Future<void> _saveFCMToken() async {
  //   final MessagingManager messagingManager = MessagingManager();
  //   final token = await messagingManager.getToken();
  //   if (token != null) {
  //     debugPrint('token to save is $token');
  //     final String platform = kIsWeb ? 'Web' : Platform.operatingSystem;
  //     _appContext.sharedPref.saveFCMToken(token);
  //     final EveryoneDBManager everyoneDBManager = EveryoneDBManager();
  //     final AuthManager authManager = AuthManager();
  //     everyoneDBManager.addTokenForAuthID(authID: authManager.currentAuthUID, token: token, platform: platform);
  //   }
  // }

  void _checkIfFirstOpen() async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    if (appContext.sharedPref.isFirstOpen && !kIsWeb) {
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

      final String? token = await messagingManager.requestPermissionAndToken().then((token) {
        showDialog(context: context, builder: (_) => const TimedButtonDialog());
        return token;
      });

      // we don't need to perfrom the token grabbing here anymore - done in welcome page
      if (token != null) {
        debugPrint('Token to save is $token');
        appContext.sharedPref.saveFCMToken(token);
      }

      // TODO remove this in the future
      messagingManager.subscribeToCTRIMBelfast();
      _appContext.sharedPref.setSubscribedToBelfast(true);
      _setNotificationTopicsTemp();
      appContext.sharedPref.nowOpened();
    }
  }

  // not really something that can be tested at the moment. Requires a good amount of posts made
  // we want to see that post junk is removed when they are no longer being fetched
  // we should really be clearing up images from the cache directory as well!
  Future<void> _removeLocallySavedPosts() async {
    final LocalDataManager localDataManager = LocalDataManager();
    final List<String> postUIDs = await localDataManager.readPostTrack();
    final List<String> toDelete = List<String>.empty(growable: true);

    localDataManager.cleanupCache(_appContext.cacheDir!);

    for (final String postUID in postUIDs) {
      if (!_appContext.eventHeads.any((e) => e.id.compareTo(postUID) == 0)) {
        debugPrint('deleting post id: $postUID');
        toDelete.add(postUID);
        localDataManager.deletePostData(postUID);
      }
    }

    if (toDelete.isNotEmpty) {
      postUIDs.removeWhere((e) => toDelete.contains(e));
      localDataManager.writePostTrack(postUIDs);
    }
  }

  // * Notification related

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

  Future<void> _handleInitialMessage(final RemoteMessage message) async {
    if (!_appContext.sharedPref.loggedOut && message.data.containsKey('PostID')) {
      final String postID = message.data['PostID'];
      final bool hasHead = _appContext.eventHeads.any((element) => element.id.compareTo(postID) == 0);

      if (!hasHead) {
        //  fetch and add the head
        final EventHeadDBManager eventHeadDBManager = EventHeadDBManager();
        final head = await eventHeadDBManager.fetchHead(postID);
        _appContext.addNewPostHead(head);
      }
      final thisHead = _appContext.eventHeads.firstWhere((element) => element.id.compareTo(postID) == 0);
      _openPost(thisHead);
    } else if (message.data.containsKey('InfoPage')) {
      _openInformationTeachingPage(message.data['InfoPage']);
    }
    // _showFCMMessage(message);
  }

  Future<void> _handleOnMessage(final RemoteMessage message) async {
    // ! this one makes sense to have an opening dialog
    final bool openPage = _appContext.sharedPref.loggedOut ? false : await _showFCMMessage(message, true);

    if (message.data.containsKey('PostID')) {
      final String postID = message.data['PostID'];
      final head = await _reloadEventHead(postID);
      if (openPage) {
        _openPost(head);
      }
      _updateUserRoles();
    } else if (message.data.containsKey('InfoPage') && openPage) {
      _openInformationTeachingPage(message.data['InfoPage']);
    }
  }

  Future<void> _handleOnMessageOpenedBackground(final RemoteMessage message) async {
    // ! no need for a dialog, just open the page no matter where the user may be
    final bool hasLoggedOut = _appContext.sharedPref.loggedOut;
    if (message.data.containsKey('PostID')) {
      final String postID = message.data['PostID'];
      final head = await _reloadEventHead(postID);
      if (!hasLoggedOut) {
        _updateUserRoles();
        _openPost(head);
      }
    } else if (!hasLoggedOut && message.data.containsKey('InfoPage')) {
      _openInformationTeachingPage(message.data['InfoPage']);
    }
  }

  Future<EventHead> _reloadEventHead(final String postID) async {
    final EventHeadDBManager eventHeadDBManager = EventHeadDBManager();
    final head = await eventHeadDBManager.fetchHead(postID);
    _appContext.addOrUpdatePostHead(head);
    return head;
  }

  void _openPost(final EventHead thisHead) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ViewEventPage(eventHead: thisHead)));
  }

  void _openInformationTeachingPage(final String jsonPath) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SimpleInfoPage(jsonPath: jsonPath)));
  }

  // all notifications potentially will be asking to open a page
  // well... maybe not, let's make it an optional thing
  Future<bool> _showFCMMessage(final RemoteMessage message, bool openingPage) async {
    final RemoteNotification notification = message.notification!;
    final String? closeText = message.data['CloseText'];
    final String? superImageUrl = message.data['SuperImageUrl'];
    final String? imageUrl =
        superImageUrl ?? (Platform.isAndroid ? notification.android!.imageUrl : notification.apple!.imageUrl);

    bool result = false;

    final List<Widget> buttonChildren = [
      TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(closeText ?? 'Ok', style: const TextStyle(fontSize: 16)))
    ];
    if (openingPage) {
      buttonChildren.add(TextButton(
          onPressed: () {
            result = true;
            Navigator.of(context).pop();
          },
          child: const Text('Show More', style: TextStyle(fontSize: 16))));
    }

    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          // ! wrap this in an orientation builder!
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
                imageUrl != null ? const SizedBox(height: 16) : const SizedBox(height: 24),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child:
                        Text(notification.title!, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
                const SizedBox(height: 8),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(notification.body!, style: const TextStyle(fontSize: 16))),
                const SizedBox(height: 8),
                Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: buttonChildren)),
                const SizedBox(height: 16)
              ])));
        });

    return result;
  }

  // in the case that the notification is on a Post Update - receiving word of a role
  Future<void> _updateUserRoles() async {
    final UserDBManager userDBManager = UserDBManager();
    _appContext.currentUser.setRoles(await userDBManager.fetchUserRoles(_appContext.currentUser.id));
  }

  // * maintenance work

  void _performLocalUserImgCleanup() async {
    final String userImgDir = '${_appContext.appDir}/user_imgs';
    final dir = Directory(userImgDir);
    if (!await dir.exists()) {
      debugPrint('creating user_img directory!');
      await dir.create();
    }

    for (final user in _appContext.allUsers) {
      final File potentialUserImg = File('$userImgDir/${user.id}.png');
      if (user.imgSrc.isNotEmpty) {
        debugPrint('Creating user profile pic for ${user.forname} ID ${user.id}');
        _setImageForFile(potentialUserImg, user.imgSrc);
      } else if (user.imgSrc.isEmpty && await potentialUserImg.exists()) {
        debugPrint('Deleting user profile pic for ${user.forname} ID ${user.id}');
        potentialUserImg.delete();
      } else {
        debugPrint('doing nothing, no need to create/delete profile pics');
      }
    }
  }

  Future<void> _setImageForFile(final File file, final String src) async {
    final response = await http.get(Uri.parse(src));
    file.writeAsBytes(response.bodyBytes);
  }

  void _setNotificationTopicsTemp() {
    // we have to check if users are subscribed to the old notification topic (belfast)
    // if so, then subscribe to all the new ones and set old one to false
    // otherwise, we do not set it to true
    if (_appContext.sharedPref.subscribedToBelfast) {
      // unsubscribe to this and subscribe to everything temporarly available
      debugPrint('unsubscribing to old Belfast topic and subscribing to everything else');
      final MessagingManager messagingManager = MessagingManager();
      messagingManager.unsubscribeFromCTRIMBelfast();
      _appContext.sharedPref.setSubscribedToBelfast(false);

      _appContext.sharedPref.setSubscribedToTopic('belfast-sunday-service', true);
      _appContext.sharedPref.setSubscribedToTopic('belfast-midweek-service', true);
      _appContext.sharedPref.setSubscribedToTopic('belfast-growth-mentoring', true);
      _appContext.sharedPref.setSubscribedToTopic('belfast-dawn-watch', true);
      _appContext.sharedPref.setSubscribedToTopic('belfast-overnight-prayer', true);
      _appContext.sharedPref.setSubscribedToTopic('belfast-youth-cg', true);

      messagingManager.subscribeToTopic('belfast-sunday-service');
      messagingManager.subscribeToTopic('belfast-midweek-service');
      messagingManager.subscribeToTopic('belfast-growth-mentoring');
      messagingManager.subscribeToTopic('belfast-dawn-watch');
      messagingManager.subscribeToTopic('belfast-overnight-prayer');
      messagingManager.subscribeToTopic('belfast-youth-cg');
      messagingManager.subscribeToTopic('Belfast'); // hardcode to Belfast for now
    }
  }
}
