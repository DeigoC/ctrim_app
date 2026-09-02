import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/cache/users_local_cache.dart';

void main() {
  group('effectiveIsPlaceholder', () {
    test('linked Auth clears placeholder even when flag is stale true', () {
      expect(
        effectiveIsPlaceholder(authID: 'auth-1', fallbackIsPlaceholder: true),
        isFalse,
      );
    });

    test('empty Auth keeps fallback flag', () {
      expect(
        effectiveIsPlaceholder(authID: '', fallbackIsPlaceholder: true),
        isTrue,
      );
      expect(
        effectiveIsPlaceholder(authID: '  ', fallbackIsPlaceholder: true),
        isTrue,
      );
      expect(
        effectiveIsPlaceholder(authID: '', fallbackIsPlaceholder: false),
        isFalse,
      );
    });
  });

  group('UsersLocalCache', () {
    final sample = User(
      id: '7',
      forname: 'Ada',
      surname: 'Lovelace',
      imgSrc: 'https://example.com/a.png',
      isLeader: true,
      isAreaAdmin: true,
      location: 'Belfast',
      authID: 'auth-ada',
      tagIDs: const ['t1', 't2'],
      isPlaceholder: false,
      createdByUserID: '1',
    );

    test('round-trips v4 encode/decode including profile status', () {
      final hidden = User(
        id: '8',
        forname: 'Hidden',
        surname: 'User',
        status: UserStatus.hidden,
      );
      final encoded = UsersLocalCache.encode(
        lastUpdate: 100,
        appVersion: '1.2.4',
        users: [hidden],
      );
      final decoded =
          UsersLocalCache.decodeBody(encoded.split('\n').sublist(1));
      expect(decoded, isNotNull);
      expect(decoded!.single.status, UserStatus.hidden);
    });

    test('round-trips v3 encode/decode including admin and placeholder', () {
      final encoded = UsersLocalCache.encode(
        lastUpdate: 99,
        appVersion: '1.2.3',
        users: [sample],
      );
      final lines = encoded.split('\n');
      expect(lines.first, '99-1.2.3');
      final decoded = UsersLocalCache.decodeBody(lines.sublist(1));
      expect(decoded, isNotNull);
      expect(decoded!, hasLength(1));
      final u = decoded.first;
      expect(u.id, '7');
      expect(u.isAreaAdmin, isTrue);
      expect(u.isLeader, isTrue);
      expect(u.authID, 'auth-ada');
      expect(u.isPlaceholder, isFalse);
      expect(u.createdByUserID, '1');
      expect(u.tagIDs, ['t1', 't2']);
    });

    test('legacy v2 body treats empty AuthID as placeholder', () {
      final body = [
        '3',
        'Temp',
        'User',
        '',
        '0',
        '0',
        'Belfast',
        '',
        'tag-a',
      ];
      final decoded = UsersLocalCache.decodeBody(body);
      expect(decoded, isNotNull);
      expect(decoded!.first.isPlaceholder, isTrue);
      expect(decoded.first.isAreaAdmin, isFalse);
      expect(decoded.first.authID, isEmpty);
    });

    test('legacy v2 body with AuthID is not placeholder', () {
      final body = [
        '4',
        'Real',
        'User',
        '',
        '0',
        '1',
        'Belfast',
        'auth-x',
        '',
      ];
      final decoded = UsersLocalCache.decodeBody(body);
      expect(decoded!.first.isPlaceholder, isFalse);
      expect(decoded.first.isAreaAdmin, isTrue);
    });

    test('mismatched length returns null', () {
      expect(UsersLocalCache.decodeBody(['a', 'b', 'c']), isNull);
    });

    test('scrambled rows with a Drive URL as location return null', () {
      final body = [
        'Belfast',
        '0',
        '',
        '',
        '1',
        '0',
        'https://drive.google.com/uc?id=abc',
        'auth-1',
        '',
        '0',
        '',
      ];
      expect(UsersLocalCache.decodeBody(body), isNull);
      expect(
        UsersLocalCache.looksScrambled([
          User(
            id: 'Belfast',
            forname: '0',
            surname: '',
            location: 'https://drive.google.com/uc?id=abc',
            authID: 'auth-1',
          ),
        ]),
        isTrue,
      );
    });

    test('v1 body whose length is also divisible by 11 still decodes as v1',
        () {
      // 11 v1 records = 88 lines, which is also 8 × v3. Prefer the layout
      // that does not look scrambled.
      final one = [
        '7',
        'Ada',
        'Lovelace',
        '',
        '0',
        '0',
        'Belfast',
        'auth-ada',
      ];
      final body = [for (var i = 0; i < 11; i++) ...one];
      expect(body.length, 88);
      expect(body.length % UsersLocalCache.chunkSizeV3, 0);
      expect(body.length % UsersLocalCache.chunkSizeV1, 0);

      final decoded = UsersLocalCache.decodeBody(body);
      expect(decoded, isNotNull);
      expect(decoded, hasLength(11));
      expect(decoded!.first.id, '7');
      expect(decoded.first.forname, 'Ada');
      expect(decoded.first.location, 'Belfast');
      expect(decoded.first.authID, 'auth-ada');
    });
  });
}
