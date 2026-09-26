import 'package:flutter_test/flutter_test.dart';

import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/person_display_name.dart';

void main() {
  group('PersonDisplayName.leadSpeakerLabel', () {
    test('uses the live profile for guests and signed-in viewers', () {
      final user = User(id: '1', forname: 'Adam', surname: 'Barr');
      expect(
        PersonDisplayName.leadSpeakerLabel(
          storedName: 'Adam Barr',
          user: user,
          guest: true,
        ),
        'Adam B.',
      );
      expect(
        PersonDisplayName.leadSpeakerLabel(
          storedName: 'Adam Barr',
          user: user,
          guest: false,
        ),
        'Adam Barr',
      );
    });

    test('keeps the full name for guests who opted in', () {
      final user = User(
        id: '1',
        forname: 'Adam',
        surname: 'Barr',
        showFullSurnameToGuests: true,
      );
      expect(
        PersonDisplayName.leadSpeakerLabel(
          storedName: 'Stale Name',
          user: user,
          guest: true,
        ),
        'Adam Barr',
      );
    });

    test('abbreviates a stored name when the profile is missing', () {
      expect(
        PersonDisplayName.leadSpeakerLabel(
          storedName: 'Adam Barr',
          user: null,
          guest: true,
        ),
        'Adam B.',
      );
      expect(
        PersonDisplayName.leadSpeakerLabel(
          storedName: 'John Smith-Jones',
          user: null,
          guest: true,
        ),
        'John SJ.',
      );
      expect(
        PersonDisplayName.abbreviateStoredPersonalName('Adam B.'),
        'Adam B.',
      );
    });

    test('keeps the stored full name for signed-in viewers without a profile',
        () {
      expect(
        PersonDisplayName.leadSpeakerLabel(
          storedName: 'Adam Barr',
          user: null,
          guest: false,
        ),
        'Adam Barr',
      );
    });

    test('uses the fallback label when nothing is stored', () {
      expect(
        PersonDisplayName.leadSpeakerLabel(
          storedName: null,
          user: null,
          guest: true,
        ),
        'Lead speaker',
      );
    });
  });
}
