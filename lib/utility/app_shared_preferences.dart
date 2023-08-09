// This will utilse both approaches - SharedPref and File read/writing
import 'dart:collection';

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
      _phoneToken = 'phoneToken';

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

  void savePhoneToken(int token) {
    _pref.setInt(_phoneToken, token);
  }

  int? get phoneToken => _pref.getInt(_phoneToken);

  // * Notification related
  bool get isFirstOpen => _pref.getBool(_isFirstOpen) ?? true;
  void nowOpened() => _pref.setBool(_isFirstOpen, false);

  String get fcmToken => _pref.getString(_fcmToken) ?? '';
  void saveFCMToken(String thisToken) => _pref.setString(_fcmToken, thisToken);

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

  // * Local data related
  bool get shouldFetchUserImages => _pref.getBool(_fetchUserImgs) ?? true;
  void justFetchedUserImages() => _pref.setBool(_fetchUserImgs, false);
}
