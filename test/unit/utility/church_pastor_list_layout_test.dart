import 'package:ctrim_app/utility/church_pastor_list_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChurchPastorListLayout.columns', () {
    test('one pastor is a single tile', () {
      expect(
        ChurchPastorListLayout.columns(count: 1, maxWidth: 400),
        1,
      );
    });

    test('two pastors stay side by side', () {
      expect(
        ChurchPastorListLayout.columns(count: 2, maxWidth: 280),
        2,
      );
      expect(
        ChurchPastorListLayout.columns(count: 2, maxWidth: 500),
        2,
      );
    });

    test('three or more use three columns when tiles stay readable', () {
      expect(
        ChurchPastorListLayout.columns(count: 3, maxWidth: 400),
        3,
      );
      expect(
        ChurchPastorListLayout.columns(count: 4, maxWidth: 400),
        3,
      );
    });

    test('falls back to two columns on a narrow card', () {
      expect(
        ChurchPastorListLayout.columns(count: 3, maxWidth: 280),
        2,
      );
    });
  });

  group('ChurchPastorListLayout.tileWidth', () {
    test('splits the row evenly with gaps', () {
      expect(
        ChurchPastorListLayout.tileWidth(columns: 2, maxWidth: 320),
        closeTo((320 - 8) / 2, 0.01),
      );
    });
  });
}
