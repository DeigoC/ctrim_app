import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/people_directory_query.dart';
import 'package:ctrim_app/utility/placeholder_user_permissions.dart';

void main() {
  group('isIncludedInUnfilteredPeopleSearch', () {
    final admin =
        User(id: '1', forname: 'Ada', surname: 'Admin', isAreaAdmin: true);
    final author = User(id: '2', forname: 'Pat', surname: 'Author');
    final other = User(id: '3', forname: 'Oli', surname: 'Other');

    test('includes active non-placeholders for anyone', () {
      final person = User(id: '10', forname: 'Sam', surname: 'Smith');
      expect(
        isIncludedInUnfilteredPeopleSearch(user: person, viewer: other),
        isTrue,
      );
    });

    test('includes own placeholders; hides others for non-admin', () {
      final own = User(
        id: '9',
        forname: 'Temp',
        surname: 'Person',
        isPlaceholder: true,
        createdByUserID: '2',
      );
      final theirs = User(
        id: '8',
        forname: 'Other',
        surname: 'Temp',
        isPlaceholder: true,
        createdByUserID: '1',
      );
      expect(
        isIncludedInUnfilteredPeopleSearch(user: own, viewer: author),
        isTrue,
      );
      expect(
        isIncludedInUnfilteredPeopleSearch(user: theirs, viewer: author),
        isFalse,
      );
      expect(
        isIncludedInUnfilteredPeopleSearch(
          user: theirs,
          viewer: author,
          leadsCellGroupContainingUser: true,
        ),
        isTrue,
      );
    });

    test('area admin sees all placeholders and inactive', () {
      final placeholder = User(
        id: '9',
        forname: 'Temp',
        surname: 'Person',
        isPlaceholder: true,
        createdByUserID: '2',
      );
      final hidden = User(
        id: '11',
        forname: 'Hid',
        surname: 'Den',
        status: UserStatus.hidden,
      );
      expect(
        isIncludedInUnfilteredPeopleSearch(user: placeholder, viewer: admin),
        isTrue,
      );
      expect(
        isIncludedInUnfilteredPeopleSearch(user: hidden, viewer: admin),
        isTrue,
      );
      expect(
        isIncludedInUnfilteredPeopleSearch(user: hidden, viewer: author),
        isFalse,
      );
    });
  });

  group('PeopleDirectoryQuery.searchWithoutRefineFilters', () {
    final viewer = User(id: 'v', forname: 'Vie', surname: 'Wer');

    test('returns empty for blank query', () {
      expect(
        PeopleDirectoryQuery.searchWithoutRefineFilters(
          allUsers: [
            User(id: '1', forname: 'Sam', surname: 'Smith'),
          ],
          viewer: viewer,
          searchQuery: '  ',
        ),
        isEmpty,
      );
    });

    test('matches by name across locations and includes placeholders', () {
      final users = [
        User(
          id: '1',
          forname: 'Sam',
          surname: 'Smith',
          location: 'Portadown',
        ),
        User(
          id: '2',
          forname: 'Sam',
          surname: 'Jones',
          location: 'Belfast',
          isPlaceholder: true,
          createdByUserID: 'v',
        ),
        User(
          id: '3',
          forname: 'Alex',
          surname: 'Other',
          location: 'Belfast',
        ),
      ];

      final matches = PeopleDirectoryQuery.searchWithoutRefineFilters(
        allUsers: users,
        viewer: viewer,
        searchQuery: 'sam',
      );

      expect(matches.map((u) => u.id), ['2', '1']);
    });

    test('includes placeholders on a cell group the viewer leads', () {
      final users = [
        User(
          id: '8',
          forname: 'Sam',
          surname: 'Member',
          isPlaceholder: true,
          createdByUserID: 'other',
        ),
      ];

      final matches = PeopleDirectoryQuery.searchWithoutRefineFilters(
        allUsers: users,
        viewer: viewer,
        searchQuery: 'sam',
        cellGroupMemberIdsLedByViewer: {'8'},
      );

      expect(matches.map((u) => u.id), ['8']);
    });
  });

  group('PeopleDirectoryQuery.matchesShowFilter', () {
    final member = User(id: '1', forname: 'Ann', surname: 'Member');
    final server =
        User(id: '2', forname: 'Ben', surname: 'Server', isLeader: true);
    final placeholder = User(
      id: '3',
      forname: 'Cara',
      surname: 'Place',
      isPlaceholder: true,
    );
    final servingPlaceholder = User(
      id: '4',
      forname: 'Dan',
      surname: 'Both',
      isPlaceholder: true,
      isLeader: true,
    );

    bool shown(
      User user, {
      required bool servingOnly,
      required bool placeholdersOnly,
      required bool userServes,
    }) {
      return PeopleDirectoryQuery.matchesShowFilter(
        user: user,
        servingOnly: servingOnly,
        placeholdersOnly: placeholdersOnly,
        userServes: userServes,
      );
    }

    test('everyone keeps members, serving people, and placeholders', () {
      for (final user in [member, server, placeholder, servingPlaceholder]) {
        expect(
          shown(user,
              servingOnly: false, placeholdersOnly: false, userServes: false),
          isTrue,
        );
      }
    });

    test('serving alone keeps people who serve', () {
      expect(
        shown(server,
            servingOnly: true, placeholdersOnly: false, userServes: true),
        isTrue,
      );
      expect(
        shown(
          servingPlaceholder,
          servingOnly: true,
          placeholdersOnly: false,
          userServes: true,
        ),
        isTrue,
      );
      expect(
        shown(member,
            servingOnly: true, placeholdersOnly: false, userServes: false),
        isFalse,
      );
      expect(
        shown(
          placeholder,
          servingOnly: true,
          placeholdersOnly: false,
          userServes: false,
        ),
        isFalse,
      );
    });

    test('placeholders alone keeps placeholder profiles', () {
      expect(
        shown(
          placeholder,
          servingOnly: false,
          placeholdersOnly: true,
          userServes: false,
        ),
        isTrue,
      );
      expect(
        shown(member,
            servingOnly: false, placeholdersOnly: true, userServes: false),
        isFalse,
      );
      expect(
        shown(server,
            servingOnly: false, placeholdersOnly: true, userServes: true),
        isFalse,
      );
    });

    test('serving and placeholders together keep both groups', () {
      expect(
        shown(server,
            servingOnly: true, placeholdersOnly: true, userServes: true),
        isTrue,
      );
      expect(
        shown(
          placeholder,
          servingOnly: true,
          placeholdersOnly: true,
          userServes: false,
        ),
        isTrue,
      );
      expect(
        shown(
          servingPlaceholder,
          servingOnly: true,
          placeholdersOnly: true,
          userServes: true,
        ),
        isTrue,
      );
      expect(
        shown(member,
            servingOnly: true, placeholdersOnly: true, userServes: false),
        isFalse,
      );
    });
  });
}
