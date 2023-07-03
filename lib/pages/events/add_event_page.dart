import 'package:flutter/material.dart';
import '../../models/event/event_body.dart';
import '../../models/event/event_media.dart';
import '../../utility/event_context.dart';
import '../../widgets/posts/view_post_body.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> with SingleTickerProviderStateMixin {
  bool _canSave = false;

  // * Required variables
  late final TabController _tabController;
  final EventBody _eventBody = EventBody();
  final TextEditingController _tecTitle = TextEditingController(), _tecSubtitle = TextEditingController();
  String? _location;
  DateTime? _eventDate;
  // this can only be created after the user sets the _eventDate, we need to set the finishTime
  // the metadata is created at the end when uploading everything
  // a log is created when uploading as well that higlights the publication of the app.

  // * The optional variables
  final EventMedia _eventMedia = EventMedia(srcTypes: {});
  final List<String> _contributorUIDs = List.empty(growable: true);

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tecTitle.dispose();
    _tecSubtitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(headerSliverBuilder: (_, __) => _buildHeaderSliver(), body: _buildTabBody()),
    );
  }

  List<Widget> _buildHeaderSliver() {
    return [
      SliverAppBar(
        expandedHeight: MediaQuery.of(context).size.height * 0.33,
        flexibleSpace: FlexibleSpaceBar(
          background: _buildAppBarBackground(),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(8.0),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            TabBar(
              labelColor: Colors.black,
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.info_outline),
                  text: 'Header',
                ),
                Tab(
                  icon: Icon(Icons.note),
                  text: 'Body',
                ),
                Tab(
                  icon: Icon(Icons.calendar_today),
                  text: 'Program',
                ),
                Tab(
                  icon: Icon(Icons.photo_album),
                  text: 'Media',
                ),
              ],
            ),
          ]),
        ),
      )
    ];
  }

  Widget? _buildAppBarBackground() {
    // * If there are no images, we should just remove the expanded height

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
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
      _buildHeaderMetaTabBody(),
      _buildBodyTab(),
      _buildProgramTabBody(),
      _buildMediaTabBody(),
    ]);
  }

  // TODO put to it's own Widget file
  Widget _buildHeaderMetaTabBody() {
    return ListView(
      children: [
        TextField(
          controller: _tecTitle,
          decoration: const InputDecoration(label: Text('Title'), hintText: 'Make it snappy!'),
          onChanged: _onRequiredFieldTextChange,
        ),
        TextField(
          controller: _tecSubtitle,
          onChanged: _onRequiredFieldTextChange,
          decoration: const InputDecoration(label: Text('Subtitle'), hintText: 'The synopsis of the post'),
        ),
        _buildContributorSection(),
      ],
    );
  }

  Widget _buildContributorSection() {
    final List<Widget> children = [
      const Text('Select Users who can edit certain details'),
      ElevatedButton.icon(
          onPressed: _onAddContributorClick, icon: const Icon(Icons.person_add), label: const Text('Add Contributor')),
      const Divider(),
    ];

    if (_contributorUIDs.isEmpty) {
      children.add(const Text('No one selected.'));
    } else {
      children.addAll(_contributorUIDs
          .map<Widget>((e) => ListTile(
                title: Text('UID is $e'),
              ))
          .toList());
    }

    return Column(children: children);
  }

  Widget _buildBodyTab() {
    return Column(
      children: [
        ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit), label: const Text('Edit Body')),
        ViewPostBody(eventContext: widget.eventContext),
      ],
    );
  }

  // TODO add to it's own Widget file
  Widget _buildProgramTabBody() {
    final List<Widget> children = [
      const Text('Event Date is N/A'),
      ElevatedButton(onPressed: () {}, child: const Text('Change Date')),
      SwitchListTile(
        value: widget.eventContext.programDetails.allDay,
        onChanged: _eventDate == null ? null : (value) => {},
        title: const Text('All Day'),
      )
    ];

    // only add the rest once it's been declared that this is an event via the event date
    if (_eventDate != null) {
      // TODO add the rest of the program details + role assignment
    }

    return ListView(
      children: children,
    );
  }

  // TODO make the following into it's own Widget file
  Widget _buildMediaTabBody() {
    List<String> srcs = _eventMedia.srcTypes.keys.toList();
    return Column(
      children: [
        ElevatedButton.icon(
            onPressed: () {}, icon: const Icon(Icons.add_photo_alternate_rounded), label: const Text('Add Image')),
        ElevatedButton.icon(
            onPressed: () {}, icon: const Icon(Icons.add_photo_alternate_rounded), label: const Text('Add Video')),
        Expanded(
            child: ListView.builder(
                itemCount: srcs.length,
                itemBuilder: (_, index) {
                  return Text('Image / Video box for the src: ${srcs[index]}');
                }))
      ],
    );
  }

  // * Logic
  // the core requirements of a post
  void _onRequiredFieldTextChange(String newText) {
    if (_okToSave() && !_canSave) {
      setState(() {
        _canSave = true;
      });
    } else if (!_okToSave() && _canSave) {
      setState(() {
        _canSave = false;
      });
    }
  }

  void _onAddContributorClick() {
    showDialog(
        context: context,
        builder: (_) {
          return const Dialog(
            child: Text('Complete this'),
          );
        });
  }

  bool _okToSave() {
    if (_tecTitle.text.trim().isEmpty || _tecSubtitle.text.trim().isEmpty || _location != null) {
      return false;
    }

    if (_eventBody.json!.isEmpty) {
      return false;
    }

    return true;
  }
}
