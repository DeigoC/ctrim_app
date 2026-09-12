import 'package:ctrim_app/models/info/church_info.dart';
import 'package:ctrim_app/utility/church_hierarchy.dart';
import 'package:flutter_test/flutter_test.dart';

ChurchInfo _church({
  required String id,
  String title = '',
  ChurchKind kind = ChurchKind.church,
  String parentChurchId = '',
  String location = '',
  int displayOrder = 0,
}) {
  return ChurchInfo(
    id: id,
    title: title.isEmpty ? id : title,
    analyticsTitle: title.isEmpty ? id : title,
    kind: kind,
    parentChurchId: parentChurchId,
    location: location,
    displayOrder: displayOrder,
    body: const [
      {'insert': '\n'}
    ],
  );
}

void main() {
  group('ChurchHierarchy', () {
    final belfast = _church(id: 'belfast', title: 'Belfast', location: 'Belfast');
    final portadown =
        _church(id: 'portadown', title: 'Portadown', location: 'Portadown');
    final lisburn = _church(
      id: 'lisburn',
      title: 'Lisburn',
      kind: ChurchKind.outreach,
      parentChurchId: 'belfast',
      displayOrder: 2,
    );
    final bangor = _church(
      id: 'bangor',
      title: 'Bangor',
      kind: ChurchKind.outreach,
      parentChurchId: 'belfast',
      displayOrder: 1,
    );
    final orphan = _church(
      id: 'orphan',
      title: 'Orphan',
      kind: ChurchKind.outreach,
      parentChurchId: '',
    );

    final churches = [belfast, portadown, lisburn, bangor, orphan];

    test('fullChurches excludes outreaches', () {
      expect(
        ChurchHierarchy.fullChurches(churches).map((c) => c.id),
        ['belfast', 'portadown'],
      );
    });

    test('outreachesOf sorts by displayOrder then title', () {
      expect(
        ChurchHierarchy.outreachesOf(churches, 'belfast').map((c) => c.id),
        ['bangor', 'lisburn'],
      );
    });

    test('forChurchesTab includes outreaches sorted by displayOrder', () {
      expect(
        ChurchHierarchy.forChurchesTab(churches).map((c) => c.id),
        ['belfast', 'orphan', 'portadown', 'bangor', 'lisburn'],
      );
    });

    test('parentOf resolves parent church', () {
      expect(ChurchHierarchy.parentOf(churches, lisburn)?.id, 'belfast');
      expect(ChurchHierarchy.parentOf(churches, belfast), isNull);
    });

    test('eligibleParents excludes self and outreaches', () {
      expect(
        ChurchHierarchy.eligibleParents(
          churches: churches,
          excludingId: 'belfast',
        ).map((c) => c.id),
        ['portadown'],
      );
    });

    test('applyPromote clears parent and sets church kind', () {
      final draft = _church(
        id: 'lisburn',
        kind: ChurchKind.outreach,
        parentChurchId: 'belfast',
      );
      ChurchHierarchy.applyPromote(draft);
      expect(draft.kind, ChurchKind.church);
      expect(draft.parentChurchId, '');
    });

    test('applyDemote sets parent and clears location', () {
      final draft = _church(
        id: 'newtownards',
        location: 'Newtownards',
      );
      ChurchHierarchy.applyDemote(draft, parentId: 'belfast');
      expect(draft.kind, ChurchKind.outreach);
      expect(draft.parentChurchId, 'belfast');
      expect(draft.location, '');
    });

    test('demoteBlockReason when church has outreaches', () {
      expect(
        ChurchHierarchy.demoteBlockReason(
          church: belfast,
          churches: churches,
        ),
        isNotNull,
      );
      expect(
        ChurchHierarchy.demoteBlockReason(
          church: portadown,
          churches: churches,
        ),
        isNull,
      );
    });

    test('validateForSave requires location on full church', () {
      final draft = _church(id: 'x', location: '');
      expect(
        ChurchHierarchy.validateForSave(draft: draft, churches: churches),
        isNotNull,
      );
    });

    test('validateForSave requires parent on outreach', () {
      expect(
        ChurchHierarchy.validateForSave(draft: orphan, churches: churches),
        isNotNull,
      );
      expect(
        ChurchHierarchy.validateForSave(draft: lisburn, churches: churches),
        isNull,
      );
    });

    test('validateForSave rejects outreach parent', () {
      final draft = _church(
        id: 'child',
        kind: ChurchKind.outreach,
        parentChurchId: 'lisburn',
      );
      expect(
        ChurchHierarchy.validateForSave(draft: draft, churches: churches),
        isNotNull,
      );
    });
  });
}
