import 'package:ctrim_app/utility/attendance_list_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceListPreview', () {
    test('a phone folds at nine people and a wide screen at eighteen', () {
      expect(
        AttendanceListPreview.shouldCollapse(count: 8, isWide: false),
        isFalse,
      );
      expect(
        AttendanceListPreview.shouldCollapse(count: 9, isWide: false),
        isTrue,
      );
      expect(
        AttendanceListPreview.shouldCollapse(count: 17, isWide: true),
        isFalse,
      );
      expect(
        AttendanceListPreview.shouldCollapse(count: 18, isWide: true),
        isTrue,
      );
    });

    test('the folded line keeps a few names and counts the rest', () {
      final names = [for (var i = 0; i < 12; i++) 'Person $i'];

      final phone = AttendanceListPreview.names(names: names, isWide: false);
      expect(phone.shown, ['Person 0', 'Person 1', 'Person 2']);
      expect(phone.hidden, 9);

      final wide = AttendanceListPreview.names(names: names, isWide: true);
      expect(wide.shown, hasLength(6));
      expect(wide.hidden, 6);
    });

    test('a short name list has nothing hidden', () {
      final preview = AttendanceListPreview.names(
        names: const ['Ada', 'Ben'],
        isWide: false,
      );

      expect(preview.shown, ['Ada', 'Ben']);
      expect(preview.hidden, 0);
    });
  });
}
