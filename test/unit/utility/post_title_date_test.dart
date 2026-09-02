import 'package:ctrim_app/utility/post_title_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPostTitleDate', () {
    test('uses ordinal day and abbreviated month', () {
      expect(formatPostTitleDate(DateTime(2026, 7, 26)), '26th Jul');
      expect(formatPostTitleDate(DateTime(2026, 8, 3)), '3rd Aug');
      expect(formatPostTitleDate(DateTime(2026, 1, 1)), '1st Jan');
      expect(formatPostTitleDate(DateTime(2026, 1, 11)), '11th Jan');
    });
  });

  group('formatPostTitle', () {
    test('wraps date in parentheses after template title', () {
      expect(
        formatPostTitle('Sunday Service', DateTime(2026, 7, 26)),
        'Sunday Service (26th Jul)',
      );
    });
  });

  group('formatPostTitlePreviewDate', () {
    test('includes weekday before title date', () {
      expect(
        formatPostTitlePreviewDate(DateTime(2026, 7, 26)),
        'Sun 26th Jul',
      );
    });
  });
}
