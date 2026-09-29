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

  group('GalleryViewer.photoEntries', () {
    test('keeps order, skips blanks, and stamps hero tags', () {
      final entries = GalleryViewer.photoEntries(
        srcs: ['a', '', 'b'],
        title: 'Team',
        heroTagFor: (src) => 'tag-$src',
      );
      expect(entries.map((entry) => entry['src']), ['a', 'b']);
      expect(entries.first['heroTag'], 'tag-a');
      expect(entries.first['title'], 'Team');
      expect(entries.first['type'], 'img');
    });

    test('finds the tapped photo and falls back to the first', () {
      final media = GalleryViewer.photoEntries(srcs: ['a', 'b']);
      expect(GalleryViewer.indexForSrc(media, 'b'), 1);
      expect(GalleryViewer.indexForSrc(media, 'missing'), 0);
    });
  });

  group('GalleryViewer hero tags', () {
    test('uses the thumbnail tag when one was passed', () {
      expect(
        GalleryViewer.resolvedHeroTag(
          useHero: true,
          explicitTag: 'group-photo',
          fallbackTag: 'postsrc',
        ),
        'group-photo',
      );
    });

    test('uses the post thumbnail tag when none was passed', () {
      expect(
        GalleryViewer.resolvedHeroTag(
          useHero: true,
          explicitTag: null,
          fallbackTag: 'postsrc',
        ),
        'postsrc',
      );
    });

    test('skips the hero when the open has no matching source', () {
      expect(
        GalleryViewer.resolvedHeroTag(
          useHero: false,
          explicitTag: 'group-photo',
          fallbackTag: 'postsrc',
        ),
        isNull,
      );
    });

    test('attaches a hero only on the visible page', () {
      expect(
        GalleryViewer.attachHero(
          useHero: true,
          isCurrentPage: true,
          heroTag: 'tag-a',
        ),
        isTrue,
      );
      expect(
        GalleryViewer.attachHero(
          useHero: true,
          isCurrentPage: false,
          heroTag: 'tag-b',
        ),
        isFalse,
      );
    });
  });
}
