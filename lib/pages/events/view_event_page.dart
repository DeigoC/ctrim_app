import 'package:ctrim_app/pages/events/add_event_page.dart';
import 'package:ctrim_app/widgets/posts/post_metadata_section.dart';
import 'package:flutter/material.dart';
import '../../models/event/event_head.dart';
import '../../utility/event_context.dart';
import '../../widgets/posts/view_event_media_tab.dart';
import '../../widgets/posts/view_post_body.dart';
import '../../widgets/posts/view_all_programs.dart';
import '../../widgets/posts/view_related_posts_tab.dart';
import 'edit_body_page.dart';
import 'edit_gallery_page.dart';

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

  @override
  void initState() {
    // ? This tab issue thing with Program will depend on:
    // - if eventDate in Head is null then don't build it unless it's a leader
    // - viewing it (we can't make sure it's the author viewing it without the meta)
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
    return Scaffold(body: _buildBody());
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
          ElevatedButton.icon(
              onPressed: _eventContext.canSaveTheEditing ? () {} : null,
              icon: const Icon(Icons.save),
              label: const Text('Update')),
          IconButton(onPressed: () => _onSettingsClick(), icon: const Icon(Icons.more_vert))
        ],
      ),
      SliverList(
          delegate: SliverChildListDelegate([
        Padding(padding: const EdgeInsets.all(8.0), child: _buildTitle()),
        PostMetadataSection(eventContext: _eventContext),
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
    return Text(widget.eventHead.title, style: const TextStyle(fontSize: 28));
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
      ViewPostBody(eventContext: _eventContext),
      ViewAllPrograms(
          eventContext: _eventContext,
          onProgramChanged: () {
            // ! I don't like this! But I want a quick and simple way to update the save button
            setState(() {});
          }),
      ViewEventMediaTab(eventContext: _eventContext),
      ViewRelatedPostsTab(eventContext: _eventContext)
    ]);
  }

  void _onSettingsClick() {
    showModalBottomSheet(
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        context: context,
        builder: (_) {
          return SafeArea(
              child: EventPostSettingsSheet(
            onEditUpdate: () => setState(() {}),
            eventContext: _eventContext,
          ));
        });
  }
}

class EventPostSettingsSheet extends StatefulWidget {
  const EventPostSettingsSheet({super.key, required this.eventContext, required this.onEditUpdate});
  final Function onEditUpdate;
  final EventContext eventContext;

  @override
  State<EventPostSettingsSheet> createState() => _EventPostSettingsSheetState();
}

class _EventPostSettingsSheetState extends State<EventPostSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ListTile(title: const Text('Edit Body'), leading: const Icon(Icons.edit_note), onTap: _openEditBodyPage),
          ListTile(
              title: const Text('Edit Gallery'), leading: const Icon(Icons.photo_album), onTap: _openEditGalleryPage),
          ListTile(title: const Text('Create Post'), leading: const Icon(Icons.note_add), onTap: _openAddChildPost)
        ],
      ),
    );
  }

  // * LOGIC
  void _openEditBodyPage() {
    // context.goNamed('edit_body', extra: widget.eventContext);
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditBodyPage(eventContext: widget.eventContext)))
        .then((_) {
      widget.onEditUpdate();
    });
  }

  void _openEditGalleryPage() {
    // context.goNamed('edit_gallery', extra: widget.eventContext);
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditGallerlyPage(eventContext: widget.eventContext)))
        .then((_) {
      widget.onEditUpdate();
    });
  }

  void _openAddChildPost() {
    Navigator.of(context).pop();
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddEventPage(eventContext: EventContext.adding(parentID: widget.eventContext.head.id))))
        .then((_) {
      widget.onEditUpdate();
    });
  }
}
