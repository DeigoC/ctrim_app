import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/post_template.dart';
import '../../../utility/app_context.dart';
import '../../../utility/event_context.dart';
import '../../../utility/post_template_loader.dart';
import '../../../utility/post_template_mapper.dart';
import '../../../utility/responsive_layout.dart';
import '../../../widgets/app_search_bar.dart';
import '../../../widgets/load_progress_body.dart';
import '../../../widgets/responsive_content.dart';
import '../../../widgets/role_access_gate.dart';
import '../add_event_page.dart';
import '../bulk_create_posts_page.dart';

class SelectPostTemplatePage extends StatefulWidget {
  const SelectPostTemplatePage({
    super.key,
    required this.eventContext,
    this.bulkMode = false,
    this.sourcePostId,
    this.sourcePostParentId,
    this.sourcePostEventDate,
  });
  static final DateFormat _eventDateFormat = DateFormat('d MMM');
  final EventContext eventContext;
  final bool bulkMode;
  final String? sourcePostId;
  final String? sourcePostParentId;
  final DateTime? sourcePostEventDate;

  @override
  State<SelectPostTemplatePage> createState() => _SelectPostTemplatePageState();
}

class _SelectPostTemplatePageState extends State<SelectPostTemplatePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<PostTemplate> _allTemplates = [];

  bool _loading = true;
  Object? _loadError;
  String _loadStatusMessage = 'Checking local cache…';
  int _loadCompletedSteps = 0;
  int _loadTotalSteps = 4;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        forceRemote: widget.bulkMode,
        onProgress: ({required completed, required total, required message}) {
          _updateLoadProgress(
              completed: completed, total: total, message: message);
        },
      );
      if (!mounted) return;

      templates.sort((a, b) => a.headTitle.compareTo(b.headTitle));
      if (!widget.bulkMode) {
        templates.add(_createBlankSlate());
      }

      setState(() {
        _allTemplates = templates;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Error fetching templates: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  final TextStyle _cardTitleStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );

  final TextStyle _cardContentStyle = const TextStyle(
    fontSize: 14,
    height: 1.4,
  );

  final TextStyle _cardMetaStyle = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RoleAccessGate(
      allow: (user) => user.canManagePostTemplates,
      deniedMessage: 'Only leaders can create posts from templates.',
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title:
              Text(widget.bulkMode ? 'Bulk Create Posts' : 'Choose Template'),
          backgroundColor: colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: Column(
          children: [
            if (!_loading && _loadError == null)
              _buildSearchAndFilters(colorScheme),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: ResponsiveContent(
        narrowPadding: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              AppSearchBar(
                controller: _searchController,
                hintText: 'Search templates...',
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 12),
              if (_allTemplates.isNotEmpty) _buildCategoryFilter(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ColorScheme colorScheme) {
    final categories = _getAvailableCategories();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) => _onCategoryChanged(category),
            backgroundColor: colorScheme.surfaceContainerHighest,
            selectedColor: colorScheme.primaryContainer,
            checkmarkColor: colorScheme.onPrimaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            side: BorderSide(
              color:
                  isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
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

    final filtered = _getFilteredTemplates(_allTemplates);
    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return _buildBodyWithData(filtered);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'No templates available at the moment',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedCategory != 'All') ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  PostTemplate _createBlankSlate() {
    final Map<String, dynamic> templateData = {
      'Title': 'Blank Template',
      'Description': "A clean slate. Edit to your heart's content!",
      'HeadTitle': 'Blank Template',
      'Body': r'[{"insert":"Hello, time to start writing!\n"}]',
      'Location': 'Belfast',
      'Topics': ['Belfast'],
      'TagIDs': <String>[],
      'CellGroupIDs': <String>[],
      'Contributors': [],
      'LeadSpeakerUID': null,
      'AllDay': false,
      'Online': false,
      'Address': '',
      'MapLink': '',
      'StartTime': null,
      'FinishTime': null,
      'Media': [],
      'HeadMedia': List<Map<String, dynamic>>.empty(),
      'Roles': List<Map<String, dynamic>>.empty(),
    };

    return PostTemplate.fromMap(true, 'blank', templateData);
  }

  Widget _buildBodyWithData(final List<PostTemplate> templates) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = ResponsiveLayout.isWideScreen(width);
        final horizontalPadding = isWide
            ? ((width - ResponsiveLayout.maxContentWidth(width)) / 2)
                .clamp(16.0, double.infinity)
            : 16.0;

        if (!isWide) {
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 16, horizontalPadding, 16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: templates.length,
            itemBuilder: (_, index) => _buildTemplateTile(templates[index]),
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

        return SingleChildScrollView(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: column(left)),
              const SizedBox(width: 16),
              Expanded(child: column(right)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateTile(final PostTemplate template) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBlankTemplate = template.id == 'blank';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isBlankTemplate
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant,
          width: isBlankTemplate ? 2 : 1,
        ),
      ),
      color: isBlankTemplate
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () => widget.bulkMode
            ? _onBulkAddPostTap(template)
            : _onAddPostTap(template),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isBlankTemplate
                          ? colorScheme.primary.withValues(alpha: 0.2)
                          : colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isBlankTemplate ? Icons.edit_note : Icons.description,
                      color: isBlankTemplate
                          ? colorScheme.primary
                          : colorScheme.onSecondaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and Actions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                template.title,
                                style: _cardTitleStyle.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isBlankTemplate)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'BLANK',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.description,
                          style: _cardContentStyle.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (!isBlankTemplate) ...[
                const SizedBox(height: 16),
                // Template Details
                _buildTemplateDetails(template, colorScheme),
              ],

              const SizedBox(height: 16),
              // Action Row
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => widget.bulkMode
                          ? _onBulkAddPostTap(template)
                          : _onAddPostTap(template),
                      style: FilledButton.styleFrom(
                        backgroundColor: isBlankTemplate
                            ? colorScheme.primary
                            : colorScheme.secondaryContainer,
                        foregroundColor: isBlankTemplate
                            ? colorScheme.onPrimary
                            : colorScheme.onSecondaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(
                        widget.bulkMode
                            ? Icons.calendar_month
                            : (isBlankTemplate
                                ? Icons.create
                                : Icons.add_circle_outline),
                        size: 18,
                      ),
                      label: Text(
                        widget.bulkMode
                            ? 'Bulk Create'
                            : (isBlankTemplate
                                ? 'Start from Blank'
                                : 'Use Template'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
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

  Widget _buildTemplateDetails(PostTemplate template, ColorScheme colorScheme) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        // Location
        if (template.location.isNotEmpty)
          _buildDetailChip(
            Icons.location_on_outlined,
            template.location,
            colorScheme,
          ),

        // Time info
        if (template.startTime != null)
          _buildDetailChip(
            template.allDay ? Icons.event : Icons.access_time,
            template.allDay
                ? 'All Day'
                : DateFormat.jm().format(template.startTime!),
            colorScheme,
          ),

        // Online indicator
        if (template.online)
          _buildDetailChip(
            Icons.videocam,
            'Online',
            colorScheme,
          ),

        // Topics (first 2)
        ...template.topics.take(2).map(
              (topic) => _buildDetailChip(
                Icons.tag,
                topic,
                colorScheme,
              ),
            ),

        // More topics indicator
        if (template.topics.length > 2)
          _buildDetailChip(
            Icons.more_horiz,
            '+${template.topics.length - 2} more',
            colorScheme,
          ),
      ],
    );
  }

  Widget _buildDetailChip(
      IconData icon, String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: _cardMetaStyle.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // * Logic
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
    });
  }

  List<String> _getAvailableCategories() {
    final Set<String> categories = {'All'};

    for (final template in _allTemplates) {
      categories.addAll(template.topics);
    }

    return categories.toList()..sort();
  }

  List<PostTemplate> _getFilteredTemplates(List<PostTemplate> templates) {
    return templates.where((template) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = template.title.toLowerCase().contains(query) ||
            template.description.toLowerCase().contains(query) ||
            template.location.toLowerCase().contains(query) ||
            template.topics.any((topic) => topic.toLowerCase().contains(query));

        if (!matchesSearch) return false;
      }

      // Category filter
      if (_selectedCategory != 'All') {
        if (!template.topics.contains(_selectedCategory)) return false;
      }

      return true;
    }).toList();
  }

  Future<DateTime?> _selectDate(final BuildContext context) async {
    return await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now().add(const Duration(days: 60)));
  }

  void _onBulkAddPostTap(final PostTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BulkCreatePostsPage(
          template: template,
          sourcePostId: widget.sourcePostId,
          sourcePostParentId: widget.sourcePostParentId,
          sourcePostEventDate: widget.sourcePostEventDate,
        ),
      ),
    );
  }

  Future<void> _onAddPostTap(final PostTemplate postTemplate) async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final EventContext eventContext =
        PostTemplateMapper.mapTemplateToEventContext(
      template: postTemplate,
      currentUserID: appContext.currentUser.id,
      parentID: widget.eventContext.metadata.parentID,
      allUsers: appContext.allUsers,
      allPostTags: appContext.allPostTags,
    );

    if (eventContext.head.eventDate != null) {
      final selectedDate = await _selectDate(context);
      if (selectedDate == null || !mounted) return;
      PostTemplateMapper.adjustEventProgramToDate(eventContext, selectedDate);
      eventContext.head.setTitle(
          '${postTemplate.title} (${SelectPostTemplatePage._eventDateFormat.format(selectedDate)})');
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AddEventPage(eventContext: eventContext)));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AddEventPage(eventContext: eventContext)));
    }
  }
}
