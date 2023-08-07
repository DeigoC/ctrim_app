import 'package:ctrim_app/firebase/functions_manager.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/widgets/posts/add_header_meta_tab_body.dart';
import 'package:ctrim_app/widgets/posts/view_all_programs.dart';
import 'package:ctrim_app/widgets/posts/view_event_media_tab.dart';
import 'package:ctrim_app/widgets/posts/view_post_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../firebase/db_managers/event_db_manager.dart';
import '../../utility/event_context.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> with SingleTickerProviderStateMixin {
  // * Required variables
  late final AppContext _appContext;
  late final TabController _tabController;
  final TextEditingController _tecTitle = TextEditingController(), _tecSubtitle = TextEditingController();

  // * The optional variables
  final List<String> _contributorUIDs = List<String>.empty(growable: true);

  bool _canSave = false;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
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
        body: NestedScrollView(headerSliverBuilder: (_, __) => _buildHeaderSliver(), body: _buildTabBody()));
  }

  List<Widget> _buildHeaderSliver() {
    final bool onDark = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;

    return [
      SliverAppBar(
        expandedHeight: MediaQuery.of(context).size.height * 0.33,
        flexibleSpace: FlexibleSpaceBar(background: _buildAppBarBackground()),
        actions: [
          ElevatedButton.icon(
              onPressed: _canSave ? _onSaveClick : null,
              icon: const Icon(Icons.upload),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green))
        ],
      ),
      SliverPadding(
          padding: const EdgeInsets.all(8.0),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            TabBar(
              labelColor: onDark ? Colors.white : Colors.black,
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline), text: 'Header'),
                Tab(icon: Icon(Icons.note), text: 'Info'),
                Tab(icon: Icon(Icons.calendar_today), text: 'Program'),
                Tab(icon: Icon(Icons.photo_album), text: 'Media')
              ],
            )
          ])))
    ];
  }

  Widget? _buildAppBarBackground() {
    // * If there are no images, we should just remove the expanded height
    if (widget.eventContext.head.getKeyGraphic() == null) {
      return null;
    }
    return Stack(
      alignment: Alignment.bottomRight,
      children: [Positioned.fill(child: Image.network(widget.eventContext.head.getKeyGraphic()!, fit: BoxFit.cover))],
    );
  }

  Widget _buildTabBody() {
    return TabBarView(controller: _tabController, children: [
      AddEventHeadMeta(
          tecTitle: _tecTitle,
          tecSubtitle: _tecSubtitle,
          onRequiredFieldChange: _onRequiredFieldTextChange,
          contributorUIDs: _contributorUIDs),
      ViewPostBody(
          eventContext: widget.eventContext, updateBody: () => _updateBody(), currentUID: _appContext.currentUser.id),
      ViewAllPrograms(eventContext: widget.eventContext, onProgramChanged: () => _updateBody(), isAddingPost: true),
      ViewEventMediaTab(
          eventContext: widget.eventContext, onMediaEdit: () => _updateBody(), currentUID: _appContext.currentUser.id)
    ]);
  }

  // * Logic

  void _updateBody() {
    setState(() {});
    _onRequiredFieldTextChange('');
  }

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

  // the core requirements of a post - title, subtitle, an update to the body
  bool _okToSave() {
    if (_tecTitle.text.trim().isEmpty || _tecSubtitle.text.trim().isEmpty) {
      return false;
    }

    if (widget.eventContext.isBodyUntouched) {
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
    final appContext = Provider.of<AppContext>(context, listen: false);
    await widget.eventContext
        .addNewPost(
            title: _tecTitle.text.trim(),
            subtitle: _tecSubtitle.text.trim(),
            eventDate: widget.eventContext.head.eventDate,
            uid: appContext.currentUser.id)
        .then((newID) => _updateParentMetadata(newID));
    await _notifyOfNewPost();
    await _notifyContributorAdditions();

    appContext.addNewPostHead(widget.eventContext.head);
  }

  void _updateParentMetadata(String thisPostID) {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final String parentID = widget.eventContext.metadata.parentID!;
    final metadata = appContext.getMetadata(parentID)!;
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(parentID);
    final EventHeadDBManager headDBManager = EventHeadDBManager();
    final parentHead = appContext.eventHeads.firstWhere((element) => element.id.compareTo(parentID) == 0);

    metadata.addChildID(thisPostID);
    dbManager.updateMetadata(metadata);

    // add a log and update the head's recentdate so that people can have their parent post instance updated
    final now = DateTime.now();
    dbManager.addLogEntry(
        log: "Created related post: '${widget.eventContext.head.title}'", uid: appContext.currentUser.id, ts: now);
    parentHead.setRecentDate(now);
    headDBManager.updateHead(parentHead);
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

  Future<void> _notifyOfNewPost() async {
    final CloudFunctionManager cloudFunctionManager = CloudFunctionManager();
    await cloudFunctionManager
        .sendToTopic(topic: 'ctrim-belfast', title: _tecTitle.text.trim(), body: _tecSubtitle.text.trim(), data: {});
  }

  Future<void> _notifyContributorAdditions() async {}

  Future<void> _notifyProgramRoleAddtitions() async {}
}
