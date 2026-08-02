/// Canonical FCM topic names for location umbrellas, service streams, and per-post bookmarks.
///
/// Service streams are `{locationSlug}-{streamKind}` (e.g. `belfast-sunday-service`).
/// Belfast IDs are frozen — [streamTopic] must keep producing the existing strings.
class NotificationTopics {
  NotificationTopics._();

  static const String belfastUmbrella = 'Belfast';
  static const String sundayService = 'belfast-sunday-service';
  static const String midweekService = 'belfast-midweek-service';
  static const String growthMentoring = 'belfast-growth-mentoring';
  static const String dawnWatch = 'belfast-dawn-watch';
  static const String overnightPrayer = 'belfast-overnight-prayer';
  static const String youthCaregroup = 'belfast-youth-cg';

  static const String belfastUmbrellaLabel = 'All Belfast updates';

  /// Stream kind suffixes used with [streamTopic] (location-agnostic).
  static const String kindSundayService = 'sunday-service';
  static const String kindMidweekService = 'midweek-service';
  static const String kindGrowthMentoring = 'growth-mentoring';
  static const String kindDawnWatch = 'dawn-watch';
  static const String kindOvernightPrayer = 'overnight-prayer';
  static const String kindYouthCaregroup = 'youth-cg';

  static const List<String> serviceStreamKinds = [
    kindSundayService,
    kindMidweekService,
    kindGrowthMentoring,
    kindDawnWatch,
    kindOvernightPrayer,
    kindYouthCaregroup,
  ];

  /// Display labels for stream kinds (and legacy full topic ids).
  static const Map<String, String> serviceTopicLabels = {
    sundayService: 'Sunday Worship Service',
    midweekService: 'Midweek Service',
    growthMentoring: 'Growth Mentoring',
    dawnWatch: 'Dawn Watch',
    overnightPrayer: 'Overnight Prayer',
    youthCaregroup: 'Youth Online Caregroup',
    kindSundayService: 'Sunday Worship Service',
    kindMidweekService: 'Midweek Service',
    kindGrowthMentoring: 'Growth Mentoring',
    kindDawnWatch: 'Dawn Watch',
    kindOvernightPrayer: 'Overnight Prayer',
    kindYouthCaregroup: 'Youth Online Caregroup',
  };

  /// Belfast service topics (frozen IDs for existing subscribers).
  static const List<String> serviceTopics = [
    sundayService,
    midweekService,
    growthMentoring,
    dawnWatch,
    overnightPrayer,
    youthCaregroup,
  ];

  static const List<String> allManagedTopics = [
    ...serviceTopics,
    belfastUmbrella,
  ];

  static String postTopic(String postId) => 'post-$postId';

  /// Slug for FCM topic segments. `Belfast` → `belfast`, `North Coast` → `north-coast`.
  static String locationSlug(String locationName) {
    final cleaned = locationNameForStreams(locationName)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Strips trailing `(Online)` from head location strings before stream derivation.
  static String locationNameForStreams(String locationName) {
    return locationName
        .replaceAll(RegExp(r'\s*\(Online\)\s*$', caseSensitive: false), '')
        .trim();
  }

  /// Location umbrella topic. Belfast stays the literal string [belfastUmbrella].
  static String locationUmbrella(String locationName) {
    final name = locationNameForStreams(locationName);
    if (locationSlug(name) == 'belfast') return belfastUmbrella;
    return name.isEmpty ? belfastUmbrella : name;
  }

  static String locationUmbrellaLabel(String locationName) {
    final umbrella = locationUmbrella(locationName);
    if (umbrella == belfastUmbrella) return belfastUmbrellaLabel;
    return 'All $umbrella updates';
  }

  /// `{locationSlug}-{streamKind}` — Belfast IDs match historical constants.
  static String streamTopic({
    required String locationName,
    required String streamKind,
  }) {
    final kind = streamKind.trim();
    final slug = locationSlug(locationName);
    if (slug.isEmpty || kind.isEmpty) return kind;
    return '$slug-$kind';
  }

  static String labelFor(String topic) {
    if (topic == belfastUmbrella) return belfastUmbrellaLabel;
    final known = serviceTopicLabels[topic];
    if (known != null) return known;
    // `{slug}-{kind}` → try kind label, else raw topic
    final dash = topic.indexOf('-');
    if (dash > 0 && dash < topic.length - 1) {
      final kind = topic.substring(dash + 1);
      final kindLabel = serviceTopicLabels[kind];
      if (kindLabel != null) return kindLabel;
    }
    return topic;
  }
}
