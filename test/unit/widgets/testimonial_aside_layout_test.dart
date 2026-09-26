import 'package:ctrim_app/pages/information/info_detail_body.dart';
import 'package:ctrim_app/utility/image_orientation.dart';
import 'package:ctrim_app/widgets/information/info_image_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _page({required ImageOrientation orientation}) {
  return MaterialApp(
    home: Scaffold(
      body: InfoDetailAsideHost(
        imageUrls: const ['https://example.com/portrait.jpg'],
        heroTag: 'info_testimonial_test',
        body: const [],
        header: const Text('Maije Gobaton'),
        belowBody: const Text('Story starts here'),
        onRefresh: _refresh,
        knownLeadOrientation: orientation,
      ),
    ),
  );
}

void _setWindow(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _refresh() async {}

void main() {
  testWidgets('wide portrait testimonial puts the photo left of the story',
      (tester) async {
    _setWindow(tester, const Size(1400, 900));

    await tester.pumpWidget(_page(orientation: ImageOrientation.portrait));

    final photo = tester.getTopLeft(find.byType(InfoImageCarousel));
    final name = tester.getTopLeft(find.text('Maije Gobaton'));
    final story = tester.getTopLeft(find.text('Story starts here'));

    expect(photo.dx, lessThan(story.dx - 200));
    expect(name.dx, lessThan(story.dx - 200));
    expect(name.dy, greaterThan(photo.dy));
  });

  testWidgets('desktop-width portrait still puts the photo on the left',
      (tester) async {
    _setWindow(tester, const Size(1000, 900));
    await tester.pumpWidget(_page(orientation: ImageOrientation.portrait));

    final photo = tester.getTopLeft(find.byType(InfoImageCarousel));
    final story = tester.getTopLeft(find.text('Story starts here'));
    expect(photo.dx, lessThan(story.dx - 200));
  });

  testWidgets('narrow portrait keeps the story under the name', (tester) async {
    _setWindow(tester, const Size(500, 900));
    await tester.pumpWidget(_page(orientation: ImageOrientation.portrait));

    final name = tester.getTopLeft(find.text('Maije Gobaton'));
    final story = tester.getTopLeft(find.text('Story starts here'));

    expect(story.dy, greaterThan(name.dy + 20));
    expect((story.dx - name.dx).abs(), lessThan(40));
  });

  testWidgets('wide landscape photo stays above the story', (tester) async {
    _setWindow(tester, const Size(1400, 900));

    await tester.pumpWidget(_page(orientation: ImageOrientation.landscape));

    final name = tester.getTopLeft(find.text('Maije Gobaton'));
    final story = tester.getTopLeft(find.text('Story starts here'));
    expect(story.dy, greaterThan(name.dy + 20));
  });
}
