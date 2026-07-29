import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/db_managers/post_template_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/event/event_metadata.dart';
import '../../models/post_template.dart';
import '../../utility/app_context.dart';
import '../../utility/bulk_post_dates.dart';
import '../../utility/local_data_manager.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/post_template_mapper.dart';
import '../../utility/responsive_layout.dart';

enum _BulkPostRelation { child, sibling }

class BulkCreatePostsPage extends StatefulWidget {
  const BulkCreatePostsPage({
    super.key,
    required this.template,
    this.parentID,
    this.sourcePostId,
    this.sourcePostParentId,
    this.sourcePostEventDate,
  });

  final PostTemplate template;
  final String? parentID;
  final String? sourcePostId;
  final String? sourcePostParentId;
  final DateTime? sourcePostEventDate;

  @override
  State<BulkCreatePostsPage> createState() => _BulkCreatePostsPageState();
}

class _BulkCreatePostsPageState extends State<BulkCreatePostsPage> {
  static const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final _random = Random();

  late PostTemplate _template;
  int _selectedWeeks = 4;
  int? _selectedDayOfWeek;
  _BulkPostRelation _selectedRelation = _BulkPostRelation.child;
  List<_PostPreview> _previews = [];
  bool _isCreating = false;
  bool _isRefreshingTemplate = true;
  int _createdCount = 0;

  String? get _effectiveParentID {
    if (widget.sourcePostId != null) {
      return _selectedRelation == _BulkPostRelation.child ? widget.sourcePostId : widget.sourcePostParentId;
    }
    return widget.parentID;
  }

  List<Map<String, dynamic>> get _coverPool => _template.keyGraphicPool;

  bool get _hasCoverPool => _coverPool.isNotEmpty;

  bool get _hasSubtitles => _template.subtitles.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _template = widget.template;
    _selectedDayOfWeek = _template.defaultDayOfWeek;
    _refreshTemplateAndPreviews();
  }

  Future<void> _refreshTemplateAndPreviews() async {
    setState(() => _isRefreshingTemplate = true);
    try {
      final fresh = await PostTemplateDBManager().fetchTemplate(widget.template.id);
      if (fresh != null && mounted) {
        _template = fresh;
        // Keep local cache in sync so the next select list sees pool items too.
        await LocalDataManager().writePostTemplateData(fresh);
        debugPrint(
          'BulkCreate: refreshed template "${fresh.title}" '
          'bodyMediaPool=${fresh.bodyMediaPool.length} '
          'headMediaPool=${fresh.headMediaPool.length} keyGraphicPool=${fresh.keyGraphicPool.length}',
        );
      } else {
        debugPrint(
          'BulkCreate: using passed template "${_template.title}" '
          'keyGraphicPool=${_template.keyGraphicPool.length}',
        );
      }
    } catch (e) {
      debugPrint('BulkCreate: template refresh failed: $e');
    }

    if (!mounted) return;
    setState(() {
      _isRefreshingTemplate = false;
      _selectedDayOfWeek ??= _template.defaultDayOfWeek;
    });
    if (_selectedDayOfWeek != null) {
      _regeneratePreviews();
    }
  }

  Map<String, dynamic>? _pickRandomCover() {
    if (!_hasCoverPool) return null;
    final item = _coverPool[_random.nextInt(_coverPool.length)];
    return Map<String, dynamic>.from(item);
  }

  void _regeneratePreviews() {
    if (_selectedDayOfWeek == null) return;

    final dates = computeBulkPostDates(
      dayOfWeek: _selectedDayOfWeek!,
      weeks: _selectedWeeks,
      anchorDate: widget.sourcePostEventDate,
    );
    setState(() {
      _previews = [
        for (final date in dates)
          _PostPreview(
            title: '${_template.title} – ${_formatBulkPostTitleDate(date)}',
            subtitle: _hasSubtitles
                ? _template.subtitles[_random.nextInt(_template.subtitles.length)]
                : '',
            date: date,
            headMedia: _pickRandomCover(),
          ),
      ];
    });
  }

  void _shuffleSubtitle(int index) {
    if (!_hasSubtitles) return;
    setState(() {
      _previews[index].subtitle = _template.subtitles[_random.nextInt(_template.subtitles.length)];
    });
  }

  void _shuffleHeadMedia(int index) {
    if (!_hasCoverPool) return;
    setState(() {
      _previews[index].headMedia = _pickRandomCover();
    });
  }

  void _applyPreviewHeadMedia(EventHead head, Map<String, dynamic>? headMedia) {
    if (headMedia == null) return;
    head.clearMedia();
    head.addMediaItem(
      type: headMedia['type'] ?? 'img',
      src: headMedia['src'] ?? '',
      title: headMedia['title'] ?? '',
      thumbnail: headMedia['thumbnailSrc'] ?? '',
    );
  }

  Future<void> _createAllPosts() async {
    setState(() {
      _isCreating = true;
      _createdCount = 0;
    });

    final appContext = Provider.of<AppContext>(context, listen: false);
    final uid = appContext.currentUser.id;
    final location = _template.location;
    final headDBManager = EventHeadDBManager();

    final String? parentID = _effectiveParentID;
    EventSupplementalDBManager? parentDbManager;
    EventMetadata? parentMetadata;
    if (parentID != null) {
      parentDbManager = EventSupplementalDBManager(parentID);
      parentMetadata = await parentDbManager.fetchMetadata();
      appContext.setMetadata(parentID, parentMetadata);
    }

    try {
      for (int i = 0; i < _previews.length; i++) {
        final preview = _previews[i];
        final eventContext = PostTemplateMapper.mapTemplateToEventContext(
          template: _template,
          currentUserID: uid,
          parentID: parentID,
          allUsers: appContext.allUsers,
        );
        PostTemplateMapper.adjustEventProgramToDate(eventContext, preview.date);
        _applyPreviewHeadMedia(eventContext.head, preview.headMedia);

        final newID = await eventContext.addNewPost(
          title: preview.title,
          subtitle: preview.subtitle,
          uid: uid,
          location: location,
          eventDate: preview.date,
        );

        if (parentID != null && parentMetadata != null && parentDbManager != null) {
          await _updateParentMetadata(
            newPostID: newID,
            title: preview.title,
            parentID: parentID,
            parentMetadata: parentMetadata,
            uid: uid,
            appContext: appContext,
            headDBManager: headDBManager,
            parentDbManager: parentDbManager,
          );
        }
        appContext.addNewPostHead(await headDBManager.fetchHead(newID));

        setState(() {
          _createdCount = i + 1;
        });
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_previews.length} posts created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating posts: $e')),
        );
      }
    }
  }

  Future<void> _updateParentMetadata({
    required String newPostID,
    required String title,
    required String parentID,
    required EventMetadata parentMetadata,
    required String uid,
    required AppContext appContext,
    required EventHeadDBManager headDBManager,
    required EventSupplementalDBManager parentDbManager,
  }) async {
    parentMetadata.childrenPostIDs.add(newPostID);
    await parentDbManager.updateMetadata(parentMetadata);
    appContext.setMetadata(parentID, parentMetadata);

    await parentDbManager.addLogEntry(
      logMessage: "Created related post: '$title'",
      uid: uid,
      ts: DateTime.now(),
    );

    EventHead parentHead;
    if (appContext.eventHeads.any((e) => e.id == parentID)) {
      parentHead = appContext.getPostHead(parentID);
    } else {
      parentHead = await headDBManager.fetchHead(parentID);
    }

    if (parentHead.recentDate.second == 59) {
      parentHead.setRecentDate(parentHead.recentDate.add(const Duration(seconds: -58)));
    } else {
      parentHead.setRecentDate(parentHead.recentDate.add(const Duration(seconds: 1)));
    }
    await headDBManager.updateHead(parentHead);
    appContext.addOrUpdatePostHead(parentHead);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dayName = _selectedDayOfWeek != null ? _dayNames[_selectedDayOfWeek! - 1] : 'Not set';

    if (_isCreating) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bulk Create Posts')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text('Creating $_createdCount of ${_previews.length} posts…',
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    if (_isRefreshingTemplate) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bulk Create Posts')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Create Posts'),
        backgroundColor: colorScheme.surface,
      ),
      floatingActionButton: _previews.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _createAllPosts,
              icon: const Icon(Icons.check),
              label: Text('Create ${_previews.length} Posts'),
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth;
          final isWide = ResponsiveLayout.isWideScreen(contentWidth);
          final maxWidth = ResponsiveLayout.maxContentWidth(contentWidth);
          final horizontalPadding = isWide
              ? ((contentWidth - maxWidth) / 2).clamp(16.0, double.infinity)
              : 0.0;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    _buildTemplateHeader(colorScheme, dayName),
                    if (widget.sourcePostId != null) _buildRelationPicker(colorScheme),
                    _buildDayOfWeekSelector(colorScheme),
                    if (_selectedDayOfWeek != null) _buildWeeksSelector(),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _selectedDayOfWeek == null
                      ? Center(
                          child: Text(
                            'Choose a day of the week to preview posts.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        )
                      : _buildPreviewList(colorScheme, contentWidth: maxWidth.clamp(0, contentWidth)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTemplateHeader(ColorScheme colorScheme, String dayName) {
    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _template.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (_selectedDayOfWeek != null)
                  Text('Every $dayName',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                const SizedBox(height: 4),
                Text(
                  _hasCoverPool
                      ? 'Cover images randomly chosen from media pool (${_coverPool.length})'
                      : 'No cover media pool on this template — add covers under Media → Cover Image Pool',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _hasCoverPool ? colorScheme.onSurfaceVariant : colorScheme.error,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayOfWeekSelector(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Day of week',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedDayOfWeek == null
                ? 'Choose which day to create posts for.'
                : 'Posts will be scheduled every ${_dayNames[_selectedDayOfWeek! - 1]}.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              final day = i + 1;
              final selected = _selectedDayOfWeek == day;
              return FilterChip(
                label: Text(_dayNames[i]),
                selected: selected,
                onSelected: (_) {
                  setState(() => _selectedDayOfWeek = day);
                  _regeneratePreviews();
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeksSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedWeeks ${_selectedWeeks == 1 ? 'week' : 'weeks'} • ${_previews.length} ${_previews.length == 1 ? 'post' : 'posts'}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _selectedWeeks.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            label: '$_selectedWeeks weeks',
            onChanged: (value) {
              _selectedWeeks = value.round();
              _regeneratePreviews();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewList(ColorScheme colorScheme, {required double contentWidth}) {
    if (_previews.isEmpty) {
      return Center(
        child: Text(
          'No upcoming dates found.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final isWide = ResponsiveLayout.isWideScreen(contentWidth);
    final columns = contentWidth >= ResponsiveLayout.desktop
        ? 3
        : (isWide ? 2 : 1);

    if (columns == 1) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        itemCount: _previews.length,
        itemBuilder: (context, index) => _buildPreviewCard(
          index,
          colorScheme,
          wideLayout: false,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: columns >= 3 ? 0.92 : 1.0,
      ),
      itemCount: _previews.length,
      itemBuilder: (context, index) => _buildPreviewCard(
        index,
        colorScheme,
        wideLayout: true,
      ),
    );
  }

  Widget _buildPreviewCard(int index, ColorScheme colorScheme, {required bool wideLayout}) {
    final preview = _previews[index];
    if (wideLayout) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: _buildCoverImage(
                preview,
                colorScheme,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatBulkPostPreviewDate(preview.date),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (preview.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          preview.subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (_hasSubtitles || _hasCoverPool)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 4,
                          children: [
                            if (_hasCoverPool)
                              TextButton.icon(
                                onPressed: () => _shuffleHeadMedia(index),
                                icon: const Icon(Icons.image_outlined, size: 16),
                                label: const Text('Cover'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                            if (_hasSubtitles)
                              TextButton.icon(
                                onPressed: () => _shuffleSubtitle(index),
                                icon: const Icon(Icons.shuffle, size: 16),
                                label: const Text('Subtitle'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: _buildCoverImage(preview, colorScheme),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatBulkPostPreviewDate(preview.date),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(preview.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (preview.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(preview.subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (_hasSubtitles || _hasCoverPool)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasCoverPool)
                    IconButton(
                      icon: const Icon(Icons.image_outlined, size: 18),
                      tooltip: 'Randomise cover',
                      onPressed: () => _shuffleHeadMedia(index),
                    ),
                  if (_hasSubtitles)
                    IconButton(
                      icon: const Icon(Icons.shuffle, size: 18),
                      tooltip: 'Randomise subtitle',
                      onPressed: () => _shuffleSubtitle(index),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(
    _PostPreview preview,
    ColorScheme colorScheme, {
    BorderRadius? borderRadius,
  }) {
    final media = preview.headMedia;
    final radius = borderRadius ?? BorderRadius.circular(8);

    if (media == null) {
      return ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: colorScheme.primaryContainer,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _formatBulkPostPreviewDate(preview.date),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      );
    }

    final bool isVideo = media['type'] == 'vid';
    final String? thumbnailSrc = media['thumbnailSrc'] as String?;
    final String src = (media['src'] as String?) ?? '';
    final displaySrc = (isVideo ? thumbnailSrc : src)?.trim();
    final imageUrl =
        displaySrc != null && displaySrc.isNotEmpty ? NetworkImageHelper.getImageUrl(displaySrc) : null;

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverFallback(isVideo, colorScheme),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
            )
          else
            _coverFallback(isVideo, colorScheme),
          if (isVideo)
            const Positioned(
              right: 8,
              bottom: 8,
              child: Icon(Icons.play_circle_fill, size: 28, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _coverFallback(bool isVideo, ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        color: colorScheme.onSurfaceVariant,
        size: 32,
      ),
    );
  }

  Widget _buildRelationPicker(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'Post relationship',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        RadioListTile<_BulkPostRelation>(
          dense: true,
          title: const Text('Children of this post'),
          subtitle: const Text('New posts appear under the current post'),
          value: _BulkPostRelation.child,
          groupValue: _selectedRelation,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedRelation = value);
          },
        ),
        if (widget.sourcePostParentId != null)
          RadioListTile<_BulkPostRelation>(
            dense: true,
            title: const Text('Siblings of this post'),
            subtitle: const Text('New posts share the same parent as the current post'),
            value: _BulkPostRelation.sibling,
            groupValue: _selectedRelation,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedRelation = value);
            },
          ),
        const Divider(height: 1),
      ],
    );
  }
}

String _dayWithOrdinal(int day) {
  if (day >= 11 && day <= 13) return '${day}th';
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

String _formatBulkPostTitleDate(DateTime date) =>
    '${_dayWithOrdinal(date.day)} ${DateFormat('MMM').format(date)}';

String _formatBulkPostPreviewDate(DateTime date) =>
    '${DateFormat('EEE').format(date)} ${_dayWithOrdinal(date.day)} ${DateFormat('MMM').format(date)}';

class _PostPreview {
  String title;
  String subtitle;
  final DateTime date;
  Map<String, dynamic>? headMedia;

  _PostPreview({
    required this.title,
    required this.subtitle,
    required this.date,
    this.headMedia,
  });
}
