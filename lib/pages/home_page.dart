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
import '../utility/app_analytics.dart';
import '../utility/app_context.dart';
import '../utility/event_context.dart';
import '../utility/cache/local_data_manager.dart';
import '../utility/network_image_helper.dart';
import '../utility/responsive_layout.dart';
import '../utility/user_schedule_service.dart';
import '../utility/notifications/web_notification_lifecycle.dart';
import '../utility/notifications/notification_subscription_service.dart';
import '../utility/app_links.dart';
import '../utility/notifications/web_notification_deep_link.dart';
import '../src/localization/app_localizations.dart';
import '../widgets/common/app_dialog.dart';
import 'events/post_templates/select_post_template_page.dart';
import 'events/events_home.dart';
import 'cell_groups/cell_groups_home.dart';
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
  static const int _ctrimIndex = 1;
  static const double _iconRailWidth = 80;
  static const double _labeledRailWidth = 220;

  late final TabController _informationTabController;
  late final TabController _cellGroupsTabController;
  late int _selectedIndex;
  String? _loggedShellScreen;

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

    _informationTabController = TabController(
      length: InformationHome.sections.length,
      vsync: this,
    );
    _informationTabController.addListener(_onInformationSectionChanged);
    _cellGroupsTabController = TabController(length: 2, vsync: this);
    _cellGroupsTabController.addListener(_onCellGroupsSectionChanged);
    _logShellScreen();
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
    _informationTabController.removeListener(_onInformationSectionChanged);
    _informationTabController.dispose();
    _cellGroupsTabController.removeListener(_onCellGroupsSectionChanged);
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
          final nestCtrimSections =
              constraints.maxWidth >= ResponsiveLayout.desktop;
          return Scaffold(
            body: useRail
                ? _buildWideBody(nestCtrimSections: nestCtrimSections)
                : _buildSelectedBody(),
            floatingActionButton:
                _selectedIndex == 0 ? const _AddPostFab() : null,
            bottomNavigationBar: useRail ? null : _buildBottomNavigationBar(),
          );
        },
      ),
    );
  }

  Widget _buildWideBody({required bool nestCtrimSections}) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _ShellNavRail(
          destinations: _destinations,
          selectedIndex: _selectedIndex,
          personalLabel: _personalLabel,
          nestSections: nestCtrimSections,
          groups: [
            _NavSectionGroup(
              destinationIndex: _ctrimIndex,
              sections: InformationHome.sections,
              selectedSection: _informationTabController.index,
              onSectionSelected: _selectCtrimSection,
            ),
            _NavSectionGroup(
              destinationIndex: 2,
              sections: [
                (
                  label: l10n.cellGroupsTabOverview,
                  icon: Icons.info_outline,
                ),
                (label: l10n.cellGroupsTabGroups, icon: Icons.groups),
              ],
              selectedSection: _cellGroupsTabController.index,
              onSectionSelected: _selectCellGroupSection,
            ),
          ],
          onDestinationSelected: _onNavigationItemTap,
          width: nestCtrimSections ? _labeledRailWidth : _iconRailWidth,
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _buildSelectedBody()),
      ],
    );
  }

  void _onInformationSectionChanged() {
    if (_informationTabController.indexIsChanging) return;
    _logShellScreen();
    if (mounted) setState(() {});
  }

  void _onCellGroupsSectionChanged() {
    if (_cellGroupsTabController.indexIsChanging) return;
    _logShellScreen();
    if (mounted) setState(() {});
  }

  void _logShellScreen() {
    final name = AppAnalytics.homeScreenName(
      destinationIndex: _selectedIndex,
      ctrimSection: _informationTabController.index,
      cellGroupsSection: _cellGroupsTabController.index,
    );
    if (name == _loggedShellScreen) return;
    _loggedShellScreen = name;
    _appContext.analytics.logHome(
      destinationIndex: _selectedIndex,
      ctrimSection: _informationTabController.index,
      cellGroupsSection: _cellGroupsTabController.index,
    );
  }

  void _selectCtrimSection(int section) {
    _selectNestedSection(
      destinationIndex: _ctrimIndex,
      section: section,
      controller: _informationTabController,
    );
  }

  void _selectCellGroupSection(int section) {
    _selectNestedSection(
      destinationIndex: 2,
      section: section,
      controller: _cellGroupsTabController,
    );
  }

  void _selectNestedSection({
    required int destinationIndex,
    required int section,
    required TabController controller,
  }) {
    if (_selectedIndex != destinationIndex) {
      setState(() => _selectedIndex = destinationIndex);
    }
    if (controller.index != section) {
      controller.animateTo(section);
    }
    _logShellScreen();
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
      onBrowseCellGroups: () {
        setState(() => _selectedIndex = 2);
        _logShellScreen();
      },
    );
  }

  // * Logic

  void _onNavigationItemTap(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      _logShellScreen();
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
    final appData = WebNotificationDeepLink.extractAppData(data);
    if (appData.containsKey('PostID')) {
      final postID = appData['PostID']?.toString() ?? '';
      if (postID.isEmpty) return;
      final head = await _reloadEventHead(postID);
      if (!mounted) return;
      AppLinks.openPost(context, id: postID, extra: head);
      if (head != null) _updateUserRoles();
      return;
    }

    if (appData.containsKey('InfoPage')) {
      final infoPage = appData['InfoPage']?.toString() ?? '';
      if (infoPage.isEmpty) return;
      if (!mounted) return;
      AppLinks.openInfo(context, id: infoPage);
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
      if (openPage && mounted) {
        AppLinks.openPost(context, id: postID, extra: head);
      }
      if (head != null) _updateUserRoles();
    } else if (appData.containsKey('InfoPage') && openPage) {
      AppLinks.openInfo(context, id: appData['InfoPage'].toString());
    }
  }

  Future<void> _handleOnMessageOpenedBackground(
      final RemoteMessage message) async {
    await _openFromNotificationData(message.data);
  }

  Future<EventHead?> _reloadEventHead(final String postID) async {
    try {
      final head = await EventHeadDBManager().fetchHeadIfExists(postID);
      if (head != null) {
        _appContext.addOrUpdatePostHead(head);
      }
      return head;
    } catch (e) {
      debugPrint('Failed to reload post head $postID: $e');
      return null;
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

class _NavSectionGroup {
  const _NavSectionGroup({
    required this.destinationIndex,
    required this.sections,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final int destinationIndex;
  final List<({String label, IconData icon})> sections;
  final int selectedSection;
  final ValueChanged<int> onSectionSelected;
}

class _ShellNavRail extends StatelessWidget {
  const _ShellNavRail({
    required this.destinations,
    required this.selectedIndex,
    required this.personalLabel,
    required this.nestSections,
    required this.groups,
    required this.onDestinationSelected,
    required this.width,
  });

  final List<_NavDestination> destinations;
  final int selectedIndex;
  final String personalLabel;
  final bool nestSections;
  final List<_NavSectionGroup> groups;
  final ValueChanged<int> onDestinationSelected;
  final double width;

  _NavSectionGroup? _groupFor(int index) {
    for (final group in groups) {
      if (group.destinationIndex == index) return group;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: SizedBox(
        width: width,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/ctrim_logo.png',
                    width: 48,
                    height: 48,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.church,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (var index = 0; index < destinations.length; index++)
                      ..._destination(context, index),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _destination(BuildContext context, int index) {
    final dest = destinations[index];
    final selected = selectedIndex == index;
    final icon = dest.label == personalLabel
        ? _PersonalNavIcon(icon: dest.icon)
        : Icon(dest.icon);
    final group = _groupFor(index);
    final showChildren = nestSections && group != null && selected;

    if (!nestSections && group != null) {
      return [
        PopupMenuButton<int>(
          tooltip: dest.label,
          offset: Offset(width - 8, 0),
          onOpened: () {
            if (!selected) onDestinationSelected(index);
          },
          onSelected: group.onSectionSelected,
          itemBuilder: (context) => [
            for (var section = 0; section < group.sections.length; section++)
              PopupMenuItem<int>(
                value: section,
                child: Row(
                  children: [
                    Icon(
                      group.sections[section].icon,
                      color: selected && group.selectedSection == section
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      group.sections[section].label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight:
                                selected && group.selectedSection == section
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
          ],
          child: _RailButton(
            icon: icon,
            label: dest.label,
            selected: selected,
            showLabel: false,
            tooltip: dest.label,
          ),
        ),
      ];
    }

    return [
      _RailButton(
        icon: icon,
        label: dest.label,
        selected: selected,
        showLabel: nestSections,
        tooltip: nestSections ? '' : dest.label,
        onTap: () => onDestinationSelected(index),
      ),
      if (showChildren)
        for (var section = 0; section < group.sections.length; section++)
          _RailButton(
            icon: Icon(group.sections[section].icon),
            label: group.sections[section].label,
            selected: group.selectedSection == section,
            showLabel: true,
            indented: true,
            onTap: () => group.onSectionSelected(section),
          ),
    ];
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.showLabel,
    this.indented = false,
    this.tooltip = '',
    this.onTap,
  });

  final Widget icon;
  final String label;
  final bool selected;
  final bool showLabel;
  final bool indented;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;
    final button = Padding(
      padding: EdgeInsets.only(left: indented ? 12 : 0, bottom: 4),
      child: Material(
        color: selected ? colorScheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: showLabel ? 12 : 0,
              vertical: 10,
            ),
            child: showLabel
                ? Row(
                    children: [
                      IconTheme(
                        data: IconThemeData(color: foreground, size: 24),
                        child: icon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: foreground,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: IconTheme(
                      data: IconThemeData(color: foreground, size: 24),
                      child: icon,
                    ),
                  ),
          ),
        ),
      ),
    );
    if (tooltip.isEmpty) return button;
    return Tooltip(message: tooltip, child: button);
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
