/// Canonical FCM topic names for Belfast broadcasts and per-post bookmarks.
class NotificationTopics {
  NotificationTopics._();

  static const String belfastUmbrella = 'Belfast';
  static const String sundayService = 'belfast-sunday-service';
  static const String midweekService = 'belfast-midweek-service';
  static const String growthMentoring = 'belfast-growth-mentoring';
  static const String dawnWatch = 'belfast-dawn-watch';
  static const String overnightPrayer = 'belfast-overnight-prayer';
  static const String youthCaregroup = 'belfast-youth-cg';

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
}
