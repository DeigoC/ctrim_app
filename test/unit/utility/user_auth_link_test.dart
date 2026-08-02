import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/user_auth_link.dart';

void main() {
  group('validateAuthRelink', () {
    test('rejects empty auth id', () {
      expect(
        validateAuthRelink(
          targetAuthID: '',
          currentUserId: '1',
          existingOwner: null,
        ),
        'No account found for that email.',
      );
    });

    test('rejects auth already owned by another volunteer', () {
      final owner = User(id: '2', forname: 'Other', surname: 'Person', authID: 'auth-x');
      expect(
        validateAuthRelink(
          targetAuthID: 'auth-x',
          currentUserId: '1',
          existingOwner: owner,
        ),
        'That account is already linked to Other Person.',
      );
    });

    test('allows same volunteer keeping their auth', () {
      final owner = User(id: '1', forname: 'Same', surname: 'User', authID: 'auth-x');
      expect(
        validateAuthRelink(
          targetAuthID: 'auth-x',
          currentUserId: '1',
          existingOwner: owner,
        ),
        isNull,
      );
    });

    test('allows linking unused auth', () {
      expect(
        validateAuthRelink(
          targetAuthID: 'auth-new',
          currentUserId: '1',
          existingOwner: null,
        ),
        isNull,
      );
    });
  });
}
