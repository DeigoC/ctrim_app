import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/event/event_metadata.dart';
import '../../models/post_template.dart';
import '../../utility/app_context.dart';
import '../../utility/bulk_post_dates.dart';
import '../../utility/post_template_mapper.dart';

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

  int _selectedWeeks = 4;
  int? _selectedDayOfWeek;
  _BulkPostRelation _selectedRelation = _BulkPostRelation.child;
  List<_PostPreview> _previews = [];
  bool _isCreating = false;
  int _createdCount = 0;

  String? get _effectiveParentID {
    if (widget.sourcePostId != null) {
      return _selectedRelation == _BulkPostRelation.child ? widget.sourcePostId : widget.sourcePostParentId;
    }
    return widget.parentID;
  }

  @override
  void initState() {
    super.initState();
    _selectedDayOfWeek = widget.template.defaultDayOfWeek;
    if (_selectedDayOfWeek != null) {
      _regeneratePreviews();
    }
  }

  void _regeneratePreviews() {
    if (_selectedDayOfWeek == null) return;

    final dates = computeBulkPostDates(
      dayOfWeek: _selectedDayOfWeek!,
      weeks: _selectedWeeks,
      anchorDate: widget.sourcePostEventDate,
    );
    setState(() {
      _previews = [];
      for (final date in dates) {
        final subtitle = widget.template.subtitles.isNotEmpty
            ? widget.template.subtitles[_random.nextInt(widget.template.subtitles.length)]
            : '';
        final titleDate = _formatBulkPostTitleDate(date);
        final baseTitle = widget.template.title;
        final title = '$baseTitle – $titleDate';
        _previews.add(_PostPreview(title: title, subtitle: subtitle, date: date));
      }
    });
  }

  void _shuffleSubtitle(int index) {
    if (widget.template.subtitles.isEmpty) return;
    setState(() {
      _previews[index].subtitle = widget.template.subtitles[_random.nextInt(widget.template.subtitles.length)];
    });
  }

  Future<void> _createAllPosts() async {
    setState(() {
      _isCreating = true;
      _createdCount = 0;
    });

    final appContext = Provider.of<AppContext>(context, listen: false);
    final uid = appContext.currentUser.id;
    final location = widget.template.location;
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
          template: widget.template,
          currentUserID: uid,
          parentID: parentID,
          allUsers: appContext.allUsers,
        );
        PostTemplateMapper.adjustEventProgramToDate(eventContext, preview.date);

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
      body: Column(
        children: [
          // Day picker (if template has no default)
          if (_selectedDayOfWeek == null) _buildDayPicker(colorScheme),
          // Template header
          Container(
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
                        widget.template.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (_selectedDayOfWeek != null)
                        Text('Every $dayName',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.sourcePostId != null) _buildRelationPicker(colorScheme),
          // Weeks selector
          Padding(
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
          ),
          const Divider(height: 1),
          // Preview list
          Expanded(
            child: _previews.isEmpty
                ? Center(
                    child: Text(
                      'No upcoming dates found.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                    itemCount: _previews.length,
                    itemBuilder: (context, index) {
                      final preview = _previews[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatBulkPostPreviewDate(preview.date),
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(preview.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.w600)),
                                    if (preview.subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(preview.subtitle, style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ],
                                ),
                              ),
                              if (widget.template.subtitles.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.shuffle, size: 18),
                                  tooltip: 'Randomise subtitle',
                                  onPressed: () => _shuffleSubtitle(index),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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

  Widget _buildDayPicker(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      color: colorScheme.secondaryContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.onSecondaryContainer, size: 20),
              const SizedBox(width: 8),
              Text(
                'Select day of week',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This template doesn\'t have a default day. Choose which day of the week to create posts for:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSecondaryContainer),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: List.generate(7, (i) {
              final day = i + 1;
              return FilterChip(
                label: Text(_dayNames[i]),
                selected: false,
                onSelected: (_) {
                  setState(() {
                    _selectedDayOfWeek = day;
                    _regeneratePreviews();
                  });
                },
              );
            }),
          ),
        ],
      ),
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

  _PostPreview({required this.title, required this.subtitle, required this.date});
}
