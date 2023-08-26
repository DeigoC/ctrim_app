// This will utilse both approaches - SharedPref and File read/writing
import 'dart:collection';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppSharedPreferences {
  static late final SharedPreferences _pref;
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
      _showMultirowTools = 'showMultirowTools';

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
  void saveFCMToken(final String thisToken) => _pref.setString(_fcmToken, thisToken);

  bool get loggedOut => _pref.getBool(_loggedOut) ?? true;
  void setLoggedOut(final bool state) => _pref.setBool(_loggedOut, state);

  bool get subscribedToBelfast => _pref.getBool(_subscribedToBelfast) ?? true;
  void setSubscribedToBelfast(final bool newState) => _pref.setBool(_subscribedToBelfast, newState);

  // * Post related
  List<String> get bookmarkedPosts => UnmodifiableListView(_pref.getStringList(_bookmarkedPosts) ?? List.empty());

  void addPostBookmark(final String id) {
    final List<String> bookmarked = _pref.getStringList(_bookmarkedPosts) ?? List.empty(growable: true);
    if (!bookmarked.contains(id)) {
      bookmarked.add(id);
      _pref.setStringList(_bookmarkedPosts, bookmarked);
    }
  }

  void removePostBookmark(final String id) {
    final List<String> bookmarked = _pref.getStringList(_bookmarkedPosts) ?? List.empty(growable: true);
    bookmarked.remove(id);
    _pref.setStringList(_bookmarkedPosts, bookmarked);
  }

  bool get canRefreshPosts => _pref.getInt(_lastPostRefresh) == null
      ? true
      : DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(_pref.getInt(_lastPostRefresh)!)).inMinutes >= 2;
  void setPostRefreshTime() => _pref.setInt(_lastPostRefresh, DateTime.now().millisecondsSinceEpoch);

  bool get canRefreshRoles => _pref.getInt(_lastRoleRefresh) == null
      ? true
      : DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(_pref.getInt(_lastRoleRefresh)!)).inMinutes >= 2;
  void setRoleRefreshTime() => _pref.setInt(_lastRoleRefresh, DateTime.now().millisecondsSinceEpoch);

  bool get showMultirowTools => _pref.getBool(_showMultirowTools) ?? false;
  void setShowMultirowTools(final bool newState) => _pref.setBool(_showMultirowTools, newState);

  // * Local data related
  bool get shouldFetchUserImages => _pref.getBool(_fetchUserImgs) ?? true;
  void justFetchedUserImages() => _pref.setBool(_fetchUserImgs, false);

  // * For WebApp - use localdata manager for native apps!

  List<String> getPostData(final String id) {
    final data = _pref.getString('postData-$id');
    if (data == null) {
      return List.empty();
    }
    const LineSplitter ls = LineSplitter();
    return ls.convert(data);
  }

  void writePostData(final String id, final String content) => _pref.setString('postData-$id', content);

  List<String> getPostTrack() => _pref.getStringList('postTrack') ?? [];

  void addPostTrackID(final String id) {
    final data = getPostTrack();
    if (!data.contains(id)) {
      data.add(id);
      _pref.setStringList('postTrack', data);
    }
  }

  List<String> getUsersData() {
    final data = _pref.getString('usersData');
    if (data == null) {
      return List.empty();
    }
    const LineSplitter ls = LineSplitter();
    return ls.convert(data);
  }

  void setUsersData(final String data) => _pref.setString('usersData', data);

  void setLastUsersFetch() => _pref.setString('lastUserFetch', DateTime.now().millisecondsSinceEpoch.toString());
}
