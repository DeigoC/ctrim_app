import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/models/user_tag.dart';
import 'package:ctrim_app/utility/app_context.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  AppContext context({
    List<EventHead>? heads,
    List<User>? users,
    User? user,
  }) {
    return AppContext(
      prefInstance: prefs,
      cacheDir: null,
      appDir: null,
      heads: heads,
      allUsers: users,
      user: user,
    );
  }

  User user({
    required String id,
    String forname = 'Ann',
    String surname = 'Bee',
    String authID = '',
  }) {
    return User(id: id, forname: forname, surname: surname, authID: authID);
  }

  EventHead head(String id) => EventHead(id: id, title: id);

  group('AppContext', () {
    test('instances do not share user or head lists', () {
      final first = context();
      final second = context();

      first.addOrUpdateUser(user(id: 'u1'));
      first.addOrUpdatePostHead(head('h1'));

      expect(first.allUsers, hasLength(1));
      expect(first.eventHeads, hasLength(1));
      expect(second.allUsers, isEmpty);
      expect(second.eventHeads, isEmpty);
    });

    test('allUsers and eventHeads reject external mutation', () {
      final ctx = context(
        users: [user(id: 'u1')],
        heads: [head('h1')],
      );

      expect(() => ctx.allUsers.add(user(id: 'u2')), throwsUnsupportedError);
      expect(() => ctx.eventHeads.add(head('h2')), throwsUnsupportedError);
    });

    test('setAllUsers replaces and sorts by surname then forename', () {
      final ctx = context();
      ctx.setAllUsers([
        user(id: '2', forname: 'Zed', surname: 'Young'),
        user(id: '1', forname: 'Ann', surname: 'Able'),
        user(id: '3', forname: 'Bob', surname: 'Able'),
      ]);

      expect(ctx.allUsers.map((u) => u.id).toList(), ['1', '3', '2']);
    });

    test('addOrUpdateUser upserts without duplicating', () {
      final ctx = context(users: [user(id: 'u1', forname: 'Old')]);
      ctx.addOrUpdateUser(user(id: 'u1', forname: 'New'));
      ctx.addOrUpdateUser(user(id: 'u2'));

      expect(ctx.allUsers, hasLength(2));
      expect(ctx.userById('u1')?.forname, 'New');
    });

    test('userById and headById return null when missing', () {
      final ctx = context();
      expect(ctx.userById('missing'), isNull);
      expect(ctx.headById('missing'), isNull);
    });

    test('setAllEventHeads and addOrUpdatePostHead replace by id', () {
      final ctx = context(heads: [head('a'), head('b')]);
      ctx.setAllEventHeads([head('c')]);
      expect(ctx.eventHeads.map((h) => h.id).toList(), ['c']);
      expect(ctx.headById('a'), isNull);
      expect(ctx.headById('c'), isNotNull);

      final updated = EventHead(id: 'c', title: 'Updated');
      ctx.addOrUpdatePostHead(updated);
      expect(ctx.eventHeads, hasLength(1));
      expect(ctx.headById('c')?.title, 'Updated');
    });

    test('upgradeToAuthenticatedUser replaces lists and current user', () {
      final ctx = context(
        users: [user(id: 'old')],
        heads: [head('old-head')],
      );
      final signedIn = user(id: 'me', forname: 'Pat');
      ctx.upgradeToAuthenticatedUser(
        user: signedIn,
        heads: [head('new-head')],
        allUsers: [signedIn],
      );

      expect(ctx.currentUser.id, 'me');
      expect(ctx.isCurrentUserGuest, isFalse);
      expect(ctx.allUsers.map((u) => u.id).toList(), ['me']);
      expect(ctx.eventHeads.map((h) => h.id).toList(), ['new-head']);
    });

    test('mutations notify listeners', () {
      final ctx = context();
      var notifications = 0;
      ctx.addListener(() => notifications++);

      ctx.setAllUsers([user(id: 'u1')]);
      ctx.addOrUpdateUser(user(id: 'u2'));
      ctx.setAllEventHeads([head('h1')]);
      ctx.addOrUpdatePostHead(head('h2'));
      ctx.setCurrentUser(user(id: 'me'));
      ctx.setUserToGuest();

      expect(notifications, 6);
    });

    test('getTokensFromUserID is empty when missing', () {
      final ctx = context();
      expect(ctx.haveTokensForUserID('u1'), isFalse);
      expect(ctx.getTokensFromUserID('u1'), isEmpty);

      ctx.addTokensToUserID('u1', ['tok']);
      expect(ctx.getTokensFromUserID('u1'), ['tok']);
    });

    test('authIdByUserId is null when the user is missing', () {
      final ctx = context(users: [user(id: 'u1', authID: 'auth-1')]);
      expect(ctx.authIdByUserId('u1'), 'auth-1');
      expect(ctx.authIdByUserId('missing'), isNull);
    });

    test('epochs bump only the mutated slice', () {
      final ctx = context();
      expect(ctx.sessionEpoch, 0);
      expect(ctx.usersEpoch, 0);
      expect(ctx.headsEpoch, 0);
      expect(ctx.catalogsEpoch, 0);

      ctx.setAllTags([
        UserTag(id: 't1', name: 'Leader'),
      ]);
      expect(ctx.catalogsEpoch, 1);
      expect(ctx.headsEpoch, 0);
      expect(ctx.usersEpoch, 0);
      expect(ctx.sessionEpoch, 0);

      ctx.setAllEventHeads([head('h1')]);
      expect(ctx.headsEpoch, 1);
      expect(ctx.catalogsEpoch, 1);
      expect(ctx.usersEpoch, 0);

      ctx.setAllUsers([user(id: 'u1')]);
      expect(ctx.usersEpoch, 1);
      expect(ctx.headsEpoch, 1);
      expect(ctx.sessionEpoch, 0);

      ctx.setCurrentUser(user(id: 'me'));
      expect(ctx.sessionEpoch, 1);
      expect(ctx.usersEpoch, 1);
      expect(ctx.headsEpoch, 1);
      expect(ctx.catalogsEpoch, 1);
    });
  });
}
