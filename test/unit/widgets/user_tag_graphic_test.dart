import 'package:ctrim_app/utility/gallery_viewer.dart';
import 'package:ctrim_app/widgets/catalog/user_tag_graphic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coverHeroTag is stable for gallery and detail flyovers', () {
    expect(UserTagGraphic.coverHeroTag('tag-1'), 'user_tag_cover_tag-1');
  });

  test('cover sizes are larger than the previous card and detail defaults', () {
    expect(UserTagGraphic.cardHeight, greaterThan(140));
    expect(UserTagGraphic.detailHeight, greaterThan(200));
    expect(UserTagGraphic.detailHeight, greaterThan(UserTagGraphic.cardHeight));
  });

  test('gallery photo entry keeps the cover hero tag', () {
    final entry = GalleryViewer.photoEntry(
      src: 'https://example.com/cover.jpg',
      title: 'Worship',
      heroTag: UserTagGraphic.coverHeroTag('tag-1'),
    );
    expect(entry['type'], 'img');
    expect(entry['src'], 'https://example.com/cover.jpg');
    expect(entry['heroTag'], 'user_tag_cover_tag-1');
  });

  testWidgets('tappable graphic invokes onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserTagGraphic(
            imageUrl: 'https://example.com/cover.jpg',
            height: UserTagGraphic.cardHeight,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(UserTagGraphic));
    expect(taps, 1);
  });

  testWidgets('empty imageUrl draws nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UserTagGraphic(imageUrl: ''),
        ),
      ),
    );

    final graphic = find.byType(UserTagGraphic);
    expect(graphic, findsOneWidget);
    expect(tester.getSize(graphic), Size.zero);
  });
}
