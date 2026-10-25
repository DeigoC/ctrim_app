import 'package:ctrim_app/models/shared_media_folders.dart';
import 'package:ctrim_app/pages/events/add_media_drive_helpers.dart';
import 'package:ctrim_app/pages/events/bulk_add_media_page.dart';
import 'package:ctrim_app/utility/drive_folder_listing.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _currentId = 'currentfolderid0000000000001';
const _previousId = 'previousfolderid000000000001';
const _cellId = 'cellgroupfolderid000000000001';

void main() {
  testWidgets('shows This month, Drive folder, and Paste URLs tabs',
      (tester) async {
    final eventContext = EventContext.adding(currentUserID: 'author-1');

    await tester.pumpWidget(
      MaterialApp(
        home: BulkAddMediaPage(
          eventContext: eventContext,
          folders: SharedMediaFolders.empty,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Bulk add media'), findsOneWidget);
    expect(find.text('This month'), findsWidgets);
    expect(find.text('Drive folder'), findsOneWidget);
    expect(find.text('Paste URLs'), findsOneWidget);
    expect(
      find.textContaining('This month’s Services folder isn’t set yet'),
      findsOneWidget,
    );
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Cell Groups'), findsOneWidget);

    await tester.tap(find.text('Drive folder'));
    await tester.pumpAndSettle();
    expect(find.text('List files'), findsOneWidget);

    await tester.tap(find.text('Paste URLs'));
    await tester.pumpAndSettle();
    expect(find.text('Review links'), findsOneWidget);
  });

  testWidgets('month tab lists loose images and can switch to last month',
      (tester) async {
    final listing = _ScriptedListing({
      _currentId: const [
        DriveFolderEntry(
          id: 'imagefileid00000000000000001',
          name: 'welcome.jpg',
          mimeType: 'image/jpeg',
          isFolder: false,
        ),
        DriveFolderEntry(
          id: 'subfolderid00000000000000001',
          name: 'Sunday service',
          mimeType: 'application/vnd.google-apps.folder',
          isFolder: true,
        ),
      ],
      _previousId: const [
        DriveFolderEntry(
          id: 'previmageid00000000000000001',
          name: 'prayer.jpg',
          mimeType: 'image/jpeg',
          isFolder: false,
        ),
      ],
      _cellId: const [
        DriveFolderEntry(
          id: 'cellimageid000000000000000001',
          name: 'meeting.jpg',
          mimeType: 'image/jpeg',
          isFolder: false,
        ),
      ],
    });
    final eventContext = EventContext.adding(currentUserID: 'author-1');

    await tester.pumpWidget(
      MaterialApp(
        home: BulkAddMediaPage(
          eventContext: eventContext,
          listing: listing,
          folders: SharedMediaFolders(
            service: SharedMediaFolderPair(
              currentLabel: 'October 2026',
              currentFolderUrl:
                  'https://drive.google.com/drive/folders/$_currentId',
              previousLabel: 'September 2026',
              previousFolderUrl:
                  'https://drive.google.com/drive/folders/$_previousId',
            ),
            cellGroup: SharedMediaFolderPair(
              currentLabel: 'October meetings',
              currentFolderUrl:
                  'https://drive.google.com/drive/folders/$_cellId',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(listing.requested, [_currentId]);
    expect(find.byTooltip('welcome.jpg'), findsOneWidget);
    expect(find.text('welcome.jpg'), findsNothing);
    expect(find.byTooltip('Show file names'), findsOneWidget);

    await tester.tap(find.byTooltip('Show file names'));
    await tester.pump();
    expect(find.text('welcome.jpg'), findsOneWidget);

    await tester.tap(find.byTooltip('Show as photos'));
    await tester.pump();
    expect(find.text('welcome.jpg'), findsNothing);
    expect(find.text('0 of 1 selected'), findsOneWidget);
    expect(find.text('Sunday service'), findsNothing);
    expect(
      find.textContaining('Bulk add from a folder'),
      findsOneWidget,
    );

    await tester.tap(find.text('September 2026'));
    await tester.pump();
    await tester.pump();

    expect(listing.requested, [_currentId, _previousId]);
    expect(find.byTooltip('prayer.jpg'), findsOneWidget);
    expect(find.byTooltip('welcome.jpg'), findsNothing);
    expect(find.text('0 of 1 selected'), findsOneWidget);

    await tester.tap(find.text('Cell Groups'));
    await tester.pump();
    await tester.pump();

    expect(listing.requested, [_currentId, _previousId, _cellId]);
    expect(find.byTooltip('meeting.jpg'), findsOneWidget);
    expect(find.byTooltip('prayer.jpg'), findsNothing);
    expect(find.text('0 of 1 selected'), findsOneWidget);
  });

  testWidgets('a cell group post opens on the Cell Groups folder',
      (tester) async {
    final listing = _ScriptedListing({
      _currentId: const [
        DriveFolderEntry(
          id: 'imagefileid00000000000000001',
          name: 'welcome.jpg',
          mimeType: 'image/jpeg',
          isFolder: false,
        ),
      ],
      _cellId: const [
        DriveFolderEntry(
          id: 'cellimageid000000000000000001',
          name: 'meeting.jpg',
          mimeType: 'image/jpeg',
          isFolder: false,
        ),
      ],
    });
    final eventContext = EventContext.adding(currentUserID: 'author-1')
      ..applyCellGroupIDs(['group-1']);

    await tester.pumpWidget(
      MaterialApp(
        home: BulkAddMediaPage(
          eventContext: eventContext,
          listing: listing,
          folders: SharedMediaFolders(
            service: SharedMediaFolderPair(
              currentLabel: 'October 2026',
              currentFolderUrl:
                  'https://drive.google.com/drive/folders/$_currentId',
            ),
            cellGroup: SharedMediaFolderPair(
              currentLabel: 'October meetings',
              currentFolderUrl:
                  'https://drive.google.com/drive/folders/$_cellId',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(listing.requested, [_cellId]);
    expect(find.byTooltip('meeting.jpg'), findsOneWidget);
    expect(find.byTooltip('welcome.jpg'), findsNothing);
  });
}

class _ScriptedListing extends DriveFolderListing {
  _ScriptedListing(this.pages);

  final Map<String, List<DriveFolderEntry>> pages;
  final List<String> requested = [];

  @override
  Future<List<DriveFolderEntry>> listPublicFolder(String folderId) async {
    requested.add(folderId);
    return pages[folderId] ?? const [];
  }
}
