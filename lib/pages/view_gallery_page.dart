import 'package:flutter/material.dart';

import '../widgets/media/my_photo_viewer.dart';
import '../widgets/media/my_video_player.dart';

class ViewGalleryPage extends StatefulWidget {
  const ViewGalleryPage({super.key, required this.media, required this.initialIndex, required this.postId});
  final List<Map<String, String>> media;
  final int initialIndex;
  final String postId;

  @override
  State<ViewGalleryPage> createState() => _ViewGalleryPageState();
}

class _ViewGalleryPageState extends State<ViewGalleryPage> {
  late final PageController _pageController;
  bool _dismissed = false;

  @override
  void initState() {
    _pageController = PageController(initialPage: widget.initialIndex);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: _buildBody(), backgroundColor: Colors.black);
  }

  Widget _buildBody() {
    // https://drive.google.com/file/d/1zhyUfJ7pPHPL2t78Vo8Uwf7IHHoFwDcz/view?usp=sharing
    // the above becomes
    // https://drive.google.com/uc?id=1zhyUfJ7pPHPL2t78Vo8Uwf7IHHoFwDcz
    // test this out for the video - it works!
    // https://drive.google.com/file/d/16CfgsqABldM6shwmzmYokJj9Je0xq7k2/view?usp=drive_link for an image turns into:
    // https://drive.google.com/uc?id=16CfgsqABldM6shwmzmYokJj9Je0xq7k2
    // final Map<String, String> testData = {
    //   'https://drive.google.com/uc?id=16CfgsqABldM6shwmzmYokJj9Je0xq7k2': 'image',
    //   'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4': 'video',
    //   'https://drive.google.com/uc?id=1zhyUfJ7pPHPL2t78Vo8Uwf7IHHoFwDcz': 'video'
    // };

    // final List<String> mediaSrcs = testData.keys.toList();

    return SafeArea(
      top: false,
      child: PageView.builder(
          itemCount: widget.media.length,
          controller: _pageController,
          itemBuilder: (_, index) {
            final Map<String, String> thisEntry = widget.media[index];
            return Dismissible(
              direction: DismissDirection.vertical,
              dismissThresholds: const {DismissDirection.vertical: 0.7},
              onUpdate: (details) {
                if (details.progress >= 0.6 && !_dismissed) {
                  debugPrint('Reached beyond 0.6');
                  _dismissed = true;
                  Navigator.of(context).pop();
                }
              },
              key: Key(thisEntry['src']!),
              child: Column(children: [
                Flexible(child: _buildMedia(thisEntry)),
                ListTile(
                    title: Text(thisEntry['title']!, style: const TextStyle(color: Colors.white)),
                    leading:
                        thisEntry['title']!.isNotEmpty ? const Icon(Icons.photo_library, color: Colors.white) : null)
              ]),
              onDismissed: (_) {
                Navigator.of(context).pop();
              },
            );
          }),
    );
  }

  Widget _buildMedia(final Map<String, String> thisEntry) {
    final String thisMediaSrc = thisEntry['src']!;
    final String type = thisEntry['type']!;

    if (type.compareTo('vid') == 0) {
      return MyVideoPlayer(src: thisMediaSrc);
    } else if (type.compareTo('img') == 0) {
      return MyPhotoViewer(src: thisMediaSrc); // TODO does this work with gifs?
    }

    return const Center(
      child: Text('Something went wrong'),
    );
  }
}
