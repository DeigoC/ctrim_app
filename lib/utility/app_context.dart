import 'dart:collection';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cell_group.dart';
import '../models/event/event_head.dart';
import '../models/event/event_metadata.dart';
import '../models/post_tag.dart';
import '../models/user.dart';
import '../models/user_location.dart';
import '../models/user_role_assignment.dart';
import '../models/user_tag.dart';
import 'app_shared_preferences.dart';

/// Session cache for the signed-in user, volunteer directory, bulletin heads,
/// and admin catalogs. Mutate only through the methods on this class.
class AppContext extends ChangeNotifier {
  static final User _guest =
      User(id: '0', forname: 'Guest', surname: 'Account');

  final List<EventHead> _eventHeads;
  final List<User> _allUsers;
  final List<UserTag> _allTags;
  final List<PostTag> _allPostTags;
  final List<UserLocation> _allLocations;
  final List<CellGroup> _allCellGroups;

  final Map<String, EventHead> _headsById = {};
  final Map<String, User> _usersById = {};

  final Map<String, EventMetadata> _metaData = {};
  final Map<String, List<String>> _userTokens = {};

  late final AppSharedPreferences _sharedPref;
  late final String? _cacheDir, _appDir;
  final FirebaseAnalytics? _analytics;

  late User _currentUser;

  bool _useCurrentUserSrc = false;

  int _sessionEpoch = 0;
  int _usersEpoch = 0;
  int _headsEpoch = 0;
  int _catalogsEpoch = 0;

  int get sessionEpoch => _sessionEpoch;
  int get usersEpoch => _usersEpoch;
  int get headsEpoch => _headsEpoch;
  int get catalogsEpoch => _catalogsEpoch;

  void _notify({
    bool session = false,
    bool users = false,
    bool heads = false,
    bool catalogs = false,
  }) {
    if (session) _sessionEpoch++;
    if (users) _usersEpoch++;
    if (heads) _headsEpoch++;
    if (catalogs) _catalogsEpoch++;
    notifyListeners();
  }

  AppContext(
      {required SharedPreferences prefInstance,
      required String? cacheDir,
      required String? appDir,
      FirebaseAnalytics? analytics,
      List<EventHead>? heads,
      List<User>? allUsers,
      List<UserTag>? allTags,
      List<PostTag>? allPostTags,
      List<UserLocation>? allLocations,
      List<CellGroup>? allCellGroups,
      User? user})
      : _eventHeads = List<EventHead>.from(heads ?? const []),
        _allUsers = List<User>.from(allUsers ?? const []),
        _allTags = List<UserTag>.from(allTags ?? const []),
        _allPostTags = List<PostTag>.from(allPostTags ?? const []),
        _allLocations = List<UserLocation>.from(allLocations ?? const []),
        _allCellGroups = List<CellGroup>.from(allCellGroups ?? const []),
        _analytics = analytics {
    _currentUser = user ?? _guest;
    _sharedPref = AppSharedPreferences(preferences: prefInstance);
    _cacheDir = cacheDir;
    _appDir = appDir;
    _sortUsers();
    _reindexUsers();
    _reindexHeads();
  }

  // * meta related
  void setMetadata(final String id, final EventMetadata data) =>
      _metaData[id] = data;
  EventMetadata? getMetadata(final String id) => _metaData[id];

  // * event head related
  List<EventHead> get eventHeads => UnmodifiableListView(_eventHeads);

  EventHead? headById(final String id) => _headsById[id];

  void addNewPostHead(final EventHead newHead) => addOrUpdatePostHead(newHead);

  void addOrUpdatePostHead(final EventHead head) {
    _eventHeads.removeWhere((element) => element.id == head.id);
    _eventHeads.insert(0, head);
    _headsById[head.id] = head;
    _notify(heads: true);
  }

  void setAllEventHeads(final List<EventHead> heads) {
    _eventHeads
      ..clear()
      ..addAll(heads);
    _reindexHeads();
    notifyListeners();
  }

  void setRefreshedHeads(final List<EventHead> heads) =>
      setAllEventHeads(heads);

  void _reindexHeads() {
    _headsById
      ..clear()
      ..addEntries(_eventHeads.map((head) => MapEntry(head.id, head)));
  }

  // * user related
  bool get isCurrentUserGuest => _currentUser.id.compareTo('0') == 0;
  User get currentUser => _currentUser;
  List<User> get allUsers => UnmodifiableListView(_allUsers);
  List<UserTag> get allTags => UnmodifiableListView(_allTags);
  List<UserTag> get activeTags =>
      _allTags.where((tag) => tag.isActive).toList();

  User? userById(final String id) => _usersById[id];

  void setAllUsers(final List<User> users) {
    _allUsers
      ..clear()
      ..addAll(users);
    _sortUsers();
    _reindexUsers();
    notifyListeners();
  }

  void addOrUpdateUser(final User user) {
    _allUsers.removeWhere((u) => u.id == user.id);
    _allUsers.add(user);
    _sortUsers();
    _usersById[user.id] = user;
    notifyListeners();
  }

  void removeUser(final String id) {
    _allUsers.removeWhere((u) => u.id == id);
    _usersById.remove(id);
    notifyListeners();
  }

  void _sortUsers() {
    _allUsers.sort((a, b) {
      final surname = a.surname.compareTo(b.surname);
      if (surname == 0) {
        return a.forname.compareTo(b.forname);
      }
      return surname;
    });
  }

  void _reindexUsers() {
    _usersById
      ..clear()
      ..addEntries(_allUsers.map((user) => MapEntry(user.id, user)));
  }

  void setAllTags(final List<UserTag> tags) {
    _allTags
      ..clear()
      ..addAll(tags);
    _allTags.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
    notifyListeners();
  }

  void addOrUpdateTag(final UserTag tag) {
    _allTags.removeWhere((t) => t.id == tag.id);
    _allTags.add(tag);
    _allTags.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
    notifyListeners();
  }

  void removeTag(final String tagId) {
    _allTags.removeWhere((t) => t.id == tagId);
    notifyListeners();
  }

  UserTag? tagById(final String tagId) {
    for (final tag in _allTags) {
      if (tag.id == tagId) return tag;
    }
    return null;
  }

  List<PostTag> get allPostTags => UnmodifiableListView(_allPostTags);
  List<PostTag> get activePostTags =>
      _allPostTags.where((tag) => tag.isActive).toList();

  void setAllPostTags(final List<PostTag> tags) {
    _allPostTags
      ..clear()
      ..addAll(tags);
    _allPostTags.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
    notifyListeners();
  }

  void addOrUpdatePostTag(final PostTag tag) {
    _allPostTags.removeWhere((t) => t.id == tag.id);
    _allPostTags.add(tag);
    _allPostTags.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
    notifyListeners();
  }

  void removePostTag(final String tagId) {
    _allPostTags.removeWhere((t) => t.id == tagId);
    notifyListeners();
  }

  PostTag? postTagById(final String tagId) {
    for (final tag in _allPostTags) {
      if (tag.id == tagId) return tag;
    }
    return null;
  }

  List<CellGroup> get allCellGroups => UnmodifiableListView(_allCellGroups);
  List<CellGroup> get activeCellGroups =>
      _allCellGroups.where((g) => g.isActive).toList();

  void setAllCellGroups(final List<CellGroup> groups) {
    _allCellGroups
      ..clear()
      ..addAll(groups);
    _sortCellGroups();
    notifyListeners();
  }

  void addOrUpdateCellGroup(final CellGroup group) {
    _allCellGroups.removeWhere((g) => g.id == group.id);
    _allCellGroups.add(group);
    _sortCellGroups();
    notifyListeners();
  }

  void removeCellGroup(final String groupId) {
    _allCellGroups.removeWhere((g) => g.id == groupId);
    notifyListeners();
  }

  CellGroup? cellGroupById(final String groupId) {
    for (final group in _allCellGroups) {
      if (group.id == groupId) return group;
    }
    return null;
  }

  void _sortCellGroups() {
    _allCellGroups.sort((a, b) {
      final statusOrder = _cellGroupStatusRank(a.status)
          .compareTo(_cellGroupStatusRank(b.status));
      if (statusOrder != 0) return statusOrder;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  static int _cellGroupStatusRank(final String status) {
    switch (status) {
      case CellGroupStatus.active:
        return 0;
      case CellGroupStatus.paused:
        return 1;
      case CellGroupStatus.archived:
        return 2;
      default:
        return 3;
    }
  }

  List<UserLocation> get allLocations => UnmodifiableListView(_allLocations);
  List<UserLocation> get activeLocations =>
      _allLocations.where((location) => location.isActive).toList();

  void setAllLocations(final List<UserLocation> locations) {
    _allLocations
      ..clear()
      ..addAll(locations);
    _allLocations.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
    notifyListeners();
  }

  void addOrUpdateLocation(final UserLocation location) {
    _allLocations.removeWhere((l) => l.id == location.id);
    _allLocations.add(location);
    _allLocations.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
    notifyListeners();
  }

  void removeLocation(final String locationId) {
    _allLocations.removeWhere((l) => l.id == locationId);
    notifyListeners();
  }

  /// Updates in-memory user location strings after a definition rename.
  void renameUsersLocation(final String oldName, final String newName) {
    for (final user in _allUsers) {
      if (user.location == oldName) {
        user.setLocation(newName);
      }
    }
    if (_currentUser.location == oldName) {
      _currentUser.setLocation(newName);
    }
    notifyListeners();
  }

  void setUserToGuest() {
    _currentUser = _guest;
    notifyListeners();
  }

  void setCurrentUser(final User? user) {
    _currentUser = user ?? _guest;
    notifyListeners();
  }

  void setCurrentUserRoles(final List<UserRoleAssignment> roles) {
    _currentUser.setRoles(roles);
    notifyListeners();
  }

  // Upgrade from guest to authenticated user (used during background login)
  void upgradeToAuthenticatedUser({
    required User user,
    required List<EventHead> heads,
    required List<User> allUsers,
  }) {
    _currentUser = user;
    _eventHeads
      ..clear()
      ..addAll(heads);
    _allUsers
      ..clear()
      ..addAll(allUsers);
    _sortUsers();
    _reindexUsers();
    _reindexHeads();
    notifyListeners();
  }

  List<String> getTokensFromUserID(final String userID) =>
      _userTokens[userID] ?? const <String>[];
  bool haveTokensForUserID(final String userID) =>
      _userTokens.containsKey(userID);
  void addTokensToUserID(final String userID, final List<String> tokens) =>
      _userTokens[userID] = tokens;

  String? authIdByUserId(final String uid) {
    final user = _usersById[uid];
    if (user == null) return null;
    return user.authID;
  }

  bool get useUserImageSrc => _useCurrentUserSrc;
  void setNewUserImage(final String newSrc) {
    _currentUser.setImgSrc(newSrc);
    _useCurrentUserSrc = true;
    final directory = _usersById[_currentUser.id];
    if (directory != null && !identical(directory, _currentUser)) {
      directory.setImgSrc(newSrc);
    }
    notifyListeners();
  }

  // * data related
  AppSharedPreferences get sharedPref => _sharedPref;

  String? get cacheDir => _cacheDir;
  String? get appDir => _appDir;

  FirebaseAnalytics get analytics => _analytics!;
}
