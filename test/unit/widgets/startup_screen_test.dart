import 'dart:async';

import 'package:ctrim_app/utility/startup_load.dart';
import 'package:ctrim_app/widgets/startup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('covers the shell with a stepped bar, then reveals it',
      (tester) async {
    final release = Completer<void>();
    final reports = <StartupLoadStep>[];

    await tester.pumpWidget(
      MaterialApp(
        home: StartupGate(
          title: 'CTRIM',
          messageFor: (step) {
            switch (step) {
              case StartupLoadStep.opening:
                return 'Opening CTRIM…';
              case StartupLoadStep.posts:
                return 'Loading the bulletin…';
              case StartupLoadStep.catalogs:
                return 'Loading churches and groups…';
              case StartupLoadStep.people:
                return 'Loading people…';
              case StartupLoadStep.signingIn:
                return 'Signing in…';
            }
          },
          loadStartup: (onProgress) async {
            onProgress(
              completed: 1,
              total: 3,
              step: StartupLoadStep.posts,
            );
            reports.add(StartupLoadStep.posts);
            await release.future;
          },
          child: const Text('Bulletin'),
        ),
      ),
    );

    expect(find.text('CTRIM'), findsOneWidget);
    expect(find.text('Opening CTRIM…'), findsOneWidget);
    expect(find.text('Bulletin'), findsOneWidget);

    await tester.pump();
    expect(find.text('Loading the bulletin…'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(reports, [StartupLoadStep.posts]);

    expect(
      tester
          .widgetList<IgnorePointer>(
            find.ancestor(
              of: find.text('Bulletin'),
              matching: find.byType(IgnorePointer),
            ),
          )
          .any((pointer) => pointer.ignoring),
      isTrue,
    );

    release.complete();
    await tester.pump();
    await tester.pump();

    expect(find.text('CTRIM'), findsNothing);
    expect(find.text('Bulletin'), findsOneWidget);
    expect(
      tester
          .widgetList<IgnorePointer>(
            find.ancestor(
              of: find.text('Bulletin'),
              matching: find.byType(IgnorePointer),
            ),
          )
          .any((pointer) => pointer.ignoring),
      isFalse,
    );
  });

  testWidgets('still reveals the shell when startup throws', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StartupGate(
          title: 'CTRIM',
          messageFor: (_) => 'Opening CTRIM…',
          loadStartup: (onProgress) async {
            throw StateError('startup failed');
          },
          child: const Text('Bulletin'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('CTRIM'), findsNothing);
    expect(find.text('Bulletin'), findsOneWidget);
  });
}
