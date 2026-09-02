import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/placeholder_user_permissions.dart';

void main() {
  group('placeholder_user_permissions', () {
    final admin =
        User(id: '1', forname: 'Ada', surname: 'Admin', isAreaAdmin: true);
    final author = User(id: '2', forname: 'Pat', surname: 'Author');
    final other = User(id: '3', forname: 'Oli', surname: 'Other');
    final placeholder = User(
      id: '9',
      forname: 'Temp',
      surname: 'Person',
      isPlaceholder: true,
      createdByUserID: '2',
    );
    final linked = User(
      id: '10',
      forname: 'Was',
      surname: 'Temp',
      authID: 'auth-1',
      isPlaceholder: false,
      createdByUserID: '2',
    );

    group('canCreatePlaceholderUser', () {
      test('allows area admin', () {
        expect(canCreatePlaceholderUser(actor: admin), isTrue);
      });

      test('allows post author', () {
        expect(
          canCreatePlaceholderUser(actor: author, postAuthorUid: '2'),
          isTrue,
        );
      });

      test('denies non-author non-admin', () {
        expect(
          canCreatePlaceholderUser(actor: other, postAuthorUid: '2'),
          isFalse,
        );
      });

      test('denies without post author when not admin', () {
        expect(canCreatePlaceholderUser(actor: author), isFalse);
      });

      test('allows cell group leader flag', () {
        expect(
          canCreatePlaceholderUser(actor: other, isCellGroupLeader: true),
          isTrue,
        );
      });
    });

    group('canEditPlaceholderProfile', () {
      test('allows admin for anyone', () {
        expect(canEditPlaceholderProfile(actor: admin, target: placeholder),
            isTrue);
        expect(canEditPlaceholderProfile(actor: admin, target: linked), isTrue);
      });

      test('allows creator only while still a placeholder', () {
        expect(canEditPlaceholderProfile(actor: author, target: placeholder),
            isTrue);
        expect(
            canEditPlaceholderProfile(actor: author, target: linked), isFalse);
      });

      test('denies other users', () {
        expect(canEditPlaceholderProfile(actor: other, target: placeholder),
            isFalse);
      });
    });

    group('canLinkPlaceholderAuth', () {
      test('allows admin always', () {
        expect(
            canLinkPlaceholderAuth(actor: admin, target: placeholder), isTrue);
        expect(canLinkPlaceholderAuth(actor: admin, target: linked), isTrue);
      });

      test('allows creator only for unlinked placeholder', () {
        expect(
            canLinkPlaceholderAuth(actor: author, target: placeholder), isTrue);
        expect(canLinkPlaceholderAuth(actor: author, target: linked), isFalse);
      });

      test('denies other users', () {
        expect(
            canLinkPlaceholderAuth(actor: other, target: placeholder), isFalse);
      });
    });

    group('canUnlinkUserAuth', () {
      test('admin only', () {
        expect(canUnlinkUserAuth(actor: admin), isTrue);
        expect(canUnlinkUserAuth(actor: author), isFalse);
      });
    });

    group('isTransientVolunteerPlaceholder', () {
      test('true only for placeholders with a creator', () {
        expect(isTransientVolunteerPlaceholder(placeholder), isTrue);
        expect(
          isTransientVolunteerPlaceholder(
            User(
              id: '11',
              forname: 'Legacy',
              surname: 'Unlinked',
              isPlaceholder: true,
              createdByUserID: '',
            ),
          ),
          isFalse,
        );
        expect(isTransientVolunteerPlaceholder(linked), isFalse);
        expect(isTransientVolunteerPlaceholder(author), isFalse);
      });
    });

    group('isVisibleInVolunteerDirectory', () {
      final legacyUnlinked = User(
        id: '11',
        forname: 'Legacy',
        surname: 'Unlinked',
        isPlaceholder: true,
        createdByUserID: '',
      );

      test('always shows linked / non-placeholder profiles', () {
        expect(
          isVisibleInVolunteerDirectory(
            user: author,
            viewer: other,
            placeholdersOnly: false,
          ),
          isTrue,
        );
        expect(
          isVisibleInVolunteerDirectory(
            user: linked,
            viewer: other,
            placeholdersOnly: false,
          ),
          isTrue,
        );
      });

      test('hides all placeholders unless the filter is on', () {
        expect(
          isVisibleInVolunteerDirectory(
            user: placeholder,
            viewer: admin,
            placeholdersOnly: false,
          ),
          isFalse,
        );
        expect(
          isVisibleInVolunteerDirectory(
            user: legacyUnlinked,
            viewer: admin,
            placeholdersOnly: false,
          ),
          isFalse,
        );
        expect(
          isVisibleInVolunteerDirectory(
            user: placeholder,
            viewer: admin,
            placeholdersOnly: true,
          ),
          isTrue,
        );
      });

      test('placeholders filter hides linked / non-placeholder profiles', () {
        expect(
          isVisibleInVolunteerDirectory(
            user: author,
            viewer: admin,
            placeholdersOnly: true,
          ),
          isFalse,
        );
        expect(
          isVisibleInVolunteerDirectory(
            user: linked,
            viewer: admin,
            placeholdersOnly: true,
          ),
          isFalse,
        );
      });

      test('non-admin only sees own minted placeholders when filter is on', () {
        expect(
          isVisibleInVolunteerDirectory(
            user: placeholder,
            viewer: author,
            placeholdersOnly: true,
          ),
          isTrue,
        );
        expect(
          isVisibleInVolunteerDirectory(
            user: placeholder,
            viewer: other,
            placeholdersOnly: true,
          ),
          isFalse,
        );
        // Legacy backfill rows have no creator — area admin only.
        expect(
          isVisibleInVolunteerDirectory(
            user: legacyUnlinked,
            viewer: author,
            placeholdersOnly: true,
          ),
          isFalse,
        );
        expect(
          isVisibleInVolunteerDirectory(
            user: legacyUnlinked,
            viewer: admin,
            placeholdersOnly: true,
          ),
          isTrue,
        );
      });
    });

    group('inactive profile visibility', () {
      final admin =
          User(id: '1', forname: 'Ada', surname: 'Admin', isAreaAdmin: true);
      final active =
          User(id: '2', forname: 'Pat', surname: 'Active', status: UserStatus.active);
      final hidden = User(
        id: '3',
        forname: 'Hid',
        surname: 'Den',
        status: UserStatus.hidden,
      );

      test('hides inactive profiles unless showInactive for area admin', () {
        expect(
          isVisibleInVolunteerDirectory(
            user: hidden,
            viewer: admin,
            placeholdersOnly: false,
            showInactive: false,
          ),
          isFalse,
        );
        expect(
          isVisibleInVolunteerDirectory(
            user: hidden,
            viewer: admin,
            placeholdersOnly: false,
            showInactive: true,
          ),
          isTrue,
        );
        expect(
          isVisibleInVolunteerDirectory(
            user: hidden,
            viewer: active,
            placeholdersOnly: false,
            showInactive: true,
          ),
          isFalse,
        );
      });

      test('canSignInWithVolunteerProfile requires active status', () {
        expect(canSignInWithVolunteerProfile(active), isTrue);
        expect(canSignInWithVolunteerProfile(hidden), isFalse);
        expect(
          canSignInWithVolunteerProfile(
            User(id: '4', forname: 'A', surname: 'B', status: UserStatus.archived),
          ),
          isFalse,
        );
      });

      test('isSelectableVolunteerProfile matches sign-in rule', () {
        expect(isSelectableVolunteerProfile(active), isTrue);
        expect(isSelectableVolunteerProfile(hidden), isFalse);
      });
    });
  });
}
