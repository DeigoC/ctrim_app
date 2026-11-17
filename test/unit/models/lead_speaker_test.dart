import 'package:ctrim_app/models/event/lead_speaker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LeadSpeakerSnapshot', () {
    test('joinNames uses & before the last name', () {
      expect(LeadSpeakerSnapshot.joinNames(['Ada']), 'Ada');
      expect(LeadSpeakerSnapshot.joinNames(['Ada', 'Ben']), 'Ada & Ben');
      expect(
        LeadSpeakerSnapshot.joinNames(['Ada', ' Ben ', 'Cara']),
        'Ada, Ben & Cara',
      );
      expect(LeadSpeakerSnapshot.joinNames([null, '  ']), isNull);
    });

    test('normalize drops blanks and duplicates and keeps order', () {
      final speakers = LeadSpeakerSnapshot.normalize(const [
        LeadSpeakerSnapshot(uid: ' ', name: 'Skip'),
        LeadSpeakerSnapshot(uid: 'a', imgSrc: '', name: 'Ada'),
        LeadSpeakerSnapshot(uid: 'b', name: 'Ben'),
        LeadSpeakerSnapshot(uid: 'a', name: 'Again'),
      ]);

      expect(speakers.map((speaker) => speaker.uid), ['a', 'b']);
      expect(speakers.first.imgSrc, isNull);
      expect(speakers.first.name, 'Ada');
    });
  });
}
