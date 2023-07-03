import 'package:ctrim_app/widgets/posts/add_header_meta_tab_body.dart';
import 'package:ctrim_app/widgets/posts/add_media_tab.dart';
import 'package:ctrim_app/widgets/posts/add_program_tab.dart';
import 'package:flutter/material.dart';
import '../../models/event/event_body.dart';
import '../../utility/event_context.dart';
import '../../widgets/posts/add_body_tab.dart';

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
  // this can only be created after the user sets the _eventDate, we need to set the finishTime
  // the metadata is created at the end when uploading everything
  // a log is created when uploading as well that higlights the publication of the app.

  // * The optional variables
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
      AddEventHeadMeta(
          tecTitle: _tecTitle,
          tecSubTitle: _tecSubtitle,
          onRequiredFieldChange: _onRequiredFieldTextChange,
          contributorUIDs: _contributorUIDs),
      AddBodyTab(
        eventContext: widget.eventContext,
      ),
      AddProgramTab(eventContext: widget.eventContext),
      AddMediaTabBody(
        eventContext: widget.eventContext,
      ),
    ]);
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

  bool _okToSave() {
    if (_tecTitle.text.trim().isEmpty || _tecSubtitle.text.trim().isEmpty) {
      return false;
    }

    if (_eventBody.json!.isEmpty) {
      return false;
    }

    return true;
  }
}
