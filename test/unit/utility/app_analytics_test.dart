import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/app_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _RecordingAnalyticsClient client;
  late AppAnalytics analytics;

  setUp(() {
    client = _RecordingAnalyticsClient();
    analytics = AppAnalytics(client);
  });

  User person({
    String id = 'u1',
    bool isLeader = false,
    bool isAreaAdmin = false,
    String location = 'Belfast',
  }) {
    return User(
      id: id,
      forname: 'Ann',
      surname: 'Bee',
      isLeader: isLeader,
      isAreaAdmin: isAreaAdmin,
      location: location,
    );
  }

  group('AppAnalytics identity', () {
    test('guest clears the user id', () {
      analytics.syncUser(person(location: 'Lisburn'), isGuest: true);

      expect(client.userIds, [null]);
      expect(client.userProperties['auth_state'], 'guest');
      expect(client.userProperties['role'], 'guest');
      expect(client.userProperties['home_location'], '');
    });

    test('member keeps id, role, and home location', () {
      analytics.syncUser(person(location: 'Lisburn'), isGuest: false);

      expect(client.userIds, ['u1']);
      expect(client.userProperties['auth_state'], 'member');
      expect(client.userProperties['role'], 'member');
      expect(client.userProperties['home_location'], 'Lisburn');
    });

    test('leader is a member with the leader role', () {
      analytics.syncUser(person(isLeader: true), isGuest: false);

      expect(client.userProperties['auth_state'], 'member');
      expect(client.userProperties['role'], 'leader');
    });

    test('area admin wins over leader', () {
      analytics.syncUser(
        person(isLeader: true, isAreaAdmin: true),
        isGuest: false,
      );

      expect(client.userProperties['role'], 'area_admin');
    });
  });

  group('AppAnalytics events', () {
    test('names are GA4-safe and registration has no space', () {
      analytics.logRegisterEmail();
      analytics.logLogout();
      analytics.logBulletinListing(
        sort: 'relevancy',
        time: 'all',
        bookmarksOnly: false,
        location: 'Belfast',
        tagCount: 0,
      );
      analytics.logPostBookmark(postId: 'p1', added: true);
      analytics.logPostInterest(postId: 'p1', interested: false);
      analytics.logPostExpected(postId: 'p1', checked: true);
      analytics.logPostAttendanceRemove('p1');
      analytics.logCellGroupSearch(mode: 'name');
      analytics.logCellGroupSearch(mode: 'postcode', resolved: false);
      analytics.logOpenMaps('church-1');
      analytics.logOpenSocial(churchId: 'church-1', platform: 'website');
      analytics.logNotifPermission(granted: true);
      analytics.logNotifTopic(topic: 'belfast', subscribed: true);
      analytics.logNotifTopic(topic: 'belfast', subscribed: false);
      analytics.logPostCreate('p1');
      analytics.logPostSave('p1');
      analytics.logPostBulkCreate(4);
      analytics.logSchedulePresetApply('p1');
      analytics.logPost(postId: 'p1', source: 'in_app');
      analytics.logTestimonial('t1');

      expect(
          client.events.map((event) => event.name), contains('register_email'));
      expect(
        client.events.map((event) => event.name),
        isNot(contains('register email')),
      );
      for (final event in client.events) {
        expect(event.name, matches(AppAnalytics.eventNamePattern));
      }
      for (final screen in client.screens) {
        expect(screen.name, matches(AppAnalytics.eventNamePattern));
      }
    });

    test('bulletin listing includes location and tag count', () {
      analytics.logBulletinListing(
        sort: 'relevancy',
        time: 'week',
        bookmarksOnly: true,
        location: 'Belfast',
        tagCount: 2,
      );

      expect(client.events.single.parameters, {
        'sort': 'relevancy',
        'time': 'week',
        'bookmarks': '1',
        'location': 'Belfast',
        'tag_count': 2,
      });
    });

    test('post and testimonial screens use ids', () {
      analytics.logPost(postId: 'post-1', source: 'link');
      analytics.logTestimonial('testimonial-9');

      expect(client.screens[0].name, 'post');
      expect(client.screens[0].parameters, {
        'post_id': 'post-1',
        'source': 'link',
      });
      expect(client.screens[1].name, 'testimonial');
      expect(client.screens[1].parameters, {'testimonial_id': 'testimonial-9'});
      expect(client.screens[1].parameters.toString(), isNot(contains('Ann')));
    });

    test('home tabs use stable screen names', () {
      expect(
        AppAnalytics.homeScreenName(
          destinationIndex: 0,
          ctrimSection: 0,
          cellGroupsSection: 0,
        ),
        'bulletin',
      );
      expect(
        AppAnalytics.homeScreenName(
          destinationIndex: 1,
          ctrimSection: 2,
          cellGroupsSection: 0,
        ),
        'ctrim_testimonials',
      );
      expect(
        AppAnalytics.homeScreenName(
          destinationIndex: 2,
          ctrimSection: 0,
          cellGroupsSection: 1,
        ),
        'cell_groups_list',
      );
      expect(
        AppAnalytics.homeScreenName(
          destinationIndex: 3,
          ctrimSection: 0,
          cellGroupsSection: 0,
        ),
        'personal',
      );
    });
  });
}

class _RecordedCall {
  _RecordedCall(this.name, [this.parameters]);

  final String name;
  final Map<String, Object>? parameters;
}

class _RecordingAnalyticsClient implements AnalyticsClient {
  final List<_RecordedCall> events = [];
  final List<_RecordedCall> screens = [];
  final List<String?> userIds = [];
  final Map<String, String?> userProperties = {};

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    events.add(_RecordedCall(name, parameters));
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    Map<String, Object>? parameters,
  }) async {
    screens.add(_RecordedCall(screenName, parameters));
  }

  @override
  Future<void> logLogin({String? loginMethod}) async {}

  @override
  Future<void> logSignUp({required String signUpMethod}) async {}

  @override
  Future<void> logShare({
    required String contentType,
    required String itemId,
    required String method,
  }) async {}

  @override
  Future<void> setUserId({String? id}) async {
    userIds.add(id);
  }

  @override
  Future<void> setUserProperty({required String name, String? value}) async {
    userProperties[name] = value;
  }
}
