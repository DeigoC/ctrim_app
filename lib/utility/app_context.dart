import 'dart:collection';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/event_metadata.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/models/user_contact.dart';
import 'package:ctrim_app/utility/app_data_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// handles some highlevel behaviours (like notifications) and persistant data for network optimisation
class AppContext extends ChangeNotifier {
  static final User _guest = User(id: '0', forname: 'Guest', surname: 'Account');

  // these will always be fetched on startup and maintained for the session
  static late final List<EventHead> _eventHeads;
  static late final List<User> _allUsers;
  static late final AppDataManager _dataManager;

  // there's an interesting idea for optimisation to do with the recentDate and writing to file
  // so this file below here might be unecessary for now
  static final Map<String, EventMetadata> _metaData = {};
  static final List<UserContact> _allContacts = List<UserContact>.empty(growable: true);

  late User _currentUser;

  AppContext({
    required List<EventHead> heads,
    required List<User> allUsers,
    required SharedPreferences prefInstance,
    User? user,
  }) {
    _eventHeads = eventHeads;
    _allUsers = allUsers;
    _currentUser = user ?? _guest;
    _dataManager = AppDataManager(preferences: prefInstance);
  }

  // * meta related
  void addMetadata(String id, EventMetadata data) => _metaData[id] = data;
  EventMetadata? getMetadata(String id) => _metaData[id];

  // * event head related
  List<EventHead> get eventHeads => UnmodifiableListView(_eventHeads);

  // * user related
  bool get isCurrentUserGuest => _currentUser.id.compareTo('0') == 0;
  List<User> get allUsers => _allUsers;
  void addUserContact(UserContact contact) => _allContacts.add(contact);
  void setUserToGuest() => _currentUser = _guest;
  void setCurrentUser(String id) => _currentUser = _allUsers.firstWhere((e) => e.id.compareTo(id) == 0);

  // * data related
  void saveEmailPassword(String email, String password) => _dataManager.saveCreds(email, password);
}
