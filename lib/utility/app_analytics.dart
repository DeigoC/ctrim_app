import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';

import '../models/user.dart';

/// Sink for [AppAnalytics]. Production uses [FirebaseAnalyticsClient].
abstract class AnalyticsClient {
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });

  Future<void> logScreenView({
    required String screenName,
    Map<String, Object>? parameters,
  });

  Future<void> logLogin({String? loginMethod});

  Future<void> logSignUp({required String signUpMethod});

  Future<void> logShare({
    required String contentType,
    required String itemId,
    required String method,
  });

  Future<void> setUserId({String? id});

  Future<void> setUserProperty({required String name, String? value});
}

/// Delegates to the Firebase Analytics singleton.
class FirebaseAnalyticsClient implements AnalyticsClient {
  FirebaseAnalyticsClient(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    Map<String, Object>? parameters,
  }) {
    return _analytics.logScreenView(
      screenName: screenName,
      parameters: parameters,
    );
  }

  @override
  Future<void> logLogin({String? loginMethod}) {
    return _analytics.logLogin(loginMethod: loginMethod);
  }

  @override
  Future<void> logSignUp({required String signUpMethod}) {
    return _analytics.logSignUp(signUpMethod: signUpMethod);
  }

  @override
  Future<void> logShare({
    required String contentType,
    required String itemId,
    required String method,
  }) {
    return _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method,
    );
  }

  @override
  Future<void> setUserId({String? id}) => _analytics.setUserId(id: id);

  @override
  Future<void> setUserProperty({required String name, String? value}) {
    return _analytics.setUserProperty(name: name, value: value);
  }
}

/// Named analytics events for the community app.
///
/// A null [AnalyticsClient] drops every call, which is what tests use when
/// they construct [AppContext] without Firebase.
class AppAnalytics {
  AppAnalytics(this._client);

  final AnalyticsClient? _client;

  static final RegExp eventNamePattern =
      RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,39}$');

  static const String shellBulletin = 'bulletin';
  static const String shellPersonal = 'personal';
  static const String shellCtrimAbout = 'ctrim_about';
  static const String shellCtrimChurches = 'ctrim_churches';
  static const String shellCtrimTestimonials = 'ctrim_testimonials';
  static const String shellCtrimInformation = 'ctrim_information';
  static const String shellCellGroupsOverview = 'cell_groups_overview';
  static const String shellCellGroupsList = 'cell_groups_list';

  static const String _authState = 'auth_state';
  static const String _role = 'role';
  static const String _homeLocation = 'home_location';

  /// Home destination 0–3 plus the nested CTRIM or Cell Groups section.
  static String homeScreenName({
    required int destinationIndex,
    required int ctrimSection,
    required int cellGroupsSection,
  }) {
    switch (destinationIndex) {
      case 0:
        return shellBulletin;
      case 1:
        return _ctrimSectionName(ctrimSection);
      case 2:
        return cellGroupsSection == 0
            ? shellCellGroupsOverview
            : shellCellGroupsList;
      default:
        return shellPersonal;
    }
  }

  static String _ctrimSectionName(int section) {
    switch (section) {
      case 0:
        return shellCtrimAbout;
      case 1:
        return shellCtrimChurches;
      case 2:
        return shellCtrimTestimonials;
      default:
        return shellCtrimInformation;
    }
  }

  /// `area_admin` wins when both flags are set. Guests are not passed here.
  static String roleFor(User user) {
    if (user.isAreaAdmin) return 'area_admin';
    if (user.isLeader) return 'leader';
    return 'member';
  }

  void syncUser(User user, {required bool isGuest}) {
    final client = _client;
    if (client == null) return;
    if (isGuest) {
      unawaited(client.setUserId(id: null));
      unawaited(client.setUserProperty(name: _authState, value: 'guest'));
      unawaited(client.setUserProperty(name: _role, value: 'guest'));
      unawaited(client.setUserProperty(name: _homeLocation, value: ''));
      return;
    }
    unawaited(client.setUserId(id: user.id));
    unawaited(client.setUserProperty(name: _authState, value: 'member'));
    unawaited(client.setUserProperty(name: _role, value: roleFor(user)));
    unawaited(client.setUserProperty(
      name: _homeLocation,
      value: _clip(user.location, 36),
    ));
  }

  void logHome({
    required int destinationIndex,
    required int ctrimSection,
    required int cellGroupsSection,
  }) {
    _screen(homeScreenName(
      destinationIndex: destinationIndex,
      ctrimSection: ctrimSection,
      cellGroupsSection: cellGroupsSection,
    ));
  }

  void logLogin({required String loginMethod}) {
    unawaited(_client?.logLogin(loginMethod: loginMethod));
  }

  void logSignUp({required String signUpMethod}) {
    unawaited(_client?.logSignUp(signUpMethod: signUpMethod));
  }

  void logRegisterEmail() => _event('register_email');

  void logLogout() => _event('logout');

  void logBulletinListing({
    required String sort,
    required String time,
    required bool bookmarksOnly,
    required String location,
    required int tagCount,
  }) {
    _event('bulletin_listing', {
      'sort': sort,
      'time': time,
      'bookmarks': bookmarksOnly ? '1' : '0',
      'location': location,
      'tag_count': tagCount,
    });
  }

  void logPost({required String postId, required String source}) {
    _screen('post', {'post_id': postId, 'source': source});
  }

  void logPostGallery(String postId) =>
      _screen('post_gallery', {'post_id': postId});

  void logPostMetaLogs(String postId) =>
      _screen('post_meta_logs', {'post_id': postId});

  void logChurch({required String churchId, required String kind}) {
    _screen('church', {'church_id': churchId, 'kind': kind});
  }

  void logChurchPage({required String churchId, required String pageId}) {
    _screen('church_page', {'church_id': churchId, 'page_id': pageId});
  }

  void logChurchPastors(String churchId) =>
      _screen('church_pastors', {'church_id': churchId});

  void logTestimonial(String testimonialId) =>
      _screen('testimonial', {'testimonial_id': testimonialId});

  void logCtrimInfo(String infoId) =>
      _screen('ctrim_info', {'info_id': infoId});

  void logPersonalSunday() => _screen('personal_sunday');

  void logCellGroup(String groupId) =>
      _screen('cell_group', {'group_id': groupId});

  void logCellGroupsAtLocation(String locationId) =>
      _screen('cell_groups_list', {'location_id': locationId});

  void logPeopleDirectory() => _screen('people_directory');

  void logPerson({required String personId, required String source}) {
    _screen('person', {'person_id': personId, 'source': source});
  }

  void logMySchedule() => _screen('my_schedule');

  void logTeamRota() => _screen('team_rota');

  void logMyPosts() => _screen('my_posts');

  void logPostBookmark({required String postId, required bool added}) {
    _event('post_bookmark', {
      'action': added ? 'add' : 'remove',
      'post_id': postId,
    });
  }

  void logShare({
    required String contentType,
    required String method,
    required String itemId,
  }) {
    final client = _client;
    if (client == null) return;
    unawaited(client.logShare(
      contentType: contentType,
      itemId: _clip(itemId, 100),
      method: method,
    ));
  }

  void logPostInterest({required String postId, required bool interested}) {
    _event('post_interest', {
      'action': interested ? 'add' : 'remove',
      'post_id': postId,
    });
  }

  void logPostExpected({required String postId, required bool checked}) {
    _event('post_expected', {
      'action': checked ? 'check' : 'uncheck',
      'post_id': postId,
    });
  }

  void logPostAttendanceRemove(String postId) {
    _event('post_attendance', {'action': 'remove', 'post_id': postId});
  }

  void logCellGroupSearch({required String mode, bool? resolved}) {
    _event('cell_group_search', {
      'mode': mode,
      if (resolved != null) 'resolved': resolved ? '1' : '0',
    });
  }

  void logOpenMaps(String churchId) =>
      _event('open_maps', {'church_id': churchId});

  void logOpenSocial({required String churchId, required String platform}) {
    _event('open_social', {'church_id': churchId, 'platform': platform});
  }

  void logNotifPermission({required bool granted}) {
    _event('notif_permission', {'result': granted ? 'granted' : 'denied'});
  }

  void logNotifTopic({required String topic, required bool subscribed}) {
    _event(
      subscribed ? 'notif_subscribe' : 'notif_unsubscribe',
      {'topic': topic},
    );
  }

  void logPostCreate(String postId) =>
      _event('post_create', {'post_id': postId});

  void logPostSave(String postId) => _event('post_save', {'post_id': postId});

  void logPostBulkCreate(int count) =>
      _event('post_bulk_create', {'count': count});

  void logSchedulePresetApply(String postId) =>
      _event('schedule_preset_apply', {'post_id': postId});

  void _screen(String screenName, [Map<String, Object>? parameters]) {
    assert(eventNamePattern.hasMatch(screenName), screenName);
    final client = _client;
    if (client == null) return;
    unawaited(client.logScreenView(
      screenName: screenName,
      parameters: parameters == null ? null : _clipParams(parameters),
    ));
  }

  void _event(String name, [Map<String, Object>? parameters]) {
    assert(eventNamePattern.hasMatch(name), name);
    final client = _client;
    if (client == null) return;
    unawaited(client.logEvent(
      name: name,
      parameters: parameters == null ? null : _clipParams(parameters),
    ));
  }

  static Map<String, Object> _clipParams(Map<String, Object> parameters) {
    return {
      for (final entry in parameters.entries)
        entry.key: entry.value is String
            ? _clip(entry.value as String, 100)
            : entry.value,
    };
  }

  static String _clip(String value, int max) {
    if (value.length <= max) return value;
    return value.substring(0, max);
  }
}
