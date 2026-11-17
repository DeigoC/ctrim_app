import 'dart:async';

import 'package:ctrim_app/utility/startup_load.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Report = ({
  int completed,
  int total,
  StartupLoadStep step,
});

void main() {
  group('EssentialStartupLoader', () {
    test('advances as each parallel step finishes', () async {
      final catalogs = Completer<void>();
      final posts = Completer<void>();
      final people = Completer<void>();
      final reports = <_Report>[];

      final done = EssentialStartupLoader(
        loadCatalogs: () => catalogs.future,
        loadPosts: () => posts.future,
        loadPeople: () => people.future,
      ).run(onProgress: ({
        required int completed,
        required int total,
        required StartupLoadStep step,
      }) {
        reports.add((completed: completed, total: total, step: step));
      });

      await pumpEventQueue();
      expect(reports, [
        (completed: 0, total: 3, step: StartupLoadStep.opening),
      ]);

      people.complete();
      await pumpEventQueue();
      expect(reports.last, (
        completed: 1,
        total: 3,
        step: StartupLoadStep.people,
      ));

      catalogs.complete();
      await pumpEventQueue();
      expect(reports.last.step, StartupLoadStep.catalogs);
      expect(reports.last.completed, 2);

      posts.complete();
      await done;
      expect(reports.last, (
        completed: 3,
        total: 3,
        step: StartupLoadStep.posts,
      ));
    });

    test('a failed step still fills the bar and the load finishes', () async {
      final reports = <_Report>[];

      await EssentialStartupLoader(
        loadCatalogs: () async {},
        loadPosts: () async {
          throw StateError('offline');
        },
        loadPeople: () async {},
      ).run(onProgress: ({
        required int completed,
        required int total,
        required StartupLoadStep step,
      }) {
        reports.add((completed: completed, total: total, step: step));
      });

      expect(reports.first.step, StartupLoadStep.opening);
      expect(reports.last.completed, 3);
      expect(reports.last.total, 3);
      expect(
        reports.map((report) => report.step),
        contains(StartupLoadStep.posts),
      );
    });

    test('sign-in is the last step when stored credentials exist', () async {
      final catalogs = Completer<void>();
      final posts = Completer<void>();
      final people = Completer<void>();
      final signIn = Completer<void>();
      final reports = <_Report>[];
      var signInStarted = false;

      final done = EssentialStartupLoader(
        loadCatalogs: () => catalogs.future,
        loadPosts: () => posts.future,
        loadPeople: () => people.future,
        signIn: () {
          signInStarted = true;
          return signIn.future;
        },
      ).run(onProgress: ({
        required int completed,
        required int total,
        required StartupLoadStep step,
      }) {
        reports.add((completed: completed, total: total, step: step));
      });

      await pumpEventQueue();
      expect(reports.single.total, 4);
      expect(signInStarted, isFalse);

      catalogs.complete();
      posts.complete();
      people.complete();
      await pumpEventQueue();

      expect(signInStarted, isTrue);
      expect(reports.last, (
        completed: 3,
        total: 4,
        step: StartupLoadStep.signingIn,
      ));

      signIn.complete();
      await done;
      expect(reports.last, (
        completed: 4,
        total: 4,
        step: StartupLoadStep.signingIn,
      ));
    });
  });
}
