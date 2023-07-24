import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class EditGalleryPage extends StatefulWidget {
  const EditGalleryPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditGalleryPage> createState() => _EditGalleryPageState();
}

class _EditGalleryPageState extends State<EditGalleryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
        onPressed: _onAddMediaTap,
        label: const Row(
          children: [Icon(Icons.add), Text('Add Media')],
        ));
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text('Edit Gallery'),
        ),
        SliverList(
            delegate: SliverChildListDelegate([
          const Text('This is where the Key Media will be placed'),
          const Divider(),
        ])),
        SliverList.builder(
            itemCount: widget.eventContext.media.allMedia.length,
            itemBuilder: (_, index) {
              final Map<String, String> thisEntry = widget.eventContext.media.allMedia[index];
              return _buildMediaBox(thisEntry);
            })
      ],
    );
  }

  Widget _buildMediaBox(final Map<String, String> thisEntry) {
    final bool isImage = thisEntry['type']!.compareTo('img') == 0;
    return Row(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25,
          child: _buildMediaViewer(isImage, thisEntry['src']!),
        ),
        Column(
          children: [
            ListTile(
              title: Text(thisEntry['title']!),
              subtitle: Text(thisEntry['src']!),
              leading: Icon(isImage ? Icons.image : Icons.movie),
            ),
            Wrap(
              children: [
                ElevatedButton.icon(
                    onPressed: () {}, icon: const Icon(Icons.star_border), label: const Text('Key Media'))
              ],
            )
          ],
        )
      ],
    );
  }

  Widget _buildMediaViewer(bool isImage, String src) {
    if (isImage) {
      return Image.network(
        src,
        fit: BoxFit.cover,
      );
    }
    return const Text('Work out the video player!');
  }

  void _showSettings() {}

  // * Logic

  void _onAddMediaTap() {}
}
