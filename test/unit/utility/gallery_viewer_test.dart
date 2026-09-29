import 'package:ctrim_app/utility/gallery_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GalleryViewer.visibleMedia', () {
    const media = [
      {'type': 'img', 'src': 'a'},
      {'type': 'vid', 'src': 'b'},
      {'type': 'img', 'src': 'c'},
    ];

    test('keeps videos when the grid shows them', () {
      final visible = GalleryViewer.visibleMedia(media, imagesOnly: false);
      expect(visible, same(media));
      expect(visible[1]['src'], 'b');
    });

    test('drops videos so a web grid index still opens that photo', () {
      final visible = GalleryViewer.visibleMedia(media, imagesOnly: true);
      expect(visible.map((entry) => entry['src']), ['a', 'c']);
      expect(visible[1]['src'], 'c');
    });
  });

  group('GalleryViewer.allowsPagingAndDismiss', () {
    test('stays on for a photo that is fit to the screen', () {
      expect(
        GalleryViewer.allowsPagingAndDismiss(isPhoto: true, photoIsFit: true),
        isTrue,
      );
    });

    test('turns off while a photo is zoomed', () {
      expect(
        GalleryViewer.allowsPagingAndDismiss(isPhoto: true, photoIsFit: false),
        isFalse,
      );
    });

    test('stays on for video', () {
      expect(
        GalleryViewer.allowsPagingAndDismiss(isPhoto: false, photoIsFit: false),
        isTrue,
      );
    });
  });

  group('GalleryViewer.shouldDismissDrag', () {
    test('closes after a long drag', () {
      expect(
        GalleryViewer.shouldDismissDrag(offset: 140, velocity: 0),
        isTrue,
      );
    });

    test('closes on a fast flick', () {
      expect(
        GalleryViewer.shouldDismissDrag(offset: 20, velocity: -900),
        isTrue,
      );
    });

    test('stays open on a short slow drag', () {
      expect(
        GalleryViewer.shouldDismissDrag(offset: 40, velocity: 100),
        isFalse,
      );
    });
  });

  group('GalleryViewer.formatPlaybackTime', () {
    test('formats seconds, minutes, and hours', () {
      expect(GalleryViewer.formatPlaybackTime(Duration.zero), '0:00');
      expect(
        GalleryViewer.formatPlaybackTime(const Duration(seconds: 5)),
        '0:05',
      );
      expect(
        GalleryViewer.formatPlaybackTime(const Duration(seconds: 65)),
        '1:05',
      );
      expect(
        GalleryViewer.formatPlaybackTime(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '1:02:03',
      );
    });

    test('treats a negative position as zero', () {
      expect(
        GalleryViewer.formatPlaybackTime(const Duration(seconds: -4)),
        '0:00',
      );
    });
  });
}
