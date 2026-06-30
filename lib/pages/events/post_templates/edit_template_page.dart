import 'package:ctrim_app/firebase/db_managers/post_template_db_manager.dart';
import 'package:ctrim_app/models/post_template.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:ctrim_app/utility/local_data_manager.dart';
import 'package:ctrim_app/utility/network_image_helper.dart';
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
  late final List<String> _subtitles;
  int? _defaultDayOfWeek;
  late List<Map<String, dynamic>> _headMediaPool, _bodyMediaPool;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    _tabController = TabController(length: 4, vsync: this);
    _tecTitle = TextEditingController(text: widget.eventContext.head.title);
    _tecSubtitle = TextEditingController(text: widget.eventContext.head.subtitle);
    _subtitles = List<String>.from(widget.oldTemplate.subtitles);
    _defaultDayOfWeek = widget.oldTemplate.defaultDayOfWeek;
    _headMediaPool = widget.oldTemplate.headMediaPool.map((e) => Map<String, dynamic>.from(e)).toList();
    _bodyMediaPool = widget.oldTemplate.bodyMediaPool.map((e) => Map<String, dynamic>.from(e)).toList();
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
      _buildHeaderTab(),
      ViewPostBody(
          eventContext: widget.eventContext, updateBody: () => _updateBody(), currentUID: _appContext.currentUser.id),
      ViewAllPrograms(eventContext: widget.eventContext, onProgramChanged: () => _updateBody(), isAddingPost: true),
      _buildMediaTab(),
    ]);
  }

  Widget _buildMediaTab() {
    return Column(
      children: [
        _buildBodyMediaPoolEditor(),
        Expanded(child: ViewEventMediaTab(eventContext: widget.eventContext, currentUID: _appContext.currentUser.id)),
      ],
    );
  }

  Widget _buildHeaderTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        AddEventHeadMeta(
          tecTitle: _tecTitle,
          tecSubtitle: _tecSubtitle,
          onRequiredFieldChange: (_) => null,
          eventContext: widget.eventContext,
        ),
        const Divider(height: 32),
        _buildSubtitleListEditor(),
        const Divider(height: 32),
        _buildDayOfWeekPicker(),
        const SizedBox(height: 16),
        _buildHeadMediaPoolEditor(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDayOfWeekPicker() {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Default Day of Week',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Set which day of the week this template is typically used for. Required for bulk post creation.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final day = i + 1;
                final selected = _defaultDayOfWeek == day;
                return FilterChip(
                  label: Text(dayNames[i]),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _defaultDayOfWeek = selected ? null : day;
                  }),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleListEditor() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.format_list_bulleted, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Template Subtitles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Add multiple subtitles that can be randomly or manually selected when creating posts from this template.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (_subtitles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No subtitles added yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              )
            else
              ..._subtitles.asMap().entries.map((entry) {
                final index = entry.key;
                final subtitle = entry.value;
                return _buildSubtitleItem(index, subtitle);
              }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _onAddSubtitle,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Subtitle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleItem(int index, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        title: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _onEditSubtitle(index, subtitle),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: Theme.of(context).colorScheme.error,
              onPressed: () => _onRemoveSubtitle(index),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  void _onAddSubtitle() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subtitle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Subtitle text',
            hintText: 'Enter subtitle text...',
          ),
          maxLines: 2,
          maxLength: 128,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _subtitles.add(text);
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _onEditSubtitle(int index, String currentSubtitle) {
    final controller = TextEditingController(text: currentSubtitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subtitle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Subtitle text',
            hintText: 'Enter subtitle text...',
          ),
          maxLines: 2,
          maxLength: 128,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _subtitles[index] = text;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _onRemoveSubtitle(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subtitle'),
        content: Text('Are you sure you want to delete "${_subtitles[index]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _subtitles.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // * Head Media Pool Editor

  Widget _buildHeadMediaPoolEditor() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Template Head Media Pool',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Add multiple cover images that can be randomly or manually selected when creating posts from this template.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (_headMediaPool.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No head media items added yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              )
            else
              ..._headMediaPool.asMap().entries.map((entry) => _buildPoolMediaItem(
                    entry.value,
                    onDelete: () => setState(() => _headMediaPool.removeAt(entry.key)),
                  )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _onAddMediaPoolItem(isHead: true),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Media Item'),
            ),
          ],
        ),
      ),
    );
  }

  // * Body Media Pool Editor

  Widget _buildBodyMediaPoolEditor() {
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Template Body Media Pool',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Add media items that can be randomly or manually added to the gallery when creating posts from this template.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (_bodyMediaPool.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No body media items added yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              )
            else
              ..._bodyMediaPool.asMap().entries.map((entry) => _buildPoolMediaItem(
                    entry.value,
                    onDelete: () => setState(() => _bodyMediaPool.removeAt(entry.key)),
                  )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _onAddMediaPoolItem(isHead: false),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Media Item'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolMediaItem(Map<String, dynamic> item, {required VoidCallback onDelete}) {
    final bool isVideo = item['type'] == 'vid';
    final String? thumbnailSrc = item['thumbnailSrc'];
    final String src = item['src'] ?? '';
    final String? title = item['title']?.isNotEmpty == true ? item['title'] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 56,
            height: 56,
            child: _buildPoolItemThumbnail(isVideo: isVideo, thumbnailSrc: thumbnailSrc, src: src),
          ),
        ),
        title: Text(
          title ?? (isVideo ? 'Video' : 'Image'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          src,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 20),
          color: Theme.of(context).colorScheme.error,
          onPressed: onDelete,
          tooltip: 'Remove',
        ),
      ),
    );
  }

  Widget _buildPoolItemThumbnail({required bool isVideo, String? thumbnailSrc, required String src}) {
    final displaySrc = isVideo ? thumbnailSrc : src;
    if (displaySrc != null && displaySrc.isNotEmpty) {
      return Image.network(
        displaySrc,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _poolItemFallbackIcon(isVideo),
      );
    }
    return _poolItemFallbackIcon(isVideo);
  }

  Widget _poolItemFallbackIcon(bool isVideo) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _onAddMediaPoolItem({required bool isHead}) {
    final srcController = TextEditingController();
    final thumbnailController = TextEditingController();
    final titleController = TextEditingController();
    String selectedType = 'img';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(isHead ? 'Add Head Media Item' : 'Add Body Media Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: srcController,
                  decoration: const InputDecoration(
                    labelText: 'Media URL',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 64,
                ),
                const SizedBox(height: 4),
                Text('Type', style: Theme.of(context).textTheme.labelMedium),
                RadioGroup<String>(
                  groupValue: selectedType,
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                  child: Row(
                    children: [
                      const Radio<String>(value: 'img'),
                      const Text('Image'),
                      const SizedBox(width: 16),
                      const Radio<String>(value: 'vid'),
                      const Text('Video'),
                    ],
                  ),
                ),
                if (selectedType == 'vid') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: thumbnailController,
                    decoration: const InputDecoration(
                      labelText: 'Thumbnail URL (optional)',
                      hintText: 'https://...',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final src = srcController.text.trim();
                if (src.isEmpty) return;
                final item = {
                  'src': src,
                  'type': selectedType,
                  'title': titleController.text.trim(),
                  'thumbnailSrc': thumbnailController.text.trim(),
                };
                setState(() {
                  if (isHead) {
                    _headMediaPool.add(item);
                  } else {
                    _bodyMediaPool.add(item);
                  }
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.55))),
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
      children: [
        Positioned.fill(
            child: Image.network(NetworkImageHelper.getImageUrl(widget.eventContext.head.getKeyGraphic()!),
                fit: BoxFit.cover))
      ],
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

  void _onSavePostTemplateClick() async {
    final confirm = await DialogManager.showConfirmationDialog(
        context: context, title: 'Save Post Template', content: 'Do you wish to save the template as is?');
    if (!confirm || !mounted) return;

    DialogManager.showProgressDialog(context: context, title: 'Saving PostTemplate');
    try {
      await _performTemplateSave();
      if (!mounted) return;
      // pop progress dialog. pop the settings. pop the page
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error saving template: $e');
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss progress dialog
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save template: $e'), behavior: SnackBarBehavior.floating));
    }
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
      'Subtitles': _subtitles,
      'AllDay': widget.eventContext.program.allDay,
      'Online': widget.eventContext.program.online,
      'Address': widget.eventContext.program.address,
      'MapLink': widget.eventContext.program.mapLink,
      'StartTime': startTime,
      'FinishTime': finishTime,
      'Media': widget.eventContext.media.allMedia,
      'HeadMedia': widget.eventContext.head.media,
      'HeadMediaPool': _headMediaPool,
      'BodyMediaPool': _bodyMediaPool,
      'Roles': _rolesToJson(),
      'DefaultDayOfWeek': _defaultDayOfWeek,
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
