import 'package:ctrim_app/utility/image_orientation.dart';
import 'package:ctrim_app/utility/info_detail_aside_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InfoDetailAsideLayout.pinLeadImage', () {
    const wide = 1200.0;

    test('pins a portrait on a wide testimonial', () {
      expect(
        InfoDetailAsideLayout.pinLeadImage(
          enabled: true,
          availableWidth: wide,
          hasLeadImage: true,
          orientationKnown: true,
          leadOrientation: ImageOrientation.portrait,
        ),
        isTrue,
      );
    });

    test('pins a square headshot', () {
      expect(
        InfoDetailAsideLayout.pinLeadImage(
          enabled: true,
          availableWidth: wide,
          hasLeadImage: true,
          orientationKnown: true,
          leadOrientation: ImageOrientation.square,
        ),
        isTrue,
      );
    });

    test('pins while the lead image is still being measured', () {
      expect(
        InfoDetailAsideLayout.pinLeadImage(
          enabled: true,
          availableWidth: wide,
          hasLeadImage: true,
          orientationKnown: false,
          leadOrientation: null,
        ),
        isTrue,
      );
    });

    test('keeps a landscape photo as a banner', () {
      expect(
        InfoDetailAsideLayout.pinLeadImage(
          enabled: true,
          availableWidth: wide,
          hasLeadImage: true,
          orientationKnown: true,
          leadOrientation: ImageOrientation.landscape,
        ),
        isFalse,
      );
    });

    test('stays stacked when the window is too narrow', () {
      expect(
        InfoDetailAsideLayout.pinLeadImage(
          enabled: true,
          availableWidth: InfoDetailAsideLayout.minWidth - 1,
          hasLeadImage: true,
          orientationKnown: true,
          leadOrientation: ImageOrientation.portrait,
        ),
        isFalse,
      );
    });

    test('stays stacked when the page did not opt in', () {
      expect(
        InfoDetailAsideLayout.pinLeadImage(
          enabled: false,
          availableWidth: wide,
          hasLeadImage: true,
          orientationKnown: true,
          leadOrientation: ImageOrientation.portrait,
        ),
        isFalse,
      );
    });

    test('stays stacked when there is no lead image', () {
      expect(
        InfoDetailAsideLayout.pinLeadImage(
          enabled: true,
          availableWidth: wide,
          hasLeadImage: false,
          orientationKnown: false,
          leadOrientation: null,
        ),
        isFalse,
      );
    });

    test('stays stacked when measuring the lead image failed', () {
      expect(
        InfoDetailAsideLayout.pinLeadImage(
          enabled: true,
          availableWidth: wide,
          hasLeadImage: true,
          orientationKnown: true,
          leadOrientation: null,
        ),
        isFalse,
      );
    });
  });

  group('InfoDetailAsideLayout.railWidthFor', () {
    test('clamps the rail between the min and max', () {
      expect(
        InfoDetailAsideLayout.railWidthFor(400),
        InfoDetailAsideLayout.minRailWidth,
      );
      expect(
        InfoDetailAsideLayout.railWidthFor(2000),
        InfoDetailAsideLayout.maxRailWidth,
      );
      expect(
        InfoDetailAsideLayout.railWidthFor(1000),
        closeTo(1000 * InfoDetailAsideLayout.railFraction, 0.01),
      );
    });
  });
}
