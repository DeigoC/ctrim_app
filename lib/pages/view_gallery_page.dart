import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../utility/app_context.dart';
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
  bool _dismissed = false, _lockScreen = false;

  final Map<String, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    _pageController = PageController(initialPage: widget.initialIndex);
    Provider.of<AppContext>(context, listen: false)
        .analytics
        .setCurrentScreen(screenName: 'Post Gallery: ${widget.postId}');

    for (final entry in widget.media) {
      if (entry['type'] == 'vid') {
        _videoControllers[entry['src']!] = VideoPlayerController.networkUrl(Uri.parse(entry['src']!));
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    for (final vidController in _videoControllers.values) {
      vidController.dispose();
    }

    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(), backgroundColor: Colors.black);
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
            onPageChanged: (newIndex) {
              debugPrint('the new index is $newIndex');
              for (var videoPlayer in _videoControllers.values) {
                // pause all videos that aren't the current one being switched to
                if (videoPlayer.value.isInitialized &&
                    widget.media.indexWhere((entry) => entry['src']!.compareTo(videoPlayer.dataSource) == 0) !=
                        newIndex) {
                  videoPlayer.pause();
                  videoPlayer.seekTo(Duration.zero);
                } else {
                  videoPlayer.play();
                }
              }
            },
            physics: _lockScreen ? const NeverScrollableScrollPhysics() : null,
            itemCount: widget.media.length,
            controller: _pageController,
            itemBuilder: (_, index) => _lockScreen ? _buildMediaBody(index) : _buildWithDismissible(index)));
  }

  Widget _buildWithDismissible(int index) {
    return Dismissible(
        movementDuration: const Duration(milliseconds: 800),
        direction: DismissDirection.vertical,
        dismissThresholds: const {DismissDirection.vertical: 0.4},
        onUpdate: (details) {
          if (details.progress >= 0.4 && !_dismissed) {
            // debugPrint('Reached beyond 0.4');
            _dismissed = true;
            Navigator.of(context).pop();
          }
        },
        key: Key(index.toString()),
        child: _buildMediaBody(index),
        onDismissed: (_) {
          Navigator.of(context).pop();
        });
  }

  Widget _buildMediaBody(int index) {
    final Map<String, String> thisEntry = widget.media[index];
    final List<Widget> children = [
      Positioned.fill(child: _buildMediaView(thisEntry)),
    ];

    if (!_lockScreen) {
      children.addAll([
        Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: SizedBox(
                height: kToolbarHeight,
                child: AppBar(
                  backgroundColor: Colors.transparent.withOpacity(0.3),
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [IconButton(onPressed: _onHelpClick, icon: const Icon(Icons.help))],
                ),
              ),
            )),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            color: Colors.black.withOpacity(0.55),
            child: ListTile(
                title: Text(thisEntry['title']!, style: const TextStyle(color: Colors.white)),
                leading: const Icon(Icons.photo_library, color: Colors.white)),
          ),
        )
      ]);
    } else {
      children.add(const Align(
        alignment: Alignment.bottomCenter,
        child: ListTile(leading: Icon(Icons.lock, color: Colors.white)),
      ));
    }

    return Stack(
      alignment: Alignment.center,
      children: children,
    );
  }

  Widget _buildMediaView(final Map<String, String> thisEntry) {
    final String thisMediaSrc = thisEntry['src']!;
    final String type = thisEntry['type']!;

    if (type.compareTo('vid') == 0) {
      return MyVideoPlayer(
          src: thisMediaSrc,
          postID: widget.postId,
          onLockTap: _onLockTap,
          showControls: !_lockScreen,
          videoPlayerController: _videoControllers[thisMediaSrc]!);
    } else if (type.compareTo('img') == 0) {
      return MyPhotoViewer(src: thisMediaSrc, postID: widget.postId, onLockTap: _onLockTap);
    }

    return const Center(child: Text('Something went wrong'));
  }

  // * Logic
  void _onLockTap() {
    // we will rerbuild without the appbar, with lock scoll physics and without the dismissable
    setState(() {
      _lockScreen = !_lockScreen;
    });
  }

  void _onHelpClick() {
    DialogManager.showAlertDialog(
        context: context,
        title: 'Viewing Media',
        content:
            "Because of the many scrolling effects in place, please tap the screen once to toggle the 'locking' of the page.\n\nThis allows you to pinch in and out of images as well as to scrub through videos (which can be tricky!)");
  }
}
