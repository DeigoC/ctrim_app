/// Known social / contact channels for a church hub.
enum ChurchSocialPlatform {
  facebook,
  instagram,
  youtube,
  x,
  tiktok,
  whatsapp,
  website,
  email,
  other;

  static const List<ChurchSocialPlatform> editableOrder = [
    ChurchSocialPlatform.facebook,
    ChurchSocialPlatform.instagram,
    ChurchSocialPlatform.youtube,
    ChurchSocialPlatform.x,
    ChurchSocialPlatform.tiktok,
    ChurchSocialPlatform.whatsapp,
    ChurchSocialPlatform.website,
    ChurchSocialPlatform.email,
    ChurchSocialPlatform.other,
  ];

  static ChurchSocialPlatform fromStorage(final dynamic raw) {
    final value = (raw ?? '').toString().trim().toLowerCase();
    switch (value) {
      case 'facebook':
      case 'fb':
        return ChurchSocialPlatform.facebook;
      case 'instagram':
      case 'ig':
        return ChurchSocialPlatform.instagram;
      case 'youtube':
      case 'yt':
        return ChurchSocialPlatform.youtube;
      case 'x':
      case 'twitter':
        return ChurchSocialPlatform.x;
      case 'tiktok':
        return ChurchSocialPlatform.tiktok;
      case 'whatsapp':
      case 'wa':
        return ChurchSocialPlatform.whatsapp;
      case 'website':
      case 'web':
      case 'site':
        return ChurchSocialPlatform.website;
      case 'email':
      case 'mail':
        return ChurchSocialPlatform.email;
      default:
        return ChurchSocialPlatform.other;
    }
  }

  String get storageValue => switch (this) {
        ChurchSocialPlatform.facebook => 'facebook',
        ChurchSocialPlatform.instagram => 'instagram',
        ChurchSocialPlatform.youtube => 'youtube',
        ChurchSocialPlatform.x => 'x',
        ChurchSocialPlatform.tiktok => 'tiktok',
        ChurchSocialPlatform.whatsapp => 'whatsapp',
        ChurchSocialPlatform.website => 'website',
        ChurchSocialPlatform.email => 'email',
        ChurchSocialPlatform.other => 'other',
      };

  /// Short English fallback label (prefer l10n in UI).
  String get defaultLabel => switch (this) {
        ChurchSocialPlatform.facebook => 'Facebook',
        ChurchSocialPlatform.instagram => 'Instagram',
        ChurchSocialPlatform.youtube => 'YouTube',
        ChurchSocialPlatform.x => 'X',
        ChurchSocialPlatform.tiktok => 'TikTok',
        ChurchSocialPlatform.whatsapp => 'WhatsApp',
        ChurchSocialPlatform.website => 'Website',
        ChurchSocialPlatform.email => 'Email',
        ChurchSocialPlatform.other => 'Link',
      };
}

/// One optional social / contact link on a church hub.
class ChurchSocialLink {
  const ChurchSocialLink({
    required this.platform,
    required this.url,
  });

  final ChurchSocialPlatform platform;
  final String url;

  factory ChurchSocialLink.fromMap(final Map<String, dynamic> data) {
    return ChurchSocialLink(
      platform: ChurchSocialPlatform.fromStorage(data['platform']),
      url: (data['url'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'platform': platform.storageValue,
        'url': url,
      };

  bool get isValid => url.isNotEmpty;

  static List<ChurchSocialLink> parseList(final dynamic raw) {
    if (raw is! List) return const [];
    final results = <ChurchSocialLink>[];
    final seenPlatforms = <ChurchSocialPlatform>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final link = ChurchSocialLink.fromMap(Map<String, dynamic>.from(entry));
      if (!link.isValid) continue;
      // One link per known platform; allow multiple [other].
      if (link.platform != ChurchSocialPlatform.other &&
          seenPlatforms.contains(link.platform)) {
        continue;
      }
      seenPlatforms.add(link.platform);
      results.add(link);
    }
    return results;
  }
}
