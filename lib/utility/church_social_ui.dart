import 'package:flutter/material.dart';

import '../models/info/church_social.dart';
import '../src/localization/app_localizations.dart';

/// Icons and localized labels for [ChurchSocialPlatform].
class ChurchSocialUi {
  ChurchSocialUi._();

  static IconData iconFor(final ChurchSocialPlatform platform) {
    return switch (platform) {
      ChurchSocialPlatform.facebook => Icons.facebook,
      ChurchSocialPlatform.instagram => Icons.camera_alt_outlined,
      ChurchSocialPlatform.youtube => Icons.play_circle_outline,
      ChurchSocialPlatform.x => Icons.tag,
      ChurchSocialPlatform.tiktok => Icons.music_note_outlined,
      ChurchSocialPlatform.whatsapp => Icons.chat_outlined,
      ChurchSocialPlatform.website => Icons.language,
      ChurchSocialPlatform.email => Icons.email_outlined,
      ChurchSocialPlatform.other => Icons.link,
    };
  }

  static String labelFor(
    final AppLocalizations l10n,
    final ChurchSocialPlatform platform,
  ) {
    return switch (platform) {
      ChurchSocialPlatform.facebook => l10n.churchSocialFacebook,
      ChurchSocialPlatform.instagram => l10n.churchSocialInstagram,
      ChurchSocialPlatform.youtube => l10n.churchSocialYoutube,
      ChurchSocialPlatform.x => l10n.churchSocialX,
      ChurchSocialPlatform.tiktok => l10n.churchSocialTiktok,
      ChurchSocialPlatform.whatsapp => l10n.churchSocialWhatsapp,
      ChurchSocialPlatform.website => l10n.churchSocialWebsite,
      ChurchSocialPlatform.email => l10n.churchSocialEmail,
      ChurchSocialPlatform.other => l10n.churchSocialOther,
    };
  }

  /// Normalize typed URLs; emails get a `mailto:` prefix when needed.
  static String normalizeUrl(
    final ChurchSocialPlatform platform,
    final String raw,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (platform == ChurchSocialPlatform.email) {
      if (trimmed.toLowerCase().startsWith('mailto:')) return trimmed;
      if (trimmed.contains('@') && !trimmed.contains('://')) {
        return 'mailto:$trimmed';
      }
    }
    if (platform == ChurchSocialPlatform.whatsapp) {
      final digits = trimmed.replaceAll(RegExp(r'[^\d+]'), '');
      if (digits.isNotEmpty && !trimmed.contains('://')) {
        final phone = digits.startsWith('+') ? digits.substring(1) : digits;
        return 'https://wa.me/$phone';
      }
    }
    if (!trimmed.contains('://') &&
        platform != ChurchSocialPlatform.email) {
      return 'https://$trimmed';
    }
    return trimmed;
  }
}
