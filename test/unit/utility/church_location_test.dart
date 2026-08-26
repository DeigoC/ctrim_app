import 'package:ctrim_app/models/info/church_info.dart';
import 'package:ctrim_app/utility/church_location.dart';
import 'package:flutter_test/flutter_test.dart';

ChurchInfo _church({
  required String id,
  required String location,
}) {
  return ChurchInfo(
    id: id,
    title: id,
    analyticsTitle: id,
    body: const [
      {'insert': '\n'}
    ],
    location: location,
  );
}

void main() {
  group('ChurchLocation', () {
    final churches = [
      _church(id: 'belfast', location: 'Belfast'),
      _church(id: 'portadown', location: 'Portadown'),
      _church(id: 'draft', location: ''),
    ];

    test('otherChurchUsingLocation finds a different church', () {
      final other = ChurchLocation.otherChurchUsingLocation(
        churches: churches,
        location: 'Belfast',
        excludingId: 'new-id',
      );
      expect(other?.id, 'belfast');
    });

    test('otherChurchUsingLocation ignores the church being edited', () {
      final other = ChurchLocation.otherChurchUsingLocation(
        churches: churches,
        location: 'Belfast',
        excludingId: 'belfast',
      );
      expect(other, isNull);
    });

    test('otherChurchUsingLocation treats blank as unused', () {
      expect(
        ChurchLocation.otherChurchUsingLocation(
          churches: churches,
          location: '  ',
        ),
        isNull,
      );
    });

    test('occupiedLocationNames skips blank and excluded id', () {
      expect(
        ChurchLocation.occupiedLocationNames(
          churches: churches,
          excludingId: 'belfast',
        ),
        {'Portadown'},
      );
    });
  });
}
