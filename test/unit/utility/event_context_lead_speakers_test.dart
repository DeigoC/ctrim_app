import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/event_log.dart';
import 'package:ctrim_app/models/event/lead_speaker.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventContext speakers', () {
    test('applyLeadSpeakers stores order on metadata and the head', () {
      final context = EventContext.adding(currentUserID: 'author-1');
      context.applyLeadSpeakers(const [
        LeadSpeakerSnapshot(uid: 'ada', imgSrc: 'ada.jpg', name: 'Ada Barr'),
        LeadSpeakerSnapshot(uid: 'ben', imgSrc: 'ben.jpg', name: 'Ben Cole'),
      ]);

      expect(context.metadata.leadSpeakerUIDs, ['ada', 'ben']);
      expect(context.head.leadSpeakerUID, 'ada');
      expect(context.head.getKeyGraphic(), 'ada.jpg');
      expect(context.head.leadSpeakers.map((speaker) => speaker.name),
          ['Ada Barr', 'Ben Cole']);
    });

    test('sync resolves known users and keeps a missing portrait', () {
      final context = EventContext.adding(currentUserID: 'author-1');
      context.metadata.setLeadSpeakerUIDs(['ada', 'missing']);
      context.head.setLeadSpeakers(const [
        LeadSpeakerSnapshot(uid: 'missing', imgSrc: 'kept.jpg', name: 'Kept'),
      ]);

      context.syncLeadSpeakerHeadFromUsers([
        User(id: 'ada', forname: 'Ada', surname: 'Barr', imgSrc: 'ada.jpg'),
      ]);

      expect(context.head.leadSpeakers.map((speaker) => speaker.uid),
          ['ada', 'missing']);
      expect(context.head.leadSpeakers.first.name, 'Ada Barr');
      expect(context.head.leadSpeakers.last.imgSrc, 'kept.jpg');
      expect(context.head.getKeyGraphic(), 'ada.jpg');
    });

    test('text export round-trips several speakers and still reads one', () {
      final context = EventContext.adding(currentUserID: 'author-1');
      context.setFetchedLogs(EventLog({
        'uid': 'author-1',
        'log': 'Created',
        'ts': DateTime(2026, 1, 1),
      }));
      context.applyLeadSpeakers(const [
        LeadSpeakerSnapshot(uid: 'ada', name: 'Ada'),
        LeadSpeakerSnapshot(uid: 'ben', name: 'Ben'),
      ]);

      final lines = context.transformPostToTxtFile('1').split('\n');
      final restored = EventContext.viewing(
        eventHead: EventHead(id: 'post-1'),
        currentUID: 'author-1',
        data: lines,
      );

      expect(restored.metadata.leadSpeakerUIDs, ['ada', 'ben']);
      expect(restored.metadata.leadSpeakerUID, 'ada');
    });
  });
}
