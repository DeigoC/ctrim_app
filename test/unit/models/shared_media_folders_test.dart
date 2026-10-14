import 'package:ctrim_app/models/shared_media_folders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const currentId = '1KpLl_1tcK0eeehzN980zbG-3M2nhbVks';
  const previousId = '2KpLl_1tcK0eeehzN980zbG-3M2nhbVks';
  const olderId = '3KpLl_1tcK0eeehzN980zbG-3M2nhbVks';
  const currentUrl = 'https://drive.google.com/drive/folders/$currentId';
  const previousUrl = 'https://drive.google.com/drive/folders/$previousId';
  const olderUrl = 'https://drive.google.com/drive/folders/$olderId';

  group('SharedMediaFolders', () {
    group('fromMap', () {
      test('reads this month and last month', () {
        final folders = SharedMediaFolders.fromMap({
          'CurrentLabel': 'October 2026',
          'CurrentFolderUrl': currentUrl,
          'PreviousLabel': 'September 2026',
          'PreviousFolderUrl': previousUrl,
        });

        expect(folders.current?.folderId, currentId);
        expect(folders.current?.displayLabel('This month'), 'October 2026');
        expect(folders.previous?.folderId, previousId);
        expect(folders.previous?.label, 'September 2026');
      });

      test('an empty document has no folders', () {
        final folders = SharedMediaFolders.fromMap(const {});

        expect(folders.current, isNull);
        expect(folders.previous, isNull);
        expect(folders.canStartNewMonth, isFalse);
      });
    });

    group('toJson', () {
      test('round-trips the four fields', () {
        final folders = SharedMediaFolders(
          currentLabel: 'October 2026',
          currentFolderUrl: currentUrl,
          previousLabel: 'September 2026',
          previousFolderUrl: previousUrl,
        );

        expect(SharedMediaFolders.fromMap(folders.toJson()).toJson(), {
          'CurrentLabel': 'October 2026',
          'CurrentFolderUrl': currentUrl,
          'PreviousLabel': 'September 2026',
          'PreviousFolderUrl': previousUrl,
        });
      });
    });

    group('startNewMonth', () {
      test('drops the month before last', () {
        final folders = SharedMediaFolders(
          currentLabel: 'October 2026',
          currentFolderUrl: currentUrl,
          previousLabel: 'September 2026',
          previousFolderUrl: previousUrl,
        );

        final next = folders.startNewMonth();

        expect(next.current, isNull);
        expect(next.currentLabel, isEmpty);
        expect(next.previous?.folderId, currentId);
        expect(next.previousLabel, 'October 2026');
        expect(next.previousFolderUrl, isNot(contains(olderId)));
        expect(next.toJson().values, isNot(contains(olderUrl)));
        expect(next.toJson().values, isNot(contains(previousUrl)));
      });
    });

    group('validateFolderUrl', () {
      test('accepts an empty value and a folder link', () {
        expect(SharedMediaFolders.validateFolderUrl(''), isNull);
        expect(SharedMediaFolders.validateFolderUrl(currentUrl), isNull);
        expect(SharedMediaFolders.validateFolderUrl(currentId), isNull);
      });

      test('rejects a file share link', () {
        expect(
          SharedMediaFolders.validateFolderUrl(
            'https://drive.google.com/file/d/$currentId/view',
          ),
          isNotNull,
        );
      });
    });

    group('normalized', () {
      test('clears a label when the folder link is empty', () {
        final folders = SharedMediaFolders.normalized(
          currentLabel: 'October 2026',
          currentFolderUrl: '',
          previousLabel: 'September 2026',
          previousFolderUrl: previousUrl,
        );

        expect(folders.currentLabel, isEmpty);
        expect(folders.currentFolderUrl, isEmpty);
        expect(folders.previousLabel, 'September 2026');
      });
    });

    group('openUrl', () {
      test('keeps an https link and expands a bare id', () {
        expect(
          const SharedMediaFolder(
            label: '',
            folderUrl: currentUrl,
            folderId: currentId,
          ).openUrl,
          currentUrl,
        );
        expect(
          const SharedMediaFolder(
            label: '  ',
            folderUrl: currentId,
            folderId: currentId,
          ).openUrl,
          'https://drive.google.com/drive/folders/$currentId',
        );
        expect(
          const SharedMediaFolder(
            label: '  ',
            folderUrl: currentId,
            folderId: currentId,
          ).displayLabel('This month'),
          'This month',
        );
      });
    });
  });
}
