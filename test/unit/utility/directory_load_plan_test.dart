import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/utility/cache/directory_load_plan.dart';

void main() {
  group('planDirectoryLoad', () {
    test('downloads when the caller forces a refresh', () {
      expect(
        planDirectoryLoad(
          forceRefresh: true,
          hasCachedRecords: true,
          sessionValidated: true,
        ),
        DirectoryLoadPlan.download,
      );
    });

    test('downloads when nothing is cached', () {
      expect(
        planDirectoryLoad(
          forceRefresh: false,
          hasCachedRecords: false,
          sessionValidated: false,
        ),
        DirectoryLoadPlan.download,
      );
    });

    test('paints local data and revalidates before the session check', () {
      expect(
        planDirectoryLoad(
          forceRefresh: false,
          hasCachedRecords: true,
          sessionValidated: false,
        ),
        DirectoryLoadPlan.useLocalThenRevalidate,
      );
    });

    test('uses local data after this session has checked the watermark', () {
      expect(
        planDirectoryLoad(
          forceRefresh: false,
          hasCachedRecords: true,
          sessionValidated: true,
        ),
        DirectoryLoadPlan.useLocal,
      );
    });
  });
}
