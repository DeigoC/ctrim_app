import 'package:ctrim_app/utility/schedule_member_picker_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduleMemberPickerSeed', () {
    const sites = ['Belfast', 'Portadown', 'North Coast'];

    test('untagged role leaves ministry and location unset', () {
      final seed = ScheduleMemberPickerSeed.forRole(
        tagIDs: const ['', '  '],
        postLocation: 'Belfast',
        assignableLocations: sites,
      );

      expect(seed.tagIDs, isEmpty);
      expect(seed.location, isNull);
    });

    test('tagged role uses its ministries and the post location', () {
      final seed = ScheduleMemberPickerSeed.forRole(
        tagIDs: const ['media', 'worship'],
        postLocation: 'Portadown (Online)',
        assignableLocations: sites,
      );

      expect(seed.tagIDs, ['media', 'worship']);
      expect(seed.location, 'Portadown');
    });

    test('unknown post location still filters to the ministries', () {
      final seed = ScheduleMemberPickerSeed.forRole(
        tagIDs: const ['media'],
        postLocation: 'Somewhere else',
        assignableLocations: sites,
      );

      expect(seed.tagIDs, ['media']);
      expect(seed.location, isNull);
    });
  });
}
