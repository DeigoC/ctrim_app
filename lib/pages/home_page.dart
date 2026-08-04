import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import '../firebase/auth_manager.dart';
import '../firebase/db_managers/event_db_manager.dart';
import '../firebase/db_managers/user_db_manager.dart';
import '../models/event/event_head.dart';
import '../utility/app_context.dart';
import '../utility/event_context.dart';
import '../utility/local_data_manager.dart';
import '../utility/network_image_helper.dart';
import '../utility/responsive_layout.dart';
import '../utility/web_notification_lifecycle.dart';
import '../utility/notification_subscription_service.dart';
import '../utility/web_notification_deep_link.dart';
import 'events/post_templates/select_post_template_page.dart';
import 'events/view_event_page.dart';
import 'events_home.dart';
import 'information/ctrim_info_page.dart';
import 'information_home.dart';
import 'personal_home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _NavDestination {
  const _NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  static const List<_NavDestination> _destinations = [
    _NavDestination(icon: Icons.library_books, label: 'Bulletin'),
    _NavDestination(icon: Icons.church, label: 'CTRIM'),
    _NavDestination(icon: Icons.person, label: 'Personal'),
  ];

  late final TabController _informationTabController;
  late int _selectedIndex;

  late final AppContext _appContext;
  final ScrollController _postsScrollController = ScrollController(),
      _informationScrollController = ScrollController();

  @override
  void initState() {
    // * initial setup of data
    _appContext = Provider.of<AppContext>(context, listen: false);

    // Set startup tab based on user preference (default to 1 = Information home)
    _selectedIndex = _appContext.sharedPref.preferredStartupTab;

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
    _setupWebNotificationListeners();

    // Show first-open welcome dialog before any web token registration.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfFirstOpen();
    });

    // * periodic and non-periodic local maintenance
    if (_appContext.sharedPref.canRefreshUserImages) {
      _performUserImageCache();
      _removeLocallySavedPosts();
      _appContext.sharedPref.setUserImageRefreshTime();
    }

    super.initState();
  }

  void _setupWebNotificationListeners() {
    if (!kIsWeb || _appContext.isCurrentUserGuest) return;

    final authID = AuthManager().currentAuthUID;
    if (authID.isEmpty) return;

    WebNotificationLifecycle().listenForTokenRefresh(
      authId: authID,
      onTokenSaved: _appContext.sharedPref.saveFCMToken,
      prefs: _appContext.sharedPref,
      webAuthId: authID,
    );
  }

  void _registerWebNotificationsIfNeeded() {
    if (!kIsWeb || _appContext.isCurrentUserGuest) return;

    final authID = AuthManager().currentAuthUID;
    if (authID.isEmpty) return;

    // Await register (it reconciles topics once a token exists).
    WebNotificationLifecycle()
        .register(
      authId: authID,
      onTokenSaved: _appContext.sharedPref.saveFCMToken,
      prefs: _appContext.sharedPref,
      webAuthId: authID,
    )
        .then((_) {
      // Native + any edge case where register skipped reconcile.
      return _reconcileNotificationSubscriptions();
    });
  }

  Future<void> _reconcileNotificationSubscriptions() async {
    if (_appContext.isCurrentUserGuest || _appContext.sharedPref.loggedOut) return;

    final authID = kIsWeb ? AuthManager().currentAuthUID : null;
    if (kIsWeb && (authID == null || authID.isEmpty)) return;

    await NotificationSubscriptionService().reconcile(
      prefs: _appContext.sharedPref,
      webAuthId: authID,
    );
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useRail = ResponsiveLayout.isWideScreen(constraints.maxWidth);
            return Scaffold(
              body: useRail
                  ? _buildWideBody(appContext)
                  : _buildSelectedBody(appContext),
              floatingActionButton: _buildFAB(),
              bottomNavigationBar: useRail ? null : _buildBottomNavigationBar(),
            );
          },
        ),
      );
    });
  }

  Widget _buildWideBody(final AppContext appContext) {
    return Row(
      children: [
        _buildNavigationRail(),
        const VerticalDivider(width: 1),
        Expanded(child: _buildSelectedBody(appContext)),
      ],
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      extended: MediaQuery.sizeOf(context).width >= ResponsiveLayout.desktop,
      onDestinationSelected: _onNavigationItemTap,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/ctrim_logo.png',
            width: 48,
            height: 48,
            errorBuilder: (_, __, ___) => Icon(Icons.church,
                size: 48, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      destinations: _destinations
          .map(
            (dest) => NavigationRailDestination(
              icon: Icon(dest.icon),
              label: Text(dest.label),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      currentIndex: _selectedIndex,
      onTap: _onNavigationItemTap,
      unselectedFontSize: 8,
      selectedFontSize: 12,
      items: _destinations
          .map(
            (dest) => BottomNavigationBarItem(
              icon: Icon(dest.icon),
              label: dest.label,
            ),
          )
          .toList(),
    );
  }

  Widget _buildSelectedBody(final AppContext appContext) {
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
    if (_selectedIndex == 0 && _appContext.currentUser.canManagePostTemplates) {
      return FloatingActionButton.extended(
          icon: const Icon(Icons.post_add),
          onPressed: () {
            final String uid = _appContext.currentUser.id;
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SelectPostTemplatePage(
                            eventContext:
                                EventContext.adding(currentUserID: uid))))
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
        _postsScrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      } else if (index == 1) {
        _informationScrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
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
    if (appContext.sharedPref.isFirstOpen) {
      // Show welcome dialog without notification pressure
      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
              child: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.0),
                                child: Text('Welcome! 👋',
                                    style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.start)),
                            const SizedBox(height: 16),
                            const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.0),
                                child: Text(
                                    'Thanks for visiting the CTRIM app! Stay connected with the latest updates, events, and announcements from CTRIM Belfast.',
                                    textAlign: TextAlign.start,
                                    style: TextStyle(fontSize: 16))),
                            const SizedBox(height: 8),
                            Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Get Started',
                                            style: TextStyle(fontSize: 16)))))
                          ])))));

      appContext.sharedPref.nowOpened();
    }

    _registerWebNotificationsIfNeeded();
    if (!kIsWeb) {
      _reconcileNotificationSubscriptions();
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
    if (kIsWeb) {
      _setupWebNotificationClickListener();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleWebLaunchDeepLink();
      });
    }

    // when the app is opened (foreground messages)
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
          '-----------------Hello from on message! Here is the message: ${message.data}');
      _handleOnMessage(message).then((_) {
        _appContext.rebuildPlease();
      });
    });

    // when the app is opened in the background of device
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
          '-----------------Hello from on message opened app! Here is the message: ${message.data}');
      _handleOnMessageOpenedBackground(message).then((_) {
        _appContext.rebuildPlease();
      });
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleInitialMessage(message);
      }
    });
  }

  /// Web: open post/info when the service worker focuses an existing tab.
  void _setupWebNotificationClickListener() {
    if (!kIsWeb) return;

    html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is! Map) return;
      if (data['type'] != 'NOTIFICATION_CLICKED') return;

      final payload = data['data'];
      if (payload is! Map) return;

      final mapped = <String, dynamic>{
        for (final entry in payload.entries) entry.key.toString(): entry.value,
      };
      _openFromNotificationData(mapped);
    });
  }

  void _handleWebLaunchDeepLink() {
    final params = WebNotificationDeepLink.consumeLaunchParams();
    if (params.isEmpty) return;
    _openFromNotificationData(params);
  }

  Future<void> _openFromNotificationData(Map<String, dynamic> data) async {
    if (_appContext.sharedPref.loggedOut) return;

    if (data.containsKey('PostID')) {
      final postID = data['PostID']?.toString() ?? '';
      if (postID.isEmpty) return;
      final head = await _reloadEventHead(postID);
      if (!mounted) return;
      _openPost(head);
      _updateUserRoles();
    } else if (data.containsKey('InfoPage')) {
      final infoPage = data['InfoPage']?.toString() ?? '';
      if (infoPage.isEmpty) return;
      if (!mounted) return;
      _openInformationTeachingPage(infoPage);
    }
  }

  Future<void> _handleInitialMessage(final RemoteMessage message) async {
    await _openFromNotificationData(message.data);
  }

  Future<void> _handleOnMessage(final RemoteMessage message) async {
    // ! this one makes sense to have an opening dialog
    final bool openPage = _appContext.sharedPref.loggedOut
        ? false
        : await _showFCMMessage(message, true);

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

  Future<void> _handleOnMessageOpenedBackground(
      final RemoteMessage message) async {
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
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ViewEventPage(eventHead: thisHead)));
  }

  void _openInformationTeachingPage(final String jsonPath) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            CTRIMInfoPage(documentId: _resolveInfoDocumentId(jsonPath))));
  }

  String _resolveInfoDocumentId(final String rawValue) {
    switch (rawValue) {
      case 'assets/info/ctrim_info/core_values.json':
        return 'core_values';
      case 'assets/info/ctrim_info/4xd.json':
        return '4xd';
      case 'assets/info/ctrim_info/cell_group.json':
        return 'cell_group';
      case 'assets/info/ctrim_info/devotionals.json':
        return 'devotionals';
      default:
        return rawValue;
    }
  }

  // all notifications potentially will be asking to open a page
  // well... maybe not, let's make it an optional thing
  Future<bool> _showFCMMessage(
      final RemoteMessage message, bool openingPage) async {
    final RemoteNotification notification = message.notification!;
    final String? closeText = message.data['CloseText'];
    final String? superImageUrl = message.data['SuperImageUrl'];

    // Handle image URL for different platforms
    String? imageUrl;
    if (kIsWeb) {
      // On web, notification images are in notification.web or data
      imageUrl = superImageUrl ?? notification.web?.image;
    } else {
      // On native platforms, get platform-specific image
      imageUrl = superImageUrl ??
          (Platform.isAndroid
              ? notification.android?.imageUrl
              : notification.apple?.imageUrl);
    }

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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    imageUrl != null
                        ? Container(
                            foregroundDecoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16)),
                                image: DecorationImage(
                                    image: NetworkImage(
                                        NetworkImageHelper.getImageUrl(
                                            imageUrl)),
                                    fit: BoxFit.fill)),
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.network(
                                    NetworkImageHelper.getImageUrl(
                                        imageUrl)) // so jank lol! It works though
                                ))
                        : Container(),
                    imageUrl != null
                        ? const SizedBox(height: 16)
                        : const SizedBox(height: 24),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(notification.title!,
                            style: const TextStyle(
                                fontSize: 21, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(notification.body!,
                            style: const TextStyle(fontSize: 16))),
                    const SizedBox(height: 8),
                    Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: buttonChildren)),
                    const SizedBox(height: 16)
                  ])));
        });

    return result;
  }

  // in the case that the notification is on a Post Update - receiving word of a role
  Future<void> _updateUserRoles() async {
    final UserDBManager userDBManager = UserDBManager();
    _appContext.currentUser.setRoles(
        await userDBManager.fetchUserRoles(_appContext.currentUser.id));
  }

  // * maintenance work

  /// Cache user profile images using Hive (works on all platforms including web)
  Future<void> _performUserImageCache() async {
    final LocalDataManager localDataManager = LocalDataManager();

    for (final user in _appContext.allUsers) {
      final bool hasImage = await localDataManager.hasUserImage(user.id);

      if (user.imgSrc.isNotEmpty && !hasImage) {
        // User has image URL but not cached - download and cache it
        debugPrint(
            'Caching user profile pic for ${user.forname} ID ${user.id}');
        try {
          final String imageUrl = NetworkImageHelper.getImageUrl(user.imgSrc);
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            await localDataManager.writeUserImage(user.id, response.bodyBytes);
          }
        } catch (e) {
          debugPrint('Error caching image for ${user.forname}: $e');
        }
      } else if (user.imgSrc.isEmpty && hasImage) {
        // User removed image but it's still cached - delete it
        debugPrint(
            'Deleting cached profile pic for ${user.forname} ID ${user.id}');
        await localDataManager.deleteUserImage(user.id);
      }
    }
  }
}
