import 'package:ctrim_app/widgets/posts/add_header_meta_tab_body.dart';
import 'package:ctrim_app/widgets/posts/add_media_tab.dart';
import 'package:ctrim_app/widgets/posts/add_program_tab.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController _tecTitle = TextEditingController(), _tecSubtitle = TextEditingController();
  // this can only be created after the user sets the _eventDate, we need to set the finishTime
  // the metadata is created at the end when uploading everything
  // a log is created when uploading as well that higlights the publication of the app.

  // * The optional variables
  final List<String> _contributorUIDs = List.empty(growable: true);
  DateTime? _eventDate;

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
        actions: [
          ElevatedButton.icon(
              onPressed: _canSave ? () => _onSaveClick() : null,
              icon: const Icon(Icons.upload),
              label: const Text('Save'))
        ],
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
          tecSubtitle: _tecSubtitle,
          onRequiredFieldChange: _onRequiredFieldTextChange,
          contributorUIDs: _contributorUIDs),
      AddBodyTab(
        eventContext: widget.eventContext,
        onRequiredFieldTextChange: _onRequiredFieldTextChange,
      ),
      AddProgramTab(
        eventContext: widget.eventContext,
        eventDate: _eventDate,
      ),
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

    if (widget.eventContext.isBodyEmpty) {
      return false;
    }
    return true;
  }

  void _onSaveClick() {
    _confirmSave().then((confirmed) {
      if (confirmed) {
        _showUploadingDialog();
        _savePost().then((_) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        });
      }
    });
  }

  Future<bool> _confirmSave() async {
    bool result = false;
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Save Post'),
              content: const Text('Are you sure all details are correct?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      result = true;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save')),
              ],
            ));
    return result;
  }

  Future<void> _savePost() async {
    await widget.eventContext
        .addNewPost(title: _tecTitle.text.trim(), subtitle: _tecSubtitle.text.trim(), eventDate: _eventDate);
  }

  void _showUploadingDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Dialog(
              child: ListTile(
                title: Text('Uploading Post'),
                subtitle: Text('Please wait...'),
                trailing: CircularProgressIndicator(),
              ),
            ));
  }
}
