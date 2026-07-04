import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/info/church_info.dart';
import '../../utility/app_context.dart';
import '../../utility/info_repository.dart';
import '../../widgets/information/info_image_carousel.dart';
import '../../widgets/media/cached_image_widget.dart';
import '../../widgets/quill_editor_wrapper.dart';
import 'edit_info_body_page.dart';

class ChurchInfoPage extends StatefulWidget {
  const ChurchInfoPage({super.key, required this.documentId});

  final String documentId;

  @override
  State<ChurchInfoPage> createState() => _ChurchInfoPageState();
}

class _ChurchInfoPageState extends State<ChurchInfoPage> {
  final InfoRepository _infoRepository = InfoRepository();
  late Future<ChurchInfo?> _churchFuture;

  @override
  void initState() {
    super.initState();
    _churchFuture = _loadChurch();
  }

  Future<ChurchInfo?> _loadChurch({bool forceRefresh = false}) async {
    final info = await _infoRepository.fetchChurchById(widget.documentId, forceRefresh: forceRefresh);
    if (info != null && mounted) {
      Provider.of<AppContext>(context, listen: false)
          .analytics
          .logScreenView(screenName: 'Church Info: ${info.analyticsTitle}');
    }
    return info;
  }

  Future<void> _refresh() async {
    setState(() {
      _churchFuture = _loadChurch(forceRefresh: true);
    });
    await _churchFuture;
  }

  Future<void> _openEditor(final ChurchInfo info) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditInfoBodyPage.forChurch(info: info)),
    );

    if (changed == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAreaAdmin = Provider.of<AppContext>(context).currentUser.isAreaAdmin;

    return FutureBuilder<ChurchInfo?>(
      future: _churchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Church Info')),
            body: Center(child: Text('Something went wrong: ${snapshot.error}')),
          );
        }

        final info = snapshot.data;
        if (info == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Church Info')),
            body: const Center(child: Text('No church information found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(info.title),
            actions: [
              if (isAreaAdmin)
                IconButton(
                  onPressed: () => _openEditor(info),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit church info',
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                InfoImageCarousel(
                  imageUrls: info.imageSources,
                  heroTag: 'info_church_${info.id}',
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

  Widget _buildBodyWithData(final BuildContext context, final ChurchInfo info) {
    final List<Widget> children = [
      if (info.summary.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(info.summary, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
        child: QuillViewerWidget(jsonContent: info.body),
      ),
      ..._buildGalleryImages(info.imageSources.skip(1).toList()),
      const SizedBox(height: 16),
      const SizedBox(height: 32),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  List<Widget> _buildGalleryImages(final List<String> images) {
    return images
        .map(
          (imageUrl) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
