import 'package:ctrim_app/models/info/church_social.dart';
import 'package:ctrim_app/utility/church_social_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChurchSocialPlatform', () {
    test('fromStorage maps aliases', () {
      expect(ChurchSocialPlatform.fromStorage('twitter'), ChurchSocialPlatform.x);
      expect(ChurchSocialPlatform.fromStorage('fb'), ChurchSocialPlatform.facebook);
      expect(ChurchSocialPlatform.fromStorage('ig'), ChurchSocialPlatform.instagram);
      expect(ChurchSocialPlatform.fromStorage('unknown'), ChurchSocialPlatform.other);
    });
  });

  group('ChurchSocialLink', () {
    test('parseList skips blanks and duplicate platforms', () {
      final links = ChurchSocialLink.parseList([
        {'platform': 'facebook', 'url': 'https://facebook.com/ctrim'},
        {'platform': 'facebook', 'url': 'https://facebook.com/dup'},
        {'platform': 'other', 'url': 'https://a.example'},
        {'platform': 'other', 'url': 'https://b.example'},
        {'platform': 'instagram', 'url': ''},
      ]);

      expect(links.length, 3);
      expect(links[0].platform, ChurchSocialPlatform.facebook);
      expect(links[0].url, 'https://facebook.com/ctrim');
      expect(links[1].platform, ChurchSocialPlatform.other);
      expect(links[2].platform, ChurchSocialPlatform.other);
    });

    test('toJson round-trips platform storage', () {
      const link = ChurchSocialLink(
        platform: ChurchSocialPlatform.youtube,
        url: 'https://youtube.com/@ctrim',
      );
      expect(link.toJson(), {
        'platform': 'youtube',
        'url': 'https://youtube.com/@ctrim',
      });
    });
  });

  group('ChurchSocialUi.normalizeUrl', () {
    test('adds https when missing', () {
      expect(
        ChurchSocialUi.normalizeUrl(
          ChurchSocialPlatform.facebook,
          'facebook.com/ctrim',
        ),
        'https://facebook.com/ctrim',
      );
    });

    test('wraps bare email as mailto', () {
      expect(
        ChurchSocialUi.normalizeUrl(
          ChurchSocialPlatform.email,
          'hello@ctrim.app',
        ),
        'mailto:hello@ctrim.app',
      );
    });

    test('builds wa.me for phone digits', () {
      expect(
        ChurchSocialUi.normalizeUrl(
          ChurchSocialPlatform.whatsapp,
          '+44 7700 900123',
        ),
        'https://wa.me/447700900123',
      );
    });
  });
}
