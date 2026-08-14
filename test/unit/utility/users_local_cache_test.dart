import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/users_local_cache.dart';

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
  });
}
