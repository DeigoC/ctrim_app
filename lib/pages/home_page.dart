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
import '../utility/cache/local_data_manager.dart';
import '../utility/network_image_helper.dart';
import '../utility/responsive_layout.dart';
import '../utility/user_schedule_service.dart';
import '../utility/notifications/web_notification_lifecycle.dart';
import '../utility/notifications/notification_subscription_service.dart';
import '../utility/notifications/web_notification_deep_link.dart';
import '../src/localization/app_localizations.dart';
import '../widgets/common/app_dialog.dart';
import 'events/post_templates/select_post_template_page.dart';
import 'events/view_event_page.dart';
import 'events/events_home.dart';
import 'cell_groups/cell_groups_home.dart';
import 'information/ctrim_info_page.dart';
import 'information/information_home.dart';
import 'personal/personal_home.dart';

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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  static const List<_NavDestination> _destinations = [
    _NavDestination(icon: Icons.library_books, label: 'Bulletin'),
    _NavDestination(icon: Icons.church, label: 'CTRIM'),
    _NavDestination(icon: Icons.groups, label: 'Cell Groups'),
    _NavDestination(icon: Icons.person, label: 'Personal'),
  ];

  static const String _personalLabel = 'Personal';

  late final TabController _informationTabController;
  late final TabController _cellGroupsTabController;
  late int _selectedIndex;

  late final AppContext _appContext;
  final ScrollController _postsScrollController = ScrollController(),
      _informationScrollController = ScrollController(),
      _cellGroupsScrollController = ScrollController();

  @override
  void initState() {
    // * initial setup of data
    _appContext = Provider.of<AppContext>(context, listen: false);

    // Set startup tab based on user preference (default to 1 = Information home)
    _selectedIndex = _appContext.sharedPref.preferredStartupTab;

    _informationTabController = TabController(length: 4, vsync: this);
    _cellGroupsTabController = TabController(length: 2, vsync: this);
    _appContext.sharedPref.setPostRefreshTime();
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
    if (_appContext.isCurrentUserGuest || _appContext.sharedPref.loggedOut)
      return;

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
    _cellGroupsTabController.dispose();
    _postsScrollController.dispose();
    _informationScrollController.dispose();
    _cellGroupsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // safety for the first session
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useRail = ResponsiveLayout.isWideScreen(constraints.maxWidth);
          return Scaffold(
            body: useRail ? _buildWideBody() : _buildSelectedBody(),
            floatingActionButton:
                _selectedIndex == 0 ? const _AddPostFab() : null,
            bottomNavigationBar: useRail ? null : _buildBottomNavigationBar(),
          );
        },
      ),
    );
  }

  Widget _buildWideBody() {
    return Row(
      children: [
        _buildNavigationRail(),
        const VerticalDivider(width: 1),
        Expanded(child: _buildSelectedBody()),
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
              icon: dest.label == _personalLabel
                  ? _PersonalNavIcon(icon: dest.icon)
                  : Icon(dest.icon),
              label: Text(dest.label),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final colorScheme = Theme.of(context).colorScheme;
    // 4+ items default to shifting (white icons); force fixed + theme colors.
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      currentIndex: _selectedIndex,
      onTap: _onNavigationItemTap,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      unselectedFontSize: 8,
      selectedFontSize: 12,
      items: _destinations
          .map(
            (dest) => BottomNavigationBarItem(
              icon: dest.label == _personalLabel
                  ? _PersonalNavIcon(icon: dest.icon)
                  : Icon(dest.icon),
              label: dest.label,
            ),
          )
          .toList(),
    );
  }

  Widget _buildSelectedBody() {
    if (_selectedIndex == 0) {
      return ViewEventsHome(
          scrollController: _postsScrollController,
          rebuildFunction: () {
            setState(() {
              // there's a potential that new posts have been added
            });
          });
    } else if (_selectedIndex == 1) {
      return InformationHome(
        tabController: _informationTabController,
        scrollController: _informationScrollController,
      );
    } else if (_selectedIndex == 2) {
      return CellGroupsHome(
        tabController: _cellGroupsTabController,
        scrollController: _cellGroupsScrollController,
      );
    }
    return PersonalHome(
      appContext: _appContext,
      onBrowseCellGroups: () => setState(() => _selectedIndex = 2),
    );
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
      } else if (index == 2) {
        _cellGroupsScrollController.animateTo(0,
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
        builder: (_) => AppDialog(
          icon: Icons.waving_hand_outlined,
          title: 'Welcome!',
          message:
              'Thanks for visiting the CTRIM app! Stay connected with the latest updates, events, and announcements from CTRIM Belfast.',
          actions: AppDialogActions(
            onConfirm: () => Navigator.pop(context),
            confirmLabel: 'Get Started',
          ),
        ),
      );

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
      _handleOnMessage(message);
    });

    // when the app is opened in the background of device
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
          '-----------------Hello from on message opened app! Here is the message: ${message.data}');
      _handleOnMessageOpenedBackground(message);
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

      _openFromNotificationData(
          WebNotificationDeepLink.extractAppData(payload));
    });
  }

  void _handleWebLaunchDeepLink() {
    final params = WebNotificationDeepLink.consumeLaunchParams();
    if (params.isEmpty) return;
    _openFromNotificationData(params);
  }

  Future<void> _openFromNotificationData(Map<String, dynamic> data) async {
    if (_appContext.sharedPref.loggedOut) return;

    final appData = WebNotificationDeepLink.extractAppData(data);
    if (appData.containsKey('PostID')) {
      final postID = appData['PostID']?.toString() ?? '';
      if (postID.isEmpty) return;
      final head = await _reloadEventHead(postID);
      if (!mounted) return;
      _openPost(head);
      _updateUserRoles();
    } else if (appData.containsKey('InfoPage')) {
      final infoPage = appData['InfoPage']?.toString() ?? '';
      if (infoPage.isEmpty) return;
      if (!mounted) return;
      _openInformationTeachingPage(infoPage);
    }
  }

  Future<void> _handleInitialMessage(final RemoteMessage message) async {
    await _openFromNotificationData(message.data);
  }

  Future<void> _handleOnMessage(final RemoteMessage message) async {
    final appData = WebNotificationDeepLink.extractAppData(message.data);
    final bool openPage = _appContext.sharedPref.loggedOut
        ? false
        : await _showFCMMessage(message, appData);

    if (appData.containsKey('PostID')) {
      final String postID = appData['PostID'].toString();
      final head = await _reloadEventHead(postID);
      if (openPage) {
        _openPost(head);
      }
      _updateUserRoles();
    } else if (appData.containsKey('InfoPage') && openPage) {
      _openInformationTeachingPage(appData['InfoPage'].toString());
    }
  }

  Future<void> _handleOnMessageOpenedBackground(
      final RemoteMessage message) async {
    await _openFromNotificationData(message.data);
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
      final RemoteMessage message, Map<String, dynamic> appData) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) return false;

    final String? closeText = appData['CloseText']?.toString();
    final String? superImageUrl = appData['SuperImageUrl']?.toString();
    final l10n = AppLocalizations.of(context)!;
    final kind = WebNotificationDeepLink.openActionKind(appData);
    final String? openLabel = switch (kind) {
      WebNotificationDeepLink.openKindPost => l10n.notificationViewPost,
      WebNotificationDeepLink.openKindInfo => l10n.notificationViewPage,
      _ => null,
    };

    String? imageUrl;
    if (kIsWeb) {
      imageUrl = superImageUrl ?? notification.web?.image;
    } else {
      imageUrl = superImageUrl ??
          (Platform.isAndroid
              ? notification.android?.imageUrl
              : notification.apple?.imageUrl);
    }

    bool result = false;
    final dismissLabel = closeText ?? l10n.notificationDismiss;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppDialog(
        icon: imageUrl == null ? Icons.notifications_outlined : null,
        title: notification.title,
        message: notification.body,
        maxWidth: ResponsiveLayout.reviewDialogMaxWidth,
        child: imageUrl == null
            ? null
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  NetworkImageHelper.getImageUrl(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
        actions: openLabel != null
            ? AppDialogActions(
                onCancel: () => Navigator.of(context).pop(),
                cancelLabel: dismissLabel,
                onConfirm: () {
                  result = true;
                  Navigator.of(context).pop();
                },
                confirmLabel: openLabel,
              )
            : AppDialogActions(
                onConfirm: () => Navigator.of(context).pop(),
                confirmLabel: dismissLabel,
              ),
      ),
    );

    return result;
  }

  // in the case that the notification is on a Post Update - receiving word of a role
  Future<void> _updateUserRoles() async {
    final UserDBManager userDBManager = UserDBManager();
    _appContext.setCurrentUserRoles(
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

class _AddPostFab extends StatelessWidget {
  const _AddPostFab();

  @override
  Widget build(BuildContext context) {
    final canManage = context.select(
      (AppContext c) => (c.sessionEpoch, c.currentUser.canManagePostTemplates),
    );
    if (!canManage.$2) return const SizedBox.shrink();

    final uid = context.read<AppContext>().currentUser.id;
    return FloatingActionButton.extended(
      icon: const Icon(Icons.post_add),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SelectPostTemplatePage(
              eventContext: EventContext.adding(currentUserID: uid),
            ),
          ),
        );
      },
      label: const Text('Add Post'),
    );
  }
}

class _PersonalNavIcon extends StatelessWidget {
  const _PersonalNavIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => (c.sessionEpoch, c.headsEpoch));
    final appContext = context.read<AppContext>();
    if (appContext.isCurrentUserGuest) return Icon(icon);
    final user = appContext.currentUser;
    if (user.roles == null) return Icon(icon);
    final count = UserScheduleService.upcomingPostCount(
      user: user,
      eventHeads: appContext.eventHeads,
    );
    final child = Icon(icon);
    if (count == 0) return child;
    return Badge(
      label: Text('$count'),
      child: child,
    );
  }
}
