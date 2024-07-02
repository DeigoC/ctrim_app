import 'package:ctrim_app/firebase/db_managers/post_template_db_manager.dart';
import 'package:ctrim_app/models/post_template.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:ctrim_app/utility/local_data_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../../utility/app_context.dart';
import '../../../widgets/posts/add_header_meta_tab_body.dart';
import '../../../widgets/posts/view_all_programs.dart';
import '../../../widgets/posts/view_event_media_tab.dart';
import '../../../widgets/posts/view_post_body.dart';
import '../add_program_role_page.dart';
import '../edit_body_page.dart';
import '../edit_gallery_page.dart';

class EditTemplatePage extends StatefulWidget {
  const EditTemplatePage({super.key, required this.eventContext, required this.oldTemplate});
  final EventContext eventContext;
  final PostTemplate oldTemplate;

  @override
  State<EditTemplatePage> createState() => _EditTemplatePageState();
}

class _EditTemplatePageState extends State<EditTemplatePage> with SingleTickerProviderStateMixin {
  late final AppContext _appContext;
  late final TabController _tabController;
  late final TextEditingController _tecTitle, _tecSubtitle;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    _tabController = TabController(length: 4, vsync: this);
    _tecTitle = TextEditingController(text: widget.eventContext.head.title);
    _tecSubtitle = TextEditingController(text: widget.eventContext.head.subtitle);
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
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    return NestedScrollView(
        headerSliverBuilder: (_, __) {
          return _buildHeaderSliver();
        },
        body: _buildTabBody());
  }

  Widget _buildTabBody() {
    return TabBarView(controller: _tabController, children: [
      AddEventHeadMeta(
        tecTitle: _tecTitle,
        tecSubtitle: _tecSubtitle,
        onRequiredFieldChange: (_) => null,
        eventContext: widget.eventContext,
      ),
      ViewPostBody(
          eventContext: widget.eventContext, updateBody: () => _updateBody(), currentUID: _appContext.currentUser.id),
      ViewAllPrograms(eventContext: widget.eventContext, onProgramChanged: () => _updateBody(), isAddingPost: true),
      ViewEventMediaTab(eventContext: widget.eventContext, currentUID: _appContext.currentUser.id)
    ]);
  }

  List<Widget> _buildHeaderSliver() {
    final bool onDark = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;

    return [
      SliverAppBar(
        expandedHeight: MediaQuery.of(context).size.height * 0.33,
        flexibleSpace: FlexibleSpaceBar(background: _buildAppBarBackground()),
        actions: [
          ElevatedButton.icon(
              onPressed: () => _showSettings(),
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              label: const Text('Edit', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.withOpacity(0.55))),
          const SizedBox(width: 8)
        ],
      ),
      SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            TabBar(
              labelColor: onDark ? Colors.white : Colors.black,
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline), text: 'Header'),
                Tab(icon: Icon(Icons.note), text: 'Info'),
                Tab(icon: Icon(Icons.calendar_today), text: 'Schedule'),
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

  // * LOGIC

  void _showSettings() {
    showModalBottomSheet(
        showDragHandle: true,
        context: context,
        builder: (_) => SingleChildScrollView(
                child: SafeArea(
                    child: Column(children: [
              ListTile(title: const Text('Edit About'), leading: const Icon(Icons.edit), onTap: _onEditBodyClick),
              ListTile(
                title: const Text('Add Schedule Item'),
                leading: const Icon(Icons.edit_calendar),
                onTap: _onAddScheduleItem,
              ),
              ListTile(
                  title: const Text('Edit Media Items'),
                  leading: const Icon(Icons.photo_library),
                  onTap: _onEditMediaTap),
              ListTile(
                  title: const Text('Save Post Template'),
                  leading: const Icon(Icons.save_rounded),
                  onTap: _onSavePostTemplateClick),
            ]))));
  }

  void _onEditBodyClick() {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditBodyPage(eventContext: widget.eventContext)))
        .then((_) {
      setState(() {});
    });
  }

  void _onAddScheduleItem() async {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddEventProgramPage(eventContext: widget.eventContext)))
        .then((_) async {
      widget.eventContext.program.orderProgramsByStartTime();
      setState(() {});
    }).then((_) {});
  }

  void _onEditMediaTap() {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditGalleryPage(eventContext: widget.eventContext)))
        .then((_) {
      setState(() {});
    });
  }

  void _updateBody() {
    setState(() {});
    // _onRequiredFieldTextChange('');
  }

  void _onSavePostTemplateClick() {
    DialogManager.showConfirmationDialog(
            context: context, title: 'Save Post Template', content: 'Do you wish to save the template as is?')
        .then((confirm) {
      if (confirm) {
        // DialogManager.showProgressDialog(context: context, title: 'Saving PostTemplate');
        _performTemplateSave().then((_) {
          // pop progress dialog. pop the settings. pop the page
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        });
      }
    });
  }

  Future<void> _performTemplateSave() async {
    debugPrint('---- begin converting to post template');
    // Convert to PostTemplate again
    dynamic startTime = widget.eventContext.head.eventDate;
    dynamic finishTime = widget.eventContext.program.finishTime;
    if (startTime != null) {
      startTime = (startTime as DateTime).millisecondsSinceEpoch;
    }
    if (finishTime != null) {
      finishTime = (finishTime as DateTime).millisecondsSinceEpoch;
    }

    final Map<String, dynamic> templateData = {
      'Title': _tecTitle.text.trim(),
      'Description': widget.oldTemplate.description,
      'HeadTitle': widget.oldTemplate.headTitle, // unlikely we'll be updating this anytime soon...?
      'Body': widget.eventContext.encodedBody,
      'Location': widget.eventContext.head.location,
      'Topics': widget.oldTemplate.topics,
      'Contributors': widget.eventContext.metadata.contributorUIDs,
      'AllDay': widget.eventContext.program.allDay,
      'Online': widget.eventContext.program.online,
      'Address': widget.eventContext.program.address,
      'MapLink': widget.eventContext.program.mapLink,
      'StartTime': startTime,
      'FinishTime': finishTime,
      'Media': widget.eventContext.media.allMedia,
      'HeadMedia': widget.eventContext.head.media,
      'Roles': _rolesToJson(),
    };
    final PostTemplate updatedTemplate = PostTemplate.fromMap(true, widget.eventContext.id, templateData);

    // Save to DB
    debugPrint('---- begin saving template ID (${updatedTemplate.id}) to DB');
    final PostTemplateDBManager postTemplateDBManager = PostTemplateDBManager();
    await postTemplateDBManager.updateTemplate(updatedTemplate);

    // Save Locally
    debugPrint('---- begin saving locally');
    final LocalDataManager localDataManager = LocalDataManager();
    localDataManager.clearPostTemplateDir();
    await localDataManager.writePostTemplateData(updatedTemplate);
    debugPrint('---- FINISHED UPDATING POST TEMPLATE');
  }

  List<Map<String, dynamic>> _rolesToJson() {
    final List<Map<String, dynamic>> result = List<Map<String, dynamic>>.empty(growable: true);
    for (final entry in widget.eventContext.program.roles) {
      var start = entry['start'];
      var end = entry['end'];
      if (start != null) {
        start = (entry['start'] as DateTime).millisecondsSinceEpoch;
      }
      if (end != null) {
        end = (entry['end'] as DateTime).millisecondsSinceEpoch;
      }

      result.add({
        'uids': entry['uids'],
        'detail': entry['detail'],
        'title': entry['title'],
        'start': start,
        'end': end,
        'for_guests': entry['for_guests'],
        'id': entry['id'],
      });
    }

    return result;
  }
}
