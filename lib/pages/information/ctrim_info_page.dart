import 'package:ctrim_app/models/info/ctrim_info.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utility/info_repository.dart';
import '../../widgets/information/info_image_carousel.dart';
import '../../widgets/quill_editor_wrapper.dart';
import 'edit_info_body_page.dart';

class CTRIMInfoPage extends StatefulWidget {
  const CTRIMInfoPage({super.key, required this.documentId});

  final String documentId;

  @override
  State<CTRIMInfoPage> createState() => _CTRIMInfoPageState();
}

class _CTRIMInfoPageState extends State<CTRIMInfoPage> {
  final InfoRepository _infoRepository = InfoRepository();
  late Future<CtrimInfo?> _infoFuture;

  @override
  void initState() {
    super.initState();
    _infoFuture = _loadInfo();
  }

  Future<CtrimInfo?> _loadInfo({bool forceRefresh = false}) async {
    final info = await _infoRepository.fetchCtrimInfoById(widget.documentId, forceRefresh: forceRefresh);
    if (info != null && mounted) {
      Provider.of<AppContext>(context, listen: false)
          .analytics
          .logScreenView(screenName: 'CTRIM Info: ${info.analyticsTitle}');
    }
    return info;
  }

  Future<void> _refresh() async {
    setState(() {
      _infoFuture = _loadInfo(forceRefresh: true);
    });
    await _infoFuture;
  }

  Future<void> _openEditor(final CtrimInfo info) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditInfoBodyPage.forCtrim(info: info)),
    );

    if (changed == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AppContext>(context).currentUser.isAreaAdmin;

    return FutureBuilder<CtrimInfo?>(
      future: _infoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('CTRIM Information')),
            body: Center(child: Text('Something went wrong: ${snapshot.error}')),
          );
        }

        final info = snapshot.data;
        if (info == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('CTRIM Information')),
            body: const Center(child: Text('No information found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(info.title),
            actions: [
              if (isAdmin)
                IconButton(
                  onPressed: () => _openEditor(info),
                  icon: const Icon(Icons.edit),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                if (info.imageSources.isNotEmpty)
                  InfoImageCarousel(
                    imageUrls: info.imageSources,
                    heroTag: 'info_ctrim_${info.id}',
                    height: MediaQuery.of(context).size.height * 0.32,
                  ),
                _buildBodyWithData(context, info),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyWithData(final BuildContext context, final CtrimInfo ctrimInfo) {
    debugPrint('Body is ${ctrimInfo.body}');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ctrimInfo.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(ctrimInfo.description, style: Theme.of(context).textTheme.titleMedium),
          ),
        const Divider(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: QuillViewerWidget(
            jsonContent: ctrimInfo.body,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
