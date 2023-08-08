// This will utilse both approaches - SharedPref and File read/writing
import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';

class AppSharedPreferences {
  static late final SharedPreferences _pref;
  static const String _isFirstOpen = 'isFirstOpen',
      _email = 'email',
      _pass = 'password',
      _clear = '',
      _token = 'token',
      _bookmarkedPosts = 'bookmarked',
      _fetchUserImgs = 'FetchUserImages';

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

  String get token => _pref.getString(_token) ?? '';
  void saveToken(String thisToken) => _pref.setString(_token, thisToken);

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

  // * Local data related
  bool get shouldFetchUserImages => _pref.getBool(_fetchUserImgs) ?? true;
  void justFetchedUserImages() => _pref.setBool(_fetchUserImgs, false);
}
