import 'package:ctrim_app/models/info/church_info.dart';
import 'package:ctrim_app/models/info/church_social.dart';
import 'package:ctrim_app/pages/information/church_hub_dashboard.dart';
import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('maps and social buttons fill the card width', (tester) async {
    await _pumpHub(
      tester,
      width: 420,
      socials: const [
        ChurchSocialLink(
            platform: ChurchSocialPlatform.facebook, url: 'https://fb'),
        ChurchSocialLink(
            platform: ChurchSocialPlatform.youtube, url: 'https://yt'),
      ],
    );

    final maps = find.widgetWithText(FilledButton, 'Open in Maps');
    final facebook = find.widgetWithText(FilledButton, 'Facebook');
    final youtube = find.widgetWithText(FilledButton, 'YouTube');

    final mapsWidth = tester.getSize(maps).width;
    expect(mapsWidth, greaterThan(280));
    expect(
      tester.getSize(facebook).width + tester.getSize(youtube).width + 8,
      closeTo(mapsWidth, 1),
    );
    expect(
      tester.getSize(facebook).width,
      closeTo(tester.getSize(youtube).width, 1),
    );
  });

  testWidgets('many socials wrap into rows that still fill the card',
      (tester) async {
    await _pumpHub(
      tester,
      width: 420,
      socials: const [
        ChurchSocialLink(
            platform: ChurchSocialPlatform.facebook, url: 'https://fb'),
        ChurchSocialLink(
            platform: ChurchSocialPlatform.instagram, url: 'https://ig'),
        ChurchSocialLink(
            platform: ChurchSocialPlatform.youtube, url: 'https://yt'),
        ChurchSocialLink(
            platform: ChurchSocialPlatform.whatsapp, url: 'https://wa'),
        ChurchSocialLink(
            platform: ChurchSocialPlatform.website, url: 'https://site'),
      ],
    );

    final mapsWidth = tester
        .getSize(
          find.widgetWithText(FilledButton, 'Open in Maps'),
        )
        .width;
    final rows = _buttonsByRow(find.byType(FilledButton));
    // Maps is its own row; socials share two-wide rows, with the leftover
    // stretching across the last row.
    expect(rows.length, 4);
    expect(rows[1].length, 2);
    expect(rows[2].length, 2);
    expect(rows[3].length, 1);
    for (final row in rows.skip(1)) {
      final width = row.fold<double>(0, (sum, rect) => sum + rect.width) +
          8 * (row.length - 1);
      expect(width, closeTo(mapsWidth, 1));
    }
  });

  testWidgets('a wide card fits three socials on a row', (tester) async {
    await _pumpHub(
      tester,
      width: 560,
      socials: const [
        ChurchSocialLink(
            platform: ChurchSocialPlatform.facebook, url: 'https://fb'),
        ChurchSocialLink(
            platform: ChurchSocialPlatform.instagram, url: 'https://ig'),
        ChurchSocialLink(
            platform: ChurchSocialPlatform.youtube, url: 'https://yt'),
        ChurchSocialLink(
            platform: ChurchSocialPlatform.website, url: 'https://site'),
        ChurchSocialLink(
            platform: ChurchSocialPlatform.email, url: 'mailto:a@b.c'),
      ],
    );

    final mapsWidth = tester
        .getSize(
          find.widgetWithText(FilledButton, 'Open in Maps'),
        )
        .width;
    final rows = _buttonsByRow(find.byType(FilledButton));
    expect(rows[1].length, 3);
    expect(rows[2].length, 2);
    for (final row in rows.skip(1)) {
      final width = row.fold<double>(0, (sum, rect) => sum + rect.width) +
          8 * (row.length - 1);
      expect(width, closeTo(mapsWidth, 1));
    }
  });
}

Future<void> _pumpHub(
  WidgetTester tester, {
  required double width,
  required List<ChurchSocialLink> socials,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final prefs = await SharedPreferences.getInstance();
  final appContext = AppContext(
    prefInstance: prefs,
    cacheDir: null,
    appDir: null,
  );
  final church = ChurchInfo(
    id: 'belfast',
    title: 'Belfast',
    analyticsTitle: 'Belfast',
    body: const [],
    kind: ChurchKind.outreach,
    address: '8A Princes Drive, BT37 0AZ',
    socials: socials,
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<AppContext>.value(
      value: appContext,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: ChurchHubDashboard(
                church: church,
                pages: const [],
                pagesError: null,
                stats: null,
                statsError: null,
                canAddPages: false,
                canManageInfo: false,
                visiblePostLimit: 4,
                onOpenMaps: () {},
                onOpenSocial: (_) {},
                onOpenPastors: () {},
                onOpenPage: (_) {},
                onAddPage: () {},
                onRetryPages: () {},
                onRetryStats: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

List<List<Rect>> _buttonsByRow(Finder finder) {
  final rects = finder.evaluate().map((element) {
    final box = element.renderObject! as RenderBox;
    return box.localToGlobal(Offset.zero) & box.size;
  }).toList();
  rects.sort((a, b) => a.top.compareTo(b.top));
  final rows = <List<Rect>>[];
  for (final rect in rects) {
    if (rows.isEmpty || (rect.top - rows.last.first.top).abs() > 4) {
      rows.add([rect]);
    } else {
      rows.last.add(rect);
    }
  }
  return rows;
}
