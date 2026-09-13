import 'package:ctrim_app/widgets/quill_editor_wrapper.dart';
import 'package:ctrim_app/widgets/quill_image_embed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(final Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('viewer renders an image embed without throwing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        QuillViewerWidget(
          jsonContent: [
            {'insert': 'Caption\n'},
            {
              'insert': {'image': 'https://example.com/a.png'}
            },
            {'insert': '\n'},
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(QuillNetworkImage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor image button inserts a Drive share URL as uc?id=',
      (tester) async {
    final editorKey = GlobalKey<QuillEditorWidgetState>();
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          height: 640,
          child: QuillEditorWidget(
            key: editorKey,
            jsonContent: [
              {'insert': '\n'}
            ],
            expands: false,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Insert image from URL'));
    await tester.pumpAndSettle();

    expect(find.text('Insert image'), findsOneWidget);
    expect(find.textContaining('Gallery'), findsNothing);
    expect(find.textContaining('Camera'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('quill-image-url-field')),
      'https://drive.google.com/file/d/1abcXYZ/view?usp=sharing',
    );
    await tester.pump();
    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();

    final json = editorKey.currentState!.getDocumentJson();
    final imageOp = json.cast<dynamic>().firstWhere(
          (op) => op is Map && op['insert'] is Map,
        ) as Map;
    expect(
      (imageOp['insert'] as Map)['image'],
      'https://drive.google.com/uc?id=1abcXYZ',
    );
  });
}
