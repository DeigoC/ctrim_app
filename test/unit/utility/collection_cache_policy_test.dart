import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/utility/collection_cache_policy.dart';

void main() {
  group('shouldUseLocalCollectionCache', () {
    test('uses cache when lastUpdate matches and records exist', () {
      expect(
        shouldUseLocalCollectionCache(
          forceRefresh: false,
          hasCachedRecords: true,
          remoteLastUpdate: 100,
          localLastUpdate: 100,
        ),
        isTrue,
      );
    });

    test('skips cache when lastUpdate is unset on the server', () {
      expect(
        shouldUseLocalCollectionCache(
          forceRefresh: false,
          hasCachedRecords: true,
          remoteLastUpdate: 0,
          localLastUpdate: 0,
        ),
        isFalse,
      );
    });

    test('skips cache when watermarks differ', () {
      expect(
        shouldUseLocalCollectionCache(
          forceRefresh: false,
          hasCachedRecords: true,
          remoteLastUpdate: 200,
          localLastUpdate: 100,
        ),
        isFalse,
      );
    });

    test('skips cache when empty or force refresh', () {
      expect(
        shouldUseLocalCollectionCache(
          forceRefresh: true,
          hasCachedRecords: true,
          remoteLastUpdate: 100,
          localLastUpdate: 100,
        ),
        isFalse,
      );
      expect(
        shouldUseLocalCollectionCache(
          forceRefresh: false,
          hasCachedRecords: false,
          remoteLastUpdate: 100,
          localLastUpdate: 100,
        ),
        isFalse,
      );
    });

    test('skips cache when app version changed', () {
      expect(
        shouldUseLocalCollectionCache(
          forceRefresh: false,
          hasCachedRecords: true,
          remoteLastUpdate: 100,
          localLastUpdate: 100,
          cachedAppVersion: '1.0.0',
          currentAppVersion: '1.0.1',
        ),
        isFalse,
      );
    });

    test('uses cache when app versions match', () {
      expect(
        shouldUseLocalCollectionCache(
          forceRefresh: false,
          hasCachedRecords: true,
          remoteLastUpdate: 100,
          localLastUpdate: 100,
          cachedAppVersion: '1.0.1',
          currentAppVersion: '1.0.1',
        ),
        isTrue,
      );
    });
  });
}
