import 'package:ctrim_app/widgets/video_player.dart';
import 'package:flutter/material.dart';

class ViewGalleryPage extends StatefulWidget {
  const ViewGalleryPage({super.key});

  @override
  State<ViewGalleryPage> createState() => _ViewGalleryPageState();
}

class _ViewGalleryPageState extends State<ViewGalleryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // https://drive.google.com/file/d/1zhyUfJ7pPHPL2t78Vo8Uwf7IHHoFwDcz/view?usp=sharing
    // the above becomes
    // https://drive.google.com/uc?id=1zhyUfJ7pPHPL2t78Vo8Uwf7IHHoFwDcz
    // test this out

    final Map<String, String> testData = {
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4': 'video',
      'https://drive.google.com/uc?id=1zhyUfJ7pPHPL2t78Vo8Uwf7IHHoFwDcz': 'video'
    };

    final List<String> mediaSrcs = testData.keys.toList();

    return PageView.builder(
        itemCount: mediaSrcs.length,
        itemBuilder: (_, index) {
          final String thisMediaSrc = mediaSrcs[index];
          final String type = testData[thisMediaSrc]!;

          if (type.compareTo('video') == 0) {
            return MyVideoPlayer(
              src: thisMediaSrc,
            );
          }

          return const Center(
            child: Text('Something went wrong'),
          );
        });
  }
}
