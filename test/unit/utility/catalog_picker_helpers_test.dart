import 'package:ctrim_app/models/catalog_picker_entry.dart';
import 'package:ctrim_app/models/cell_group.dart';
import 'package:ctrim_app/models/post_tag.dart';
import 'package:ctrim_app/utility/catalog/catalog_picker_helpers.dart';
import 'package:ctrim_app/utility/notifications/notification_topics.dart';
import 'package:ctrim_app/utility/catalog/volunteer_locations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatalogPickerHelpers', () {
    test('fromPostTags maps content tags for bulletin filtering', () {
      final entries = CatalogPickerHelpers.fromPostTags(
        [
          PostTag(
            id: 'sun',
            name: 'Sunday Worship',
            streamKind: NotificationTopics.kindSundayService,
          ),
          PostTag(id: 'youth', name: 'Youth'),
        ],
      );

      expect(entries.length, 2);
      expect(entries.first.label, 'Sunday Worship');
      expect(entries.first.isNotifiable, isFalse);
      expect(entries.last.label, 'Youth');
    });

    test('filterEntries matches search and notifiable filter', () {
      const entries = [
        CatalogPickerEntry(
          id: 'a',
          label: 'Sunday Worship',
          subtitle: 'Notifies',
          isNotifiable: true,
        ),
        CatalogPickerEntry(
          id: 'b',
          label: 'Youth',
          subtitle: 'Filter only',
          isNotifiable: false,
        ),
      ];

      expect(
        CatalogPickerHelpers.filterEntries(
          entries: entries,
          searchQuery: 'youth',
        ).map((e) => e.id),
        ['b'],
      );
      expect(
        CatalogPickerHelpers.filterEntries(
          entries: entries,
          searchQuery: '',
          notifiableOnly: true,
        ).map((e) => e.id),
        ['a'],
      );
    });

    test('filterEntries respects location filter for cell groups', () {
      final entries = CatalogPickerHelpers.fromCellGroups([
        CellGroup(id: '1', name: 'North CG', location: 'Belfast'),
        CellGroup(id: '2', name: 'Portadown CG', location: 'Portadown'),
      ]);

      expect(
        CatalogPickerHelpers.filterEntries(
          entries: entries,
          searchQuery: '',
          locationFilter: 'Portadown',
        ).map((e) => e.id),
        ['2'],
      );
      expect(
        CatalogPickerHelpers.filterEntries(
          entries: entries,
          searchQuery: '',
          locationFilter: VolunteerLocations.all,
        ).length,
        2,
      );
    });

    test('visibleEntries keeps inactive selected rows', () {
      const entries = [
        CatalogPickerEntry(id: 'active', label: 'Active', isActive: true),
        CatalogPickerEntry(id: 'old', label: 'Old', isActive: false),
      ];

      expect(
        CatalogPickerHelpers.visibleEntries(
          allEntries: entries,
          selectedIds: const {'old'},
        ).map((e) => e.id),
        ['active', 'old'],
      );
      expect(
        CatalogPickerHelpers.visibleEntries(
          allEntries: entries,
          selectedIds: const {},
        ).map((e) => e.id),
        ['active'],
      );
    });
  });
}
