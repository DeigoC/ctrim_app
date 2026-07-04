import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/info/testimonial_into.dart';
import '../../utility/app_context.dart';
import '../../utility/info_repository.dart';
import '../../widgets/information/info_image_carousel.dart';
import '../../widgets/media/cached_image_widget.dart';
import '../../widgets/quill_editor_wrapper.dart';
import 'edit_info_body_page.dart';

class TestimonialInfoPage extends StatefulWidget {
  const TestimonialInfoPage({super.key, required this.documentId});

  final String documentId;

  @override
  State<TestimonialInfoPage> createState() => _TestimonialInfoPageState();
}

class _TestimonialInfoPageState extends State<TestimonialInfoPage> {
  final InfoRepository _infoRepository = InfoRepository();
  late Future<TestimonialInfo?> _testimonialFuture;

  @override
  void initState() {
    super.initState();
    _testimonialFuture = _loadTestimonial();
  }

  Future<TestimonialInfo?> _loadTestimonial({bool forceRefresh = false}) async {
    return _infoRepository.fetchTestimonialById(widget.documentId, forceRefresh: forceRefresh);
  }

  Future<void> _refresh() async {
    setState(() {
      _testimonialFuture = _loadTestimonial(forceRefresh: true);
    });
    await _testimonialFuture;
  }

  Future<void> _openEditor(final TestimonialInfo info) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditInfoBodyPage.forTestimonial(info: info)),
    );

    if (changed == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAreaAdmin = Provider.of<AppContext>(context).currentUser.isAreaAdmin;

    return FutureBuilder<TestimonialInfo?>(
      future: _testimonialFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Testimonial')),
            body: Center(child: Text('Something went wrong: ${snapshot.error}')),
          );
        }

        final info = snapshot.data;
        if (info == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Testimonial')),
            body: const Center(child: Text('No testimonial found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Testimonial'),
            actions: [
              if (isAreaAdmin)
                IconButton(
                  onPressed: () => _openEditor(info),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit testimonial',
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                InfoImageCarousel(
                  imageUrls: info.imageSources,
                  heroTag: 'info_testimonial_${info.id}',
                  height: MediaQuery.of(context).size.height * 0.4,
                ),
                _buildBodyWithData(context, info),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyWithData(final BuildContext context, final TestimonialInfo info) {
    final List<Widget> children = [
      Text(info.name, style: const TextStyle(fontSize: 32)),
      Text(info.church, style: const TextStyle(fontSize: 16)),
      if (info.summary.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(info.summary, style: Theme.of(context).textTheme.titleMedium),
      ],
      const SizedBox(height: 8),
      const Divider(),
      const SizedBox(height: 8),
      QuillViewerWidget(jsonContent: info.body),
      ..._buildGalleryImages(info.imageSources.skip(1).toList()),
      const SizedBox(height: 32)
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  List<Widget> _buildGalleryImages(final List<String> images) {
    return images
        .map(
          (imageUrl) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedImageWidget(imageUrl: imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
        )
        .toList();
  }
}
