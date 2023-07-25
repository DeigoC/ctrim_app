import 'package:ctrim_app/pages/events/edit_title_subtitle_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event/event_head.dart';
import '../../utility/event_context.dart';
import '../../widgets/posts/post_metadata_section.dart';
import '../../widgets/posts/view_event_media_tab.dart';
import '../../widgets/posts/view_post_body.dart';
import '../../widgets/posts/view_all_programs.dart';
import '../../widgets/posts/view_related_posts_tab.dart';

class ViewEventPage extends StatefulWidget {
  const ViewEventPage({super.key, required this.eventHead, required this.viewingChild});
  final EventHead eventHead;
  final bool viewingChild;

  @override
  State<ViewEventPage> createState() => _ViewEventPageState();
}

class _ViewEventPageState extends State<ViewEventPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final EventContext _eventContext;
  late final List<Map<String, String>> _originalHeadMedia;
  late final String _originalTitle, _originalSubtitle;

  @override
  void initState() {
    // ? This tab issue thing with Program will depend on:
    // - if eventDate in Head is null then don't build it unless it's a leader
    // - viewing it (we can't make sure it's the author viewing it without the meta)
    _originalHeadMedia = List<Map<String, String>>.from(widget.eventHead.media);
    _originalTitle = widget.eventHead.title;
    _originalSubtitle = widget.eventHead.subtitle;

    _tabController = TabController(length: 4, vsync: this);
    _eventContext = EventContext.viewing(eventHead: widget.eventHead, viewingChild: widget.viewingChild);

    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _eventContext.canSaveTheEditing
            ? () => DialogManager.discardChanges(context: context).then((confirmation) {
                  if (confirmation) {
                    widget.eventHead.resetMediaWithOriginal(_originalHeadMedia);
                    widget.eventHead.setTitle(_originalTitle);
                    widget.eventHead.setSubtitle(_originalSubtitle);
                  }
                  return confirmation;
                })
            : () async => true,
        child: Scaffold(body: _buildBody()));
  }

  Widget _buildBody() {
    return NestedScrollView(
        headerSliverBuilder: (_, __) {
          return _buildHeaderSliver();
        },
        body: _buildTabBody());
  }

  List<Widget> _buildHeaderSliver() {
    return [
      SliverAppBar(
        expandedHeight: MediaQuery.of(context).size.height * 0.33,
        flexibleSpace: FlexibleSpaceBar(background: _buildAppBarBackground()),
        actions: [
          _buildAppBarAction(),
          const SizedBox(width: 8),
        ],
      ),
      SliverList(
          delegate: SliverChildListDelegate([
        Padding(padding: const EdgeInsets.all(8.0), child: _buildTitle()),
        PostMetadataSection(
          eventContext: _eventContext,
          update: _update,
        ),
        TabBar(labelColor: Colors.black, controller: _tabController, tabs: const [
          Tab(icon: Icon(Icons.info_outline), text: 'About'),
          Tab(icon: Icon(Icons.calendar_today), text: 'Program'),
          Tab(icon: Icon(Icons.photo_album), text: 'Media'),
          Tab(icon: Icon(Icons.library_books), text: 'Related')
        ])
      ])),
    ];
  }

  Widget _buildTitle() {
    return InkWell(onTap: _onTitleTap, child: Text(widget.eventHead.title, style: const TextStyle(fontSize: 28)));
  }

  Widget? _buildAppBarBackground() {
    // * If there are no images, we should just remove the expanded height
    final String? keyGraphicSrc = _eventContext.head.getKeyGraphic();
    if (keyGraphicSrc != null) {
      return Image.network(keyGraphicSrc, fit: BoxFit.cover);
    }
    return null;
  }

  Widget _buildTabBody() {
    return TabBarView(controller: _tabController, children: [
      ViewPostBody(eventContext: _eventContext, updateBody: _update),
      ViewAllPrograms(eventContext: _eventContext, onProgramChanged: _update),
      ViewEventMediaTab(eventContext: _eventContext, onMediaEdit: _update),
      ViewRelatedPostsTab(eventContext: _eventContext)
    ]);
  }

  void _update() => setState(() {});

  Widget _buildAppBarAction() {
    String uid = Provider.of<AppContext>(context, listen: false).currentUser.id;
    if (_eventContext.fetchedMetadata) {
      if (_eventContext.isUserAdminOfPost(uid)) {
        return ElevatedButton.icon(
            style: ButtonStyle(
                backgroundColor: _eventContext.canSaveTheEditing
                    ? const MaterialStatePropertyAll<Color>(Colors.green)
                    : const MaterialStatePropertyAll<Color>(Colors.grey),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)))),
            onPressed: _eventContext.canSaveTheEditing ? () {} : null,
            icon: const Icon(Icons.save),
            label: const Text('Update'));
      } else {
        return IconButton.filled(onPressed: _bookmarkClick, icon: const Icon(Icons.bookmark_border));
      }
    }
    return const Center(child: CircularProgressIndicator());
  }

  void _bookmarkClick() {}

  void _onTitleTap() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditHeadDetailsPage(eventContext: _eventContext)))
        .then((_) {
      setState(() {});
    });
  }
}
