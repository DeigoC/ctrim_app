import 'dart:collection';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event/event_head.dart';
import '../models/event/event_metadata.dart';
import '../models/user.dart';
import '../models/user_location.dart';
import '../models/user_tag.dart';
import 'app_shared_preferences.dart';

// handles some highlevel behaviours (like notifications) and persistant data for network optimisation
class AppContext extends ChangeNotifier {
  static final User _guest = User(id: '0', forname: 'Guest', surname: 'Account');

  // these will always be fetched on startup and maintained for the session
  static late final List<EventHead> _eventHeads;
  static late final List<User> _allUsers;
  static late final List<UserTag> _allTags;
  static late final List<UserLocation> _allLocations;

  // there's an interesting idea for optimisation to do with the recentDate and writing to file
  // so this file below here might be unecessary for now
  static final Map<String, EventMetadata> _metaData = {};

  // no more 'user contact' we will hold the tokens as necessary
  static final Map<String, List<String>> _userTokens = {};
  static late final AppSharedPreferences _sharedPref;
  static late final String? _cacheDir, _appDir;
  static late final FirebaseAnalytics _analytics;

  late User _currentUser;

  int _postSortIndex = 0;
  bool _useCurrentUserSrc = false;

  AppContext(
      {required SharedPreferences prefInstance,
      required String? cacheDir,
      required String? appDir,
      required FirebaseAnalytics analytics,
      List<EventHead>? heads,
      List<User>? allUsers,
      List<UserTag>? allTags,
      List<UserLocation>? allLocations,
      User? user}) {
    _eventHeads = heads ?? List<EventHead>.empty(growable: true);
    _allUsers = allUsers ?? List<User>.empty(growable: true);
    _allTags = allTags ?? List<UserTag>.empty(growable: true);
    _allLocations = allLocations ?? List<UserLocation>.empty(growable: true);
    _currentUser = user ?? _guest;
    _analytics = analytics;
    _sharedPref = AppSharedPreferences(preferences: prefInstance);
    _cacheDir = cacheDir;
    _appDir = appDir;
  }

  // * meta related
  void setMetadata(final String id, final EventMetadata data) => _metaData[id] = data;
  EventMetadata? getMetadata(final String id) => _metaData[id];

  // * event head related
  List<EventHead> get eventHeads {
    return UnmodifiableListView(_eventHeads);
  }

  EventHead getPostHead(final String id) => _eventHeads.firstWhere((e) => e.id == id);

  void addNewPostHead(final EventHead newHead) => _eventHeads.insert(0, newHead);

  void addAllEventHeads(final List<EventHead> heads) => _eventHeads.addAll(heads);

  void addOrUpdatePostHead(final EventHead head) {
    _eventHeads.removeWhere((element) => element.id.compareTo(head.id) == 0);
    _eventHeads.insert(0, head);
  }

  void sortPostsByIndex() {
    // 0 Relevant activity - Mixed smart sorting
    // 1 Event date descending
    // 2 Event date ascending
    // 3 is for bookmarks. For now we default to the same as 0
    switch (_postSortIndex) {
      case 0:
        // Smart relevancy sorting: current event, recent posts, and upcoming events
        final DateTime now = DateTime.now();
        final DateTime threeDaysAgo = now.subtract(const Duration(days: 3));

        // Work with a copy and remove duplicates first
        final Map<String, EventHead> uniqueHeadsMap = {};
        for (var head in _eventHeads) {
          uniqueHeadsMap[head.id] = head;
        }
        final List<EventHead> originalHeads = uniqueHeadsMap.values.toList();

        // 1. Today's event (highest priority - event happening today)
        final List<EventHead> todayEvents =
            originalHeads.where((e) => e.eventDate != null && isAtSameDayAs(e.eventDate!)).toList();
        todayEvents.sort((a, b) => a.eventDate!.compareTo(b.eventDate!));

        // 2. Recent posts (last 3 days, excluding today's events)
        final Set<String> alreadyIncludedIds = {...todayEvents.map((e) => e.id)};
        final List<EventHead> recentPosts = originalHeads
            .where((e) => !alreadyIncludedIds.contains(e.id) && e.recentDate.isAfter(threeDaysAgo))
            .toList();
        recentPosts.sort((a, b) => b.recentDate.compareTo(a.recentDate));
        final List<EventHead> topRecentPosts = recentPosts.take(2).toList();

        // 3. Upcoming events (next few events after today)
        alreadyIncludedIds.addAll(topRecentPosts.map((e) => e.id));
        final List<EventHead> upcomingEvents = originalHeads
            .where((e) => !alreadyIncludedIds.contains(e.id) && e.eventDate != null && e.eventDate!.isAfter(now))
            .toList();
        upcomingEvents.sort((a, b) => a.eventDate!.compareTo(b.eventDate!));
        final List<EventHead> nextUpcoming = upcomingEvents.take(3).toList();

        // 4. Everything else sorted by recent date
        alreadyIncludedIds.addAll(nextUpcoming.map((e) => e.id));
        final List<EventHead> remainingPosts = originalHeads.where((e) => !alreadyIncludedIds.contains(e.id)).toList();
        remainingPosts.sort((a, b) => b.recentDate.compareTo(a.recentDate));

        // Combine all lists in priority order
        _eventHeads.clear();
        _eventHeads.addAll(todayEvents); // Today's events first
        _eventHeads.addAll(topRecentPosts); // Recent activity (2 posts)
        _eventHeads.addAll(nextUpcoming); // Upcoming events (3 posts)
        _eventHeads.addAll(remainingPosts); // Everything else

        _analytics.logEvent(name: 'post sort', parameters: {'type': 'recent activity'});
        break;
      case 1:
        // Remove duplicates first
        final Map<String, EventHead> uniqueHeads1 = {};
        for (var head in _eventHeads) {
          uniqueHeads1[head.id] = head;
        }
        _eventHeads.clear();
        _eventHeads.addAll(uniqueHeads1.values);

        _eventHeads.sort((a, b) {
          if (a.eventDate == null && b.eventDate == null) return 0;
          if (a.eventDate == null) return 1;
          if (b.eventDate == null) return -1;
          return a.eventDate!.compareTo(b.eventDate!);
        });
        _analytics.logEvent(name: 'post sort', parameters: {'type': 'upcoming events'});
        break;
      case 2:
        // Remove duplicates first
        final Map<String, EventHead> uniqueHeads2 = {};
        for (var head in _eventHeads) {
          uniqueHeads2[head.id] = head;
        }
        _eventHeads.clear();
        _eventHeads.addAll(uniqueHeads2.values);

        _eventHeads.sort((a, b) {
          if (a.eventDate == null && b.eventDate == null) return 0;
          if (a.eventDate == null) return 1;
          if (b.eventDate == null) return -1;
          return b.eventDate!.compareTo(a.eventDate!);
        });
        _analytics.logEvent(name: 'post sort', parameters: {'type': 'past events'});
        break;
      case 3:
        // Remove duplicates first
        final Map<String, EventHead> uniqueHeads3 = {};
        for (var head in _eventHeads) {
          uniqueHeads3[head.id] = head;
        }
        _eventHeads.clear();
        _eventHeads.addAll(uniqueHeads3.values);

        _eventHeads.sort((a, b) => b.recentDate.compareTo(a.recentDate));
        _analytics.logEvent(name: 'post sort', parameters: {'type': 'bookmarks'});
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

  bool isAtSameDayAs(Object? thisDate) {
    if (thisDate is DateTime) {
      return thisDate.year == DateTime.now().year &&
          thisDate.month == DateTime.now().month &&
          thisDate.day == DateTime.now().day;
    }
    return false;
  }

  // * user related
  bool get isCurrentUserGuest => _currentUser.id.compareTo('0') == 0;
  User get currentUser => _currentUser;
  List<User> get allUsers => _allUsers;
  List<UserTag> get allTags => UnmodifiableListView(_allTags);
  List<UserTag> get activeTags => _allTags.where((tag) => tag.isActive).toList();

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

  void setUserToGuest() => _currentUser = _guest;
  void setCurrentUser(final User? user) => _currentUser = user ?? _guest;
  User getUserFromID(final String id) => _allUsers.firstWhere((e) => e.id == id);

  // Upgrade from guest to authenticated user (used during background login)
  void upgradeToAuthenticatedUser({
    required User user,
    required List<EventHead> heads,
    required List<User> allUsers,
  }) {
    _currentUser = user;
    _eventHeads.clear();
    _eventHeads.addAll(heads);
    _allUsers.clear();
    _allUsers.addAll(allUsers);
    sortPostsByIndex();
    notifyListeners();
  }

  List<String> getTokensFromUserID(final String userID) => _userTokens[userID]!;
  bool haveTokensForUserID(final String userID) => _userTokens.containsKey(userID);
  void addTokensToUserID(final String userID, final List<String> tokens) => _userTokens[userID] = tokens;
  String getAuthIDFromUID(final String uid) => _allUsers.firstWhere((e) => e.id == uid).authID;

  bool get useUserImageSrc => _useCurrentUserSrc;
  void setNewUserImage(final String newSrc) {
    _currentUser.setImgSrc(newSrc);
    _useCurrentUserSrc = true;
  }

  // * data related
  AppSharedPreferences get sharedPref => _sharedPref;

  // * other related
  void rebuildPlease() => notifyListeners();
  String? get cacheDir => _cacheDir;
  String? get appDir => _appDir;

  FirebaseAnalytics get analytics => _analytics;
}
