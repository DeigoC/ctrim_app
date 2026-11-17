import 'package:ctrim_app/models/shared_media_folders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const currentId = '1KpLl_1tcK0eeehzN980zbG-3M2nhbVks';
  const previousId = '2KpLl_1tcK0eeehzN980zbG-3M2nhbVks';
  const olderId = '3KpLl_1tcK0eeehzN980zbG-3M2nhbVks';
  const cellId = '4KpLl_1tcK0eeehzN980zbG-3M2nhbVks';
  const currentUrl = 'https://drive.google.com/drive/folders/$currentId';
  const previousUrl = 'https://drive.google.com/drive/folders/$previousId';
  const olderUrl = 'https://drive.google.com/drive/folders/$olderId';
  const cellUrl = 'https://drive.google.com/drive/folders/$cellId';

  group('SharedMediaFolderPair', () {
    group('startNewMonth', () {
      test('drops the month before last', () {
        final pair = SharedMediaFolderPair(
          currentLabel: 'October 2026',
          currentFolderUrl: currentUrl,
          previousLabel: 'September 2026',
          previousFolderUrl: previousUrl,
        );

        final next = pair.startNewMonth();

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
        expect(SharedMediaFolderPair.validateFolderUrl(''), isNull);
        expect(SharedMediaFolderPair.validateFolderUrl(currentUrl), isNull);
        expect(SharedMediaFolderPair.validateFolderUrl(currentId), isNull);
      });

      test('rejects a file share link', () {
        expect(
          SharedMediaFolderPair.validateFolderUrl(
            'https://drive.google.com/file/d/$currentId/view',
          ),
          isNotNull,
        );
      });
    });

    group('normalized', () {
      test('clears a label when the folder link is empty', () {
        final pair = SharedMediaFolderPair.normalized(
          currentLabel: 'October 2026',
          currentFolderUrl: '',
          previousLabel: 'September 2026',
          previousFolderUrl: previousUrl,
        );

        expect(pair.currentLabel, isEmpty);
        expect(pair.currentFolderUrl, isEmpty);
        expect(pair.previousLabel, 'September 2026');
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

  group('SharedMediaFolders', () {
    group('fromMap', () {
      test('reads a flat document as Services', () {
        final folders = SharedMediaFolders.fromMap({
          'CurrentLabel': 'October 2026',
          'CurrentFolderUrl': currentUrl,
          'PreviousLabel': 'September 2026',
          'PreviousFolderUrl': previousUrl,
        });

        expect(folders.service.current?.folderId, currentId);
        expect(
          folders.service.current?.displayLabel('This month'),
          'October 2026',
        );
        expect(folders.service.previous?.folderId, previousId);
        expect(folders.service.previous?.label, 'September 2026');
        expect(folders.cellGroup.current, isNull);
        expect(folders.cellGroup.previous, isNull);
        expect(folders.service.canStartNewMonth, isTrue);
      });

      test('an empty document has no folders', () {
        final folders = SharedMediaFolders.fromMap(const {});

        expect(folders.service.current, isNull);
        expect(folders.service.previous, isNull);
        expect(folders.cellGroup.current, isNull);
        expect(folders.service.canStartNewMonth, isFalse);
      });

      test('nested groups win over the old flat fields', () {
        final folders = SharedMediaFolders.fromMap({
          'CurrentLabel': 'Old',
          'CurrentFolderUrl': currentUrl,
          'Service': {
            'CurrentLabel': 'October 2026',
            'CurrentFolderUrl': previousUrl,
          },
          'CellGroup': {
            'CurrentLabel': 'Meetings',
            'CurrentFolderUrl': cellUrl,
          },
        });

        expect(folders.service.current?.folderId, previousId);
        expect(folders.service.current?.label, 'October 2026');
        expect(folders.cellGroup.current?.folderId, cellId);
        expect(folders.cellGroup.current?.label, 'Meetings');
      });
    });

    group('toJson', () {
      test('round-trips both groups and mirrors Services', () {
        final folders = SharedMediaFolders(
          service: SharedMediaFolderPair(
            currentLabel: 'October 2026',
            currentFolderUrl: currentUrl,
            previousLabel: 'September 2026',
            previousFolderUrl: previousUrl,
          ),
          cellGroup: SharedMediaFolderPair(
            currentLabel: 'October meetings',
            currentFolderUrl: cellUrl,
          ),
        );

        final json = folders.toJson();

        expect(SharedMediaFolders.fromMap(json).toJson(), json);
        expect(json['Service'], {
          'CurrentLabel': 'October 2026',
          'CurrentFolderUrl': currentUrl,
          'PreviousLabel': 'September 2026',
          'PreviousFolderUrl': previousUrl,
        });
        expect(json['CellGroup'], {
          'CurrentLabel': 'October meetings',
          'CurrentFolderUrl': cellUrl,
          'PreviousLabel': '',
          'PreviousFolderUrl': '',
        });
        expect(json['CurrentLabel'], 'October 2026');
        expect(json['CurrentFolderUrl'], currentUrl);
        expect(json['PreviousFolderUrl'], previousUrl);
      });
    });

    group('replacing', () {
      test('starting a new month on Services leaves Cell Groups', () {
        final folders = SharedMediaFolders(
          service: SharedMediaFolderPair(
            currentLabel: 'October 2026',
            currentFolderUrl: currentUrl,
            previousLabel: 'September 2026',
            previousFolderUrl: previousUrl,
          ),
          cellGroup: SharedMediaFolderPair(
            currentLabel: 'October meetings',
            currentFolderUrl: cellUrl,
            previousLabel: 'September meetings',
            previousFolderUrl: olderUrl,
          ),
        );

        final next = folders.replacing(
          SharedMediaFolderKind.service,
          folders.service.startNewMonth(),
        );

        expect(next.service.current, isNull);
        expect(next.service.previous?.folderId, currentId);
        expect(next.service.previousLabel, 'October 2026');
        expect(next.cellGroup.current?.folderId, cellId);
        expect(next.cellGroup.currentLabel, 'October meetings');
        expect(next.cellGroup.previous?.folderId, olderId);
        expect(next.pairFor(SharedMediaFolderKind.cellGroup).currentLabel,
            'October meetings');
      });
    });
  });
}
