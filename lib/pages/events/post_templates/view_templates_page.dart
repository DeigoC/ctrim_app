import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../firebase/db_managers/post_template_db_manager.dart';
import '../../../models/post_template.dart';
import '../../../utility/app_context.dart';
import '../../../utility/dialog_manager.dart';
import '../../../utility/event_context.dart';
import '../../../utility/local_data_manager.dart';
import '../../../utility/notification_topics.dart';
import '../../../utility/post_template_loader.dart';
import '../../../utility/responsive_layout.dart';
import '../../../utility/user_activity_messages.dart';
import '../../../utility/user_activity_recorder.dart';
import '../../../widgets/load_progress_body.dart';
import '../../../widgets/role_access_gate.dart';
import '../../../widgets/app_dialog.dart';
import 'edit_template_page.dart';

class ViewTemplatesPage extends StatefulWidget {
  const ViewTemplatesPage({super.key});

  @override
  State<ViewTemplatesPage> createState() => _ViewTemplatesPageState();
}

class _ViewTemplatesPageState extends State<ViewTemplatesPage> {
  late final AppContext _appContext;

  bool _loading = true;
  Object? _loadError;
  List<PostTemplate> _templates = const [];
  String _loadStatusMessage = 'Checking local cache…';
  int _loadCompletedSteps = 0;
  int _loadTotalSteps = 4;

  @override
  void initState() {
    super.initState();
    _appContext = Provider.of<AppContext>(context, listen: false);
    _loadTemplates();
  }

  void _updateLoadProgress({
    required int completed,
    required int total,
    required String message,
  }) {
    if (!mounted) return;
    setState(() {
      _loadCompletedSteps = completed;
      _loadTotalSteps = total;
      _loadStatusMessage = message;
    });
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _loadStatusMessage = 'Checking local cache…';
      _loadCompletedSteps = 0;
      _loadTotalSteps = 4;
    });

    try {
      final templates = await PostTemplateLoader.load(
        onProgress: ({required completed, required total, required message}) {
          _updateLoadProgress(
              completed: completed, total: total, message: message);
        },
      );
      if (!mounted) return;
      templates.sort((a, b) => a.title.compareTo(b.title));
      setState(() {
        _templates = templates;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Error loading templates: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RoleAccessGate(
      allow: (user) => user.canManagePostTemplates,
      deniedMessage: 'Only leaders can manage post templates.',
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Post Templates'),
          backgroundColor: colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loading ? null : () => _onCreateTemplateTap(),
          icon: const Icon(Icons.add),
          label: const Text('New template'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading || _loadError != null) {
      return LoadProgressBody(
        message: _loadStatusMessage,
        completedSteps: _loadCompletedSteps,
        totalSteps: _loadTotalSteps,
        error: _loadError,
        errorTitle: 'Could not load templates',
        onRetry: _loadTemplates,
      );
    }
    return _buildBodyWithData(_templates);
  }

  Widget _buildBodyWithData(final List<PostTemplate> templates) {
    if (templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'No templates yet',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new template to get started.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = ResponsiveLayout.isWideScreen(width);
        final horizontalPadding = isWide
            ? ((width - ResponsiveLayout.maxContentWidth(width)) / 2)
                .clamp(16.0, double.infinity)
            : 16.0;

        return ListView(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 96),
          children: [
            for (var i = 0; i < PostTemplateCategory.values.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              _buildCategorySection(
                category: PostTemplateCategory.values[i],
                templates: templates
                    .where((t) => t.category == PostTemplateCategory.values[i])
                    .toList(),
                isWide: isWide,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCategorySection({
    required PostTemplateCategory category,
    required List<PostTemplate> templates,
    required bool isWide,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isServices = category == PostTemplateCategory.service;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isServices ? Icons.event_outlined : Icons.groups_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isServices
                            ? 'Sunday services and similar programmes'
                            : 'Cell group meetings',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (templates.isEmpty)
              Text(
                'No ${category.label.toLowerCase()} templates yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              _buildSectionTiles(templates, isWide),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _onCreateTemplateTap(initialCategory: category),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add ${category.label} template'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTiles(List<PostTemplate> templates, bool isWide) {
    if (!isWide) {
      return Column(
        children: [
          for (var i = 0; i < templates.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildTemplateTile(templates[i]),
          ],
        ],
      );
    }

    final left = <PostTemplate>[];
    final right = <PostTemplate>[];
    for (var i = 0; i < templates.length; i++) {
      (i.isEven ? left : right).add(templates[i]);
    }

    Widget column(List<PostTemplate> items) {
      return Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildTemplateTile(items[i]),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(left)),
        const SizedBox(width: 16),
        Expanded(child: column(right)),
      ],
    );
  }

  Widget _buildTemplateTile(final PostTemplate template) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () => _openEditTemplate(template),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description,
                    color: colorScheme.onSecondaryContainer, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (template.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        template.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (template.location.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        template.location,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_TemplateAction>(
                tooltip: 'Template actions',
                onSelected: (action) {
                  switch (action) {
                    case _TemplateAction.edit:
                      _openEditTemplate(template);
                    case _TemplateAction.duplicate:
                      _onDuplicateTemplateTap(template);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _TemplateAction.edit,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _TemplateAction.duplicate,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.copy_outlined),
                      title: Text('Duplicate'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onCreateTemplateTap({
    PostTemplateCategory? initialCategory,
  }) async {
    final details = await _showNewTemplateDetailsDialog(
      initialCategory: initialCategory ?? PostTemplateCategory.service,
    );
    if (details == null || !mounted) return;

    final location = _appContext.currentUser.location;
    final draft = _buildBlankTemplate(
      title: details.title,
      description: details.description,
      location: location,
      category: details.category,
    );
    draft.addLog(
      log: 'Created',
      uid: _appContext.currentUser.id,
      ts: DateTime.now(),
    );

    PostTemplate? createdTemplate;
    final created = await DialogManager.runWithSteppedProgressDialog(
      context: context,
      title: 'Creating template',
      initialMessage: 'Creating template…',
      errorTitle: 'Could not create template',
      action: (onProgress) async {
        const total = 2;
        onProgress(completed: 0, total: total, message: 'Creating template…');
        final result = await PostTemplateDBManager().addPostTemplate(draft);
        createdTemplate =
            PostTemplate.fromMap(true, result.id, draft.toJson(true));
        onProgress(completed: 1, total: total, message: 'Saving local copy…');
        final local = LocalDataManager();
        await local.writePostTemplateData(createdTemplate!);
        await local.writeLastPostTemplateUpdate(result.lastUpdate);
        await UserActivityRecorder().record(
          actorUserId: _appContext.currentUser.id,
          log: UserActivityMessages.createdPostTemplate,
          documentId: result.id,
        );
      },
    );

    if (!mounted || !created || createdTemplate == null) return;
    await _loadTemplates();
    if (!mounted) return;
    await _openEditTemplate(createdTemplate!);
  }

  Future<void> _onDuplicateTemplateTap(final PostTemplate source) async {
    final confirm = await DialogManager.showConfirmationDialog(
      context: context,
      title: 'Duplicate template',
      content: 'Create a copy of "${source.title}"?',
      confirmText: 'Duplicate',
      icon: Icons.copy_outlined,
    );
    if (!confirm || !mounted) return;

    PostTemplate? duplicated;
    final created = await DialogManager.runWithSteppedProgressDialog(
      context: context,
      title: 'Duplicating template',
      initialMessage: 'Duplicating template…',
      errorTitle: 'Could not duplicate template',
      action: (onProgress) async {
        const total = 2;
        onProgress(
            completed: 0, total: total, message: 'Duplicating template…');
        final copyData = source.toJson(true);
        copyData['Title'] = 'Copy of ${source.title}';
        copyData['HeadTitle'] = copyData['Title'];
        // Fresh history for the new document — do not copy source Logs.
        copyData['Logs'] = <Map<String, dynamic>>[];
        final draft = PostTemplate.fromMap(true, 'temp', copyData);
        draft.addLog(
          log: 'Duplicated from "${source.title}"',
          uid: _appContext.currentUser.id,
          ts: DateTime.now(),
        );
        final result = await PostTemplateDBManager().addPostTemplate(draft);
        duplicated = PostTemplate.fromMap(true, result.id, draft.toJson(true));
        onProgress(completed: 1, total: total, message: 'Saving local copy…');
        final local = LocalDataManager();
        await local.writePostTemplateData(duplicated!);
        await local.writeLastPostTemplateUpdate(result.lastUpdate);
        await UserActivityRecorder().record(
          actorUserId: _appContext.currentUser.id,
          log: UserActivityMessages.createdPostTemplate,
          documentId: result.id,
        );
      },
    );

    if (!mounted || !created || duplicated == null) return;
    await _loadTemplates();
    if (!mounted) return;
    await _openEditTemplate(duplicated!);
  }

  Future<_NewTemplateDetails?> _showNewTemplateDetailsDialog({
    required PostTemplateCategory initialCategory,
  }) {
    // AppDialog (not Cupertino): TextFormFields need Material.
    // Controllers live on [_NewTemplateDetailsDialog] so they are not disposed
    // while the route is still animating out (which caused "used after disposed").
    return showDialog<_NewTemplateDetails>(
      context: context,
      builder: (_) =>
          _NewTemplateDetailsDialog(initialCategory: initialCategory),
    );
  }

  PostTemplate _buildBlankTemplate({
    required String title,
    required String description,
    required String location,
    required PostTemplateCategory category,
  }) {
    return PostTemplate.fromMap(true, 'temp', {
      'Title': title,
      'Description': description.isEmpty ? 'New post template' : description,
      'HeadTitle': title,
      'Body': r'[{"insert":"Hello, time to start writing!\n"}]',
      'Location': location,
      'Category': category.firestoreValue,
      'Topics': [NotificationTopics.locationUmbrella(location)],
      'TagIDs': <String>[],
      'CellGroupIDs': <String>[],
      'ExpectedAttendeeUserIDs': <String>[],
      'Contributors': <String>[],
      'LeadSpeakerUID': null,
      'IsPeriodParent': false,
      'Subtitles': <String>[],
      'AllDay': false,
      'Online': false,
      'Address': '',
      'MapLink': '',
      'StartTime': null,
      'FinishTime': null,
      'Media': <Map<String, dynamic>>[],
      'HeadMedia': <Map<String, dynamic>>[],
      'HeadMediaPool': <Map<String, dynamic>>[],
      'BodyMediaPool': <Map<String, dynamic>>[],
      'Roles': <Map<String, dynamic>>[],
      'DefaultDayOfWeek': null,
    });
  }

  Future<void> _openEditTemplate(final PostTemplate postTemplate) async {
    final EventContext eventContext = EventContext.adding(
      currentUserID: _appContext.currentUser.id,
      id: postTemplate.id,
    );

    eventContext.head.setEventDate(postTemplate.startTime);
    eventContext.head.setLocation(postTemplate.location);
    eventContext.head.setTitle(postTemplate.title);
    for (final headMediaItem in postTemplate.headMedia) {
      eventContext.head.addMediaItem(
          type: headMediaItem['type']!,
          src: headMediaItem['src']!,
          title: headMediaItem['title'] ?? '',
          thumbnail: headMediaItem['thumbnailSrc'] ?? '');
    }

    eventContext.setFetchedBody(postTemplate.body);
    eventContext.media.addAllMediaFiles(postTemplate.media);

    eventContext.applyTagIDs(List<String>.from(postTemplate.tagIDs));
    eventContext
        .applyCellGroupIDs(List<String>.from(postTemplate.cellGroupIDs));
    eventContext.applyExpectedAttendeeUserIDs(
        List<String>.from(postTemplate.expectedAttendeeUserIDs));
    eventContext.metadata.contributorUIDs.addAll(postTemplate.contributors);
    if (postTemplate.leadSpeakerUID != null &&
        postTemplate.leadSpeakerUID!.isNotEmpty) {
      eventContext.metadata.setLeadSpeakerUID(postTemplate.leadSpeakerUID);
      eventContext.syncLeadSpeakerHeadFromUsers(_appContext.allUsers);
    }
    eventContext.applyIsPeriodParent(postTemplate.isPeriodParent);

    for (final role in postTemplate.roles) {
      eventContext.program.addRole(
        detail: role['detail'] ?? '',
        uids: List<String>.from(role['uids'] ?? const []),
        title: role['title'] ?? '',
        start: role['start'],
        end: role['end'],
        id: role['id'] is int
            ? role['id'] as int
            : DateTime.now().millisecondsSinceEpoch,
        forGuests:
            role['for_guests'] is bool ? role['for_guests'] as bool : true,
      );
    }
    eventContext.program.setAddress(postTemplate.address);
    eventContext.program.setAllDay(postTemplate.allDay);
    eventContext.program.setMapLink(postTemplate.mapLink);
    eventContext.program.setOnline(postTemplate.online);
    eventContext.program.setFinishTime(postTemplate.finishTime);

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditTemplatePage(
        eventContext: eventContext,
        oldTemplate: postTemplate,
      ),
    ));
    if (mounted) {
      await _loadTemplates();
    }
  }
}

enum _TemplateAction { edit, duplicate }

class _NewTemplateDetails {
  const _NewTemplateDetails({
    required this.title,
    required this.description,
    required this.category,
  });

  final String title;
  final String description;
  final PostTemplateCategory category;
}

class _NewTemplateDetailsDialog extends StatefulWidget {
  const _NewTemplateDetailsDialog({required this.initialCategory});

  final PostTemplateCategory initialCategory;

  @override
  State<_NewTemplateDetailsDialog> createState() =>
      _NewTemplateDetailsDialogState();
}

class _NewTemplateDetailsDialogState extends State<_NewTemplateDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late PostTemplateCategory _category;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onCreate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _NewTemplateDetails(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: Icons.post_add_outlined,
      title: 'New template',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: AppDialog.inputDecoration(
                label: 'Title',
                hint: 'e.g. Sunday Service',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: AppDialog.inputDecoration(
                label: 'Description (optional)',
                hint: 'Short summary for admins',
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PostTemplateCategory>(
              initialValue: _category,
              decoration: AppDialog.inputDecoration(label: 'Category'),
              items: [
                for (final category in PostTemplateCategory.values)
                  DropdownMenuItem<PostTemplateCategory>(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (selected) {
                if (selected == null) return;
                setState(() => _category = selected);
              },
            ),
          ],
        ),
      ),
      actions: AppDialogActions(
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: _onCreate,
        confirmLabel: 'Create',
      ),
    );
  }
}
