import 'package:ctrim_app/models/event/event_head.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/event/event_program.dart';
import '../../utility/event_context.dart';
import '../../widgets/posts/rich_text_view.dart';
import '../../widgets/view_all_programs.dart';

class ViewEventPage extends StatefulWidget {
  const ViewEventPage({super.key});

  @override
  State<ViewEventPage> createState() => _ViewEventPageState();
}

class _ViewEventPageState extends State<ViewEventPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final EventContext _eventContext;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _eventContext = EventContext.viewing(eventHead: EventHead(id: '1', media: {}, eventDate: DateTime.now()));
    _eventContext.addManyRoles([
      EventRole(
          id: '1',
          title: 'Role 1',
          startTime: DateTime.now(),
          finishTime: DateTime.now().add(const Duration(minutes: 20))),
      EventRole(
          id: '2',
          title: 'Role 2',
          startTime: DateTime.now(),
          finishTime: DateTime.now().add(const Duration(minutes: 35))),
      EventRole(
          id: '3',
          title: 'Role 3',
          startTime: DateTime.now().add(const Duration(hours: 1)),
          finishTime: DateTime.now().add(const Duration(hours: 1, minutes: 20))),
      EventRole(
          id: '4',
          title: 'Role 4',
          startTime: DateTime.now().add(const Duration(minutes: 30)),
          finishTime: DateTime.now().add(const Duration(minutes: 45))),
    ]);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
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
        flexibleSpace: FlexibleSpaceBar(
          background: _buildAppBarBackground(),
        ),
        actions: [IconButton(onPressed: () => _onSettingsClick(), icon: const Icon(Icons.more_vert))],
      ),
      SliverPadding(
        padding: const EdgeInsets.all(8.0),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildTitle(),
            TabBar(
              labelColor: Colors.black,
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.info_outline),
                  text: 'About',
                ),
                Tab(
                  icon: Icon(Icons.calendar_today),
                  text: 'Program',
                ),
              ],
            ),
          ]),
        ),
      )
    ];
  }

  Widget _buildTitle() {
    return const Text(
      'Here is the title for the post!',
      style: TextStyle(fontSize: 28),
    );
  }

  Widget? _buildAppBarBackground() {
    // * If there are no images, we should just remove the expanded height

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // we need to transform the below to a slideshow thingy maflob. Clickable as well
        Positioned.fill(
          child: Image.network(
            'https://assets.gocomics.com/uploads/collection_images/collection_image_large_1721649_Garfield_Sandwich_V2_201805291007.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBody() {
    return TabBarView(controller: _tabController, children: [
      EventBodyView(
        eventContext: _eventContext,
      ),
      ViewAllPrograms(eventContext: _eventContext)
    ]);
  }

  _onSettingsClick() {
    showModalBottomSheet(
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        context: context,
        builder: (_) {
          return SafeArea(
              child: EventPostSettingsSheet(
            eventContext: _eventContext,
          ));
        });
  }
}

class EventPostSettingsSheet extends StatefulWidget {
  const EventPostSettingsSheet({super.key, required this.eventContext});
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
          ListTile(
            title: const Text('Edit Body'),
            leading: const Icon(Icons.edit_note),
            onTap: () => _openEditBodyPage(),
          ),
          ListTile(
            title: const Text('Edit Gallery'),
            leading: const Icon(Icons.photo_album),
            onTap: () => _openEditGalleryPage(),
          ),
          ListTile(
            title: const Text('Edit More Details'),
            leading: const Icon(Icons.note_alt),
            onTap: () => _openEditMoreDetailsPage(),
          ),
        ],
      ),
    );
  }

  // * LOGIC
  _openEditBodyPage() {
    context.goNamed('edit_body', extra: widget.eventContext);
  }

  _openEditGalleryPage() {
    context.goNamed('edit_gallery', extra: widget.eventContext);
  }

  _openEditMoreDetailsPage() {
    context.goNamed('edit_header_page', extra: widget.eventContext);
  }
}
