import 'dart:collection';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/event_metadata.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/app_shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// handles some highlevel behaviours (like notifications) and persistant data for network optimisation
class AppContext extends ChangeNotifier {
  static final User _guest = User(id: '0', forname: 'Guest', surname: 'Account');

  // these will always be fetched on startup and maintained for the session
  static late final List<EventHead> _eventHeads;
  static late final List<User> _allUsers;

  // there's an interesting idea for optimisation to do with the recentDate and writing to file
  // so this file below here might be unecessary for now
  static final Map<String, EventMetadata> _metaData = {};

  // no more 'user contact' we will hold the tokens as necessary
  static final Map<String, List<String>> _userTokens = {};
  static late final AppSharedPreferences _dataManager;
  static late final String _cacheDir, _appDir;

  late User _currentUser;

  int _postSortIndex = 0;

  AppContext(
      {required SharedPreferences prefInstance,
      required String cacheDir,
      required String appDir,
      List<EventHead>? heads,
      List<User>? allUsers,
      User? user}) {
    _eventHeads = heads ?? List<EventHead>.empty(growable: true);
    _allUsers = allUsers ?? List<User>.empty(growable: true);
    _currentUser = user ?? _guest;
    _dataManager = AppSharedPreferences(preferences: prefInstance);
    _cacheDir = cacheDir;
    _appDir = appDir;
  }

  // * meta related
  void setMetadata(final String id, final EventMetadata data) => _metaData[id] = data;
  EventMetadata? getMetadata(final String id) => _metaData[id];

  // * event head related
  List<EventHead> get eventHeads => UnmodifiableListView(_eventHeads);
  void addNewPostHead(final EventHead newHead) => _eventHeads.insert(0, newHead);

  void addAllEventHeads(final List<EventHead> heads) => _eventHeads.addAll(heads);

  void addOrUpdatePostHead(final EventHead head) {
    _eventHeads.removeWhere((element) => element.id.compareTo(head.id) == 0);
    _eventHeads.insert(0, head);
  }

  void sortPostsByIndex() {
    // 0 Recency date descending
    // 1 Event date descending
    // 2 Event date ascending
    // 3 Recency date ascending
    switch (_postSortIndex) {
      case 0:
        _eventHeads.sort((a, b) => b.recentDate.compareTo(a.recentDate));
        break;
      case 1:
        _eventHeads.sort((a, b) {
          if (a.eventDate == null && b.eventDate == null) return 0;
          if (a.eventDate == null) return 1;
          if (b.eventDate == null) return -1;
          return b.eventDate!.compareTo(a.eventDate!);
        });
        break;
      case 2:
        _eventHeads.sort((a, b) {
          if (a.eventDate == null && b.eventDate == null) return 0;
          if (a.eventDate == null) return 1;
          if (b.eventDate == null) return -1;
          return a.eventDate!.compareTo(b.eventDate!);
        });
        break;
      case 3:
        _eventHeads.sort((a, b) => a.recentDate.compareTo(b.recentDate));
        break;
    }
  }

  int get postSortIndex => _postSortIndex;
  void setPostSortIndex(int newIndex) => _postSortIndex = newIndex;

  void setRefreshedHeads(final List<EventHead> heads) {
    _eventHeads.clear();
    _eventHeads.addAll(heads);
    sortPostsByIndex();
  }

  // * user related
  bool get isCurrentUserGuest => _currentUser.id.compareTo('0') == 0;
  User get currentUser => _currentUser;
  List<User> get allUsers => _allUsers;

  void setUserToGuest() => _currentUser = _guest;
  void setCurrentUser(final User user) => _currentUser = user;

  List<String> getTokensFromUserID(final String userID) => _userTokens[userID]!;
  bool haveTokensForUserID(final String userID) => _userTokens.containsKey(userID);
  void addTokensToUser(final String userID, final List<String> tokens) => _userTokens[userID] = tokens;

  // * data related
  AppSharedPreferences get dataManager => _dataManager;

  // * other related
  void rebuildPlease() => notifyListeners();
  String get cacheDir => _cacheDir;
  String get appDir => _appDir;
}
