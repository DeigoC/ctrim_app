import 'package:ctrim_app/models/post_template.dart';
import 'package:ctrim_app/widgets/posts/template_category_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('count label uses singular and empty wording', () {
    expect(TemplateCategorySection.countLabel(0), 'No templates');
    expect(TemplateCategorySection.countLabel(1), '1 template');
    expect(TemplateCategorySection.countLabel(12), '12 templates');
  });

  testWidgets('starts closed and reveals templates when the kind is opened',
      (tester) async {
    var expanded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return TemplateCategorySection(
                category: PostTemplateCategory.cellGroup,
                templateCount: 2,
                expanded: expanded,
                onToggle: () => setState(() => expanded = !expanded),
                child: const Text('Tuesday cell'),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Cell Groups'), findsOneWidget);
    expect(find.text('2 templates'), findsOneWidget);
    expect(find.text('Tuesday cell'), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);

    await tester.tap(find.text('Cell Groups'));
    await tester.pumpAndSettle();

    expect(find.text('Tuesday cell'), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    await tester.tap(find.text('Cell Groups'));
    await tester.pumpAndSettle();

    expect(find.text('Tuesday cell'), findsNothing);
  });
}
