import 'dart:collection';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/event_metadata.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/models/user_contact.dart';
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
  static final List<UserContact> _allContacts = List<UserContact>.empty(growable: true);
  static late final AppSharedPreferences _dataManager;

  late User _currentUser;

  AppContext({
    required List<EventHead> heads,
    required List<User> allUsers,
    required SharedPreferences prefInstance,
    required User user,
  }) {
    _eventHeads = heads;
    _allUsers = allUsers;
    _currentUser = user;
    _dataManager = AppSharedPreferences(preferences: prefInstance);
  }

  // * meta related
  void setMetadata(String id, EventMetadata data) => _metaData[id] = data;
  EventMetadata? getMetadata(String id) => _metaData[id];

  // * event head related
  List<EventHead> get eventHeads => UnmodifiableListView(_eventHeads);
  void addNewPostHead(final EventHead newHead) => _eventHeads.insert(0, newHead);
  void orderEventDatesByRecency() => _eventHeads.sort((a, b) => b.recentDate.compareTo(a.recentDate));

  void addOrUpdatePostHead(final EventHead head) {
    _eventHeads.removeWhere((element) => element.id.compareTo(head.id) == 0);
    _eventHeads.insert(0, head);
  }

  // * user related
  bool get isCurrentUserGuest => _currentUser.id.compareTo('0') == 0;
  User get currentUser => _currentUser;
  List<User> get allUsers => UnmodifiableListView(_allUsers);

  void addUser(User u) => _allUsers.add(u);
  void setUserToGuest() => _currentUser = _guest;
  void setCurrentUser(String id) => _currentUser = _allUsers.firstWhere((e) => e.id.compareTo(id) == 0);

  // contact related
  void addAllUserContacts(List<UserContact> contacts) {
    _allContacts.addAll(contacts);
  }

  List<UserContact> get userContacts => UnmodifiableListView(_allContacts);

  // * data related
  AppSharedPreferences get dataManager => _dataManager;

  // * other related
  void rebuildPlease() => notifyListeners();
}
