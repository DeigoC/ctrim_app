import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/placeholder_user_permissions.dart';

void main() {
  group('placeholder_user_permissions', () {
    final admin = User(id: '1', forname: 'Ada', surname: 'Admin', isAreaAdmin: true);
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
    });

    group('canEditPlaceholderProfile', () {
      test('allows admin for anyone', () {
        expect(canEditPlaceholderProfile(actor: admin, target: placeholder), isTrue);
        expect(canEditPlaceholderProfile(actor: admin, target: linked), isTrue);
      });

      test('allows creator only while still a placeholder', () {
        expect(canEditPlaceholderProfile(actor: author, target: placeholder), isTrue);
        expect(canEditPlaceholderProfile(actor: author, target: linked), isFalse);
      });

      test('denies other users', () {
        expect(canEditPlaceholderProfile(actor: other, target: placeholder), isFalse);
      });
    });

    group('canLinkPlaceholderAuth', () {
      test('allows admin always', () {
        expect(canLinkPlaceholderAuth(actor: admin, target: placeholder), isTrue);
        expect(canLinkPlaceholderAuth(actor: admin, target: linked), isTrue);
      });

      test('allows creator only for unlinked placeholder', () {
        expect(canLinkPlaceholderAuth(actor: author, target: placeholder), isTrue);
        expect(canLinkPlaceholderAuth(actor: author, target: linked), isFalse);
      });

      test('denies other users', () {
        expect(canLinkPlaceholderAuth(actor: other, target: placeholder), isFalse);
      });
    });

    group('canUnlinkUserAuth', () {
      test('admin only', () {
        expect(canUnlinkUserAuth(actor: admin), isTrue);
        expect(canUnlinkUserAuth(actor: author), isFalse);
      });
    });
  });
}
