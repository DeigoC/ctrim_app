// This will utilse both approaches - SharedPref and File read/writing
import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';

import 'bulletin_listing.dart';
import 'cache/refresh_cooldown.dart';

class AppSharedPreferences {
  late final SharedPreferences _pref;
  static const String _isFirstOpen = 'isFirstOpen',
      _email = 'email',
      _pass = 'password',
      _clear = '',
      _fcmToken = 'token',
      _bookmarkedPosts = 'bookmarked',
      _fetchUserImgs = 'fetchUserImages',
      _lastPostRefresh = 'lastPostRefresh',
      _loggedOut = 'loggedOut',
      _subscribedToBelfast = 'subscribedToBelfast',
      _lastRoleRefresh = 'lastRoleRefresh',
      _lastUsersRefresh = 'lastUsersRefresh',
      _lastInfoRefresh = 'lastInfoRefresh',
      _lastCellGroupsRefresh = 'lastCellGroupsRefresh',
      _showMultirowTools = 'showMultirowTools',
      _preferredStartupTab = 'preferredStartupTab',
      _dismissedGuestBanner = 'dismissedGuestBanner',
      _guestFcmToken = 'guestFcmToken',
      _hasSeenBulletinDialog = 'hasSeenBulletinDialog',
      _hasSeenPwaHomeScreenPrompt = 'hasSeenPwaHomeScreenPrompt',
      _hasDeclinedNotificationPrePrompt = 'hasDeclinedNotificationPrePrompt',
      _bulletinSort = 'bulletinSort',
      _bulletinTimeFilter = 'bulletinTimeFilter',
      _bulletinBookmarksOnly = 'bulletinBookmarksOnly';

  AppSharedPreferences({required SharedPreferences preferences}) {
    _pref = preferences;
  }

  // * Cred related
  void saveCreds(String email, String password) {
    _pref.setString(_email, email);
    _pref.setString(_pass, password);
  }

  void clearCreds() {
    _pref.setString(_email, _clear);
    _pref.setString(_pass, _clear);
  }

  // * Notification related
  bool get isFirstOpen => _pref.getBool(_isFirstOpen) ?? true;
  void nowOpened() => _pref.setBool(_isFirstOpen, false);

  String get fcmToken => _pref.getString(_fcmToken) ?? '';
  void saveFCMToken(final String thisToken) =>
      _pref.setString(_fcmToken, thisToken);

  bool get loggedOut => _pref.getBool(_loggedOut) ?? true;
  void setLoggedOut(final bool state) => _pref.setBool(_loggedOut, state);

  // Old style notification, needs updating
  bool get subscribedToBelfast => _pref.getBool(_subscribedToBelfast) ?? true;
  void setSubscribedToBelfast(final bool newState) =>
      _pref.setBool(_subscribedToBelfast, newState);

  bool isSubscribedToTopic(final String topic) =>
      _pref.getBool("topic_$topic") ?? false;

  void setSubscribedToTopic(final String topic, final bool state) =>
      _pref.setBool("topic_$topic", state);

  // * Post related
  List<String> get bookmarkedPosts => UnmodifiableListView(
      _pref.getStringList(_bookmarkedPosts) ?? List.empty());

  void addPostBookmark(final String id) {
    final List<String> bookmarked =
        _pref.getStringList(_bookmarkedPosts) ?? List.empty(growable: true);
    if (!bookmarked.contains(id)) {
      bookmarked.add(id);
      _pref.setStringList(_bookmarkedPosts, bookmarked);
    }
  }

  void removePostBookmark(final String id) {
    final List<String> bookmarked =
        _pref.getStringList(_bookmarkedPosts) ?? List.empty(growable: true);
    bookmarked.remove(id);
    _pref.setStringList(_bookmarkedPosts, bookmarked);
  }

  bool get canRefreshPosts => _canRefreshSince(_lastPostRefresh);

  void setPostRefreshTime() => _markRefreshed(_lastPostRefresh);

  bool get canRefreshRoles => _canRefreshSince(_lastRoleRefresh);

  void setRoleRefreshTime() => _markRefreshed(_lastRoleRefresh);

  bool get canRefreshUsers => _canRefreshSince(_lastUsersRefresh);

  void setUsersRefreshTime() => _markRefreshed(_lastUsersRefresh);

  bool get canRefreshInfo => _canRefreshSince(_lastInfoRefresh);

  void setInfoRefreshTime() => _markRefreshed(_lastInfoRefresh);

  bool get canRefreshCellGroups => _canRefreshSince(_lastCellGroupsRefresh);

  void setCellGroupsRefreshTime() => _markRefreshed(_lastCellGroupsRefresh);

  bool _canRefreshSince(final String key) {
    try {
      return hasRefreshCooldownElapsed(
        now: DateTime.now(),
        lastRefreshMs: _pref.getInt(key),
      );
    } catch (e) {
      _pref.remove(key);
      return true;
    }
  }

  void _markRefreshed(final String key) =>
      _pref.setInt(key, DateTime.now().millisecondsSinceEpoch);

  bool get showMultirowTools => _pref.getBool(_showMultirowTools) ?? false;
  void setShowMultirowTools(final bool newState) =>
      _pref.setBool(_showMultirowTools, newState);

  // * Startup tab preference (0 = Events, 1 = Information)
  int get preferredStartupTab {
    // Handle corrupted data - if wrong type is stored, remove it and return default
    try {
      return _pref.getInt(_preferredStartupTab) ?? 1;
    } catch (e) {
      _pref.remove(_preferredStartupTab);
      return 1;
    }
  }

  void setPreferredStartupTab(final int tabIndex) =>
      _pref.setInt(_preferredStartupTab, tabIndex);

  // * Guest related
  bool get dismissedGuestBanner =>
      _pref.getBool(_dismissedGuestBanner) ?? false;
  void setDismissedGuestBanner(final bool dismissed) =>
      _pref.setBool(_dismissedGuestBanner, dismissed);

  String get guestFcmToken => _pref.getString(_guestFcmToken) ?? '';
  void saveGuestFCMToken(final String token) =>
      _pref.setString(_guestFcmToken, token);
  void clearGuestFCMToken() => _pref.setString(_guestFcmToken, _clear);

  // * Local data related
  bool get canRefreshUserImages {
    try {
      return _pref.getInt(_fetchUserImgs) == null
          ? true
          : DateTime.now()
                  .difference(DateTime.fromMillisecondsSinceEpoch(
                      _pref.getInt(_fetchUserImgs)!))
                  .inDays >=
              7;
    } catch (e) {
      _pref.remove(_fetchUserImgs);
      return true;
    }
  }

  void setUserImageRefreshTime() =>
      _pref.setInt(_fetchUserImgs, DateTime.now().millisecondsSinceEpoch);

  // * First-time dialog tracking
  bool get hasSeenBulletinDialog =>
      _pref.getBool(_hasSeenBulletinDialog) ?? false;
  void setHasSeenBulletinDialog() =>
      _pref.setBool(_hasSeenBulletinDialog, true);

  BulletinSort get bulletinSort =>
      BulletinSort.fromStorage(_pref.getString(_bulletinSort));
  void setBulletinSort(final BulletinSort sort) =>
      _pref.setString(_bulletinSort, sort.name);

  BulletinTimeFilter get bulletinTimeFilter =>
      BulletinTimeFilter.fromStorage(_pref.getString(_bulletinTimeFilter));
  void setBulletinTimeFilter(final BulletinTimeFilter filter) =>
      _pref.setString(_bulletinTimeFilter, filter.name);

  bool get bulletinBookmarksOnly =>
      _pref.getBool(_bulletinBookmarksOnly) ?? false;
  void setBulletinBookmarksOnly(final bool value) =>
      _pref.setBool(_bulletinBookmarksOnly, value);

  bool get hasSeenPwaHomeScreenPrompt =>
      _pref.getBool(_hasSeenPwaHomeScreenPrompt) ?? false;
  void setHasSeenPwaHomeScreenPrompt() =>
      _pref.setBool(_hasSeenPwaHomeScreenPrompt, true);

  /// User tapped "Not now" on the post-auth notification soft-ask.
  bool get hasDeclinedNotificationPrePrompt =>
      _pref.getBool(_hasDeclinedNotificationPrePrompt) ?? false;
  void setHasDeclinedNotificationPrePrompt([bool declined = true]) =>
      _pref.setBool(_hasDeclinedNotificationPrePrompt, declined);

  // Note: Post data, post tracking, and user data caching is now handled by
  // LocalDataManager which uses Hive and works across all platforms (web, mobile, desktop)
}
