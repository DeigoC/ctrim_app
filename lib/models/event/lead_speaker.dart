/// Denormalized speaker portrait stored on a post head.
///
/// Order is sermon order. The first entry is the cover photo when the post
/// has no image of its own. [maxCount] is the cap.
class LeadSpeakerSnapshot {
  static const int maxCount = 3;

  const LeadSpeakerSnapshot({
    required this.uid,
    this.imgSrc,
    this.name,
  });

  final String uid;
  final String? imgSrc;
  final String? name;

  bool get hasPortrait =>
      (imgSrc != null && imgSrc!.isNotEmpty) ||
      (name != null && name!.isNotEmpty);

  Map<String, dynamic> toJson() => {
        'UID': uid,
        'ImgSrc': imgSrc,
        'Name': name,
      };

  static String? _blankToNull(final Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static LeadSpeakerSnapshot? tryParse(final Object? raw) {
    if (raw is! Map) return null;
    final uid = _blankToNull(raw['UID'] ?? raw['uid']);
    if (uid == null) return null;
    return LeadSpeakerSnapshot(
      uid: uid,
      imgSrc: _blankToNull(raw['ImgSrc'] ?? raw['imgSrc']),
      name: _blankToNull(raw['Name'] ?? raw['name']),
    );
  }

  /// Drops blanks and duplicates, keeps first-seen order, caps at [maxCount].
  static List<LeadSpeakerSnapshot> normalize(
    final Iterable<LeadSpeakerSnapshot> speakers,
  ) {
    final seen = <String>{};
    final result = <LeadSpeakerSnapshot>[];
    for (final speaker in speakers) {
      final uid = speaker.uid.trim();
      if (uid.isEmpty || !seen.add(uid)) continue;
      result.add(LeadSpeakerSnapshot(
        uid: uid,
        imgSrc: _blankToNull(speaker.imgSrc),
        name: _blankToNull(speaker.name),
      ));
      if (result.length == maxCount) break;
    }
    return result;
  }

  static List<String> normalizeUids(final Iterable<Object?> rawUids) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in rawUids) {
      final uid = _blankToNull(raw);
      if (uid == null || !seen.add(uid)) continue;
      result.add(uid);
      if (result.length == maxCount) break;
    }
    return result;
  }

  /// Prefers a non-empty `LeadSpeakerUIDs` list, otherwise the legacy UID.
  static List<String> uidsFromFields(
    final Object? listField,
    final Object? legacyUid,
  ) {
    if (listField is List && listField.isNotEmpty) {
      final parsed = normalizeUids(listField);
      if (parsed.isNotEmpty) return parsed;
    }
    return normalizeUids([legacyUid]);
  }

  /// Prefers a non-empty `LeadSpeakers` list, otherwise the legacy portrait.
  static List<LeadSpeakerSnapshot> listFromHeadFields(
    final Map<String, dynamic> data,
  ) {
    final raw = data['LeadSpeakers'];
    if (raw is List && raw.isNotEmpty) {
      final parsed =
          normalize(raw.map(tryParse).whereType<LeadSpeakerSnapshot>());
      if (parsed.isNotEmpty) return parsed;
    }
    final uid = _blankToNull(data['LeadSpeakerUID']);
    if (uid == null) return const [];
    return [
      LeadSpeakerSnapshot(
        uid: uid,
        imgSrc: _blankToNull(data['LeadSpeakerImgSrc']),
        name: _blankToNull(data['LeadSpeakerName']),
      ),
    ];
  }

  /// `Ada & Ben`, or `Ada, Ben & Cara` when there are three.
  static String? joinNames(final Iterable<String?> names) {
    final cleaned = names
        .map((name) => name?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return null;
    if (cleaned.length == 1) return cleaned.first;
    if (cleaned.length == 2) return '${cleaned[0]} & ${cleaned[1]}';
    return '${cleaned.sublist(0, cleaned.length - 1).join(', ')} & ${cleaned.last}';
  }
}
