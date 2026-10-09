import 'package:ctrim_app/pages/events/bulk_add_media_page.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows Drive folder and Paste URLs tabs', (tester) async {
    final eventContext = EventContext.adding(currentUserID: 'author-1');

    await tester.pumpWidget(
      MaterialApp(
        home: BulkAddMediaPage(eventContext: eventContext),
      ),
    );

    expect(find.text('Bulk add media'), findsOneWidget);
    expect(find.text('Drive folder'), findsOneWidget);
    expect(find.text('Paste URLs'), findsOneWidget);
    expect(find.text('List files'), findsOneWidget);

    await tester.tap(find.text('Paste URLs'));
    await tester.pumpAndSettle();
    expect(find.text('Review links'), findsOneWidget);
  });
}
