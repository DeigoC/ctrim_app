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
  });
}
