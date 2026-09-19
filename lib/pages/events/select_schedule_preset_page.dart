import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/post_template.dart';
import '../../utility/app_context.dart';
import '../../utility/post_template_loader.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/my_avatar_stack.dart';
import '../../widgets/posts/schedule_preset_picker.dart';

/// Pick a schedule preset from any template that has one.
class SelectSchedulePresetPage extends StatefulWidget {
  const SelectSchedulePresetPage({
    super.key,
    this.preferredTitle,
    this.preferredLocation,
  });

  final String? preferredTitle;
  final String? preferredLocation;

  @override
  State<SelectSchedulePresetPage> createState() =>
      _SelectSchedulePresetPageState();
}

class _SelectSchedulePresetPageState extends State<SelectSchedulePresetPage> {
  List<PostTemplate> _templates = const [];
  bool _loading = true;
  Object? _loadError;
  String _status = 'Loading templates…';
  int _completed = 0;
  int _total = 4;
  String? _expandedTemplateId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _status = 'Loading templates…';
      _completed = 0;
      _total = 4;
    });

    try {
      final templates = await PostTemplateLoader.load(
        onProgress: ({required completed, required total, required message}) {
          if (!mounted) return;
          setState(() {
            _completed = completed;
            _total = total;
            _status = message;
          });
        },
      );
      if (!mounted) return;

      final withPresets =
          templates.where((t) => t.schedulePresets.isNotEmpty).toList()
            ..sort((a, b) {
              final aScore = _relevanceScore(a);
              final bScore = _relevanceScore(b);
              if (aScore != bScore) return bScore.compareTo(aScore);
              return a.title.compareTo(b.title);
            });

      setState(() {
        _templates = withPresets;
        _loading = false;
        if (withPresets.isNotEmpty && _relevanceScore(withPresets.first) > 0) {
          _expandedTemplateId = withPresets.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  int _relevanceScore(PostTemplate template) {
    var score = 0;
    final preferredTitle = widget.preferredTitle?.trim();
    if (preferredTitle != null && preferredTitle.isNotEmpty) {
      final title = template.title.trim();
      if (title.isNotEmpty) {
        if (preferredTitle == title ||
            preferredTitle.startsWith('$title ') ||
            preferredTitle.startsWith('$title–') ||
            preferredTitle.startsWith('$title –') ||
            preferredTitle.startsWith('$title -')) {
          score += 10;
        } else if (preferredTitle.toLowerCase().contains(title.toLowerCase())) {
          score += 4;
        }
      }
    }
    final preferredLocation = widget.preferredLocation?.trim();
    if (preferredLocation != null &&
        preferredLocation.isNotEmpty &&
        template.location.trim().toLowerCase() ==
            preferredLocation.toLowerCase()) {
      score += 2;
    }
    return score;
  }

  void _onSelect(PostTemplate template, SchedulePreset preset) {
    Navigator.of(context).pop((template: template, preset: preset));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = ResponsiveLayout.horizontalGutter(
        MediaQuery.sizeOf(context).width,
        narrowPadding: 16);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply schedule preset'),
        backgroundColor: colorScheme.surface,
      ),
      body: _buildBody(colorScheme, horizontalPadding),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, double horizontalPadding) {
    if (_loading) {
      return LoadProgressBody(
        message: _status,
        completedSteps: _completed,
        totalSteps: _total,
      );
    }

    if (_loadError != null) {
      return LoadProgressBody(
        message: 'Could not load templates',
        completedSteps: 0,
        totalSteps: 1,
        error: _loadError,
        errorTitle: 'Could not load templates',
        onRetry: _load,
      );
    }

    if (_templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No templates have a schedule preset yet.\nAdd one under Personal → Post Templates → Schedule.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final appContext = Provider.of<AppContext>(context, listen: false);

    return ListView.builder(
      padding:
          EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 24),
      itemCount: _templates.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Pick a named running order from any template. Suggested matches for this post are listed first.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        final template = _templates[index - 1];
        final suggested = _relevanceScore(template) > 0;
        final expanded = _expandedTemplateId == template.id;
        final presetCount = template.schedulePresets.length;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(template.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  [
                    if (suggested) 'Suggested for this post',
                    '$presetCount schedule preset${presetCount == 1 ? '' : 's'}',
                    if (template.location.isNotEmpty) template.location,
                  ].join(' · '),
                ),
                trailing:
                    Icon(expanded ? Icons.expand_less : Icons.expand_more),
                onTap: () {
                  if (presetCount == 1) {
                    _onSelect(template, template.schedulePresets.first);
                    return;
                  }
                  setState(() {
                    _expandedTemplateId = expanded ? null : template.id;
                  });
                },
              ),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: [
                      for (final preset in template.schedulePresets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side:
                                  BorderSide(color: colorScheme.outlineVariant),
                            ),
                            title: Text(preset.name),
                            subtitle: Text(schedulePresetSubtitle(preset)),
                            trailing: _presetAvatars(appContext, preset),
                            onTap: () => _onSelect(template, preset),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget? _presetAvatars(AppContext appContext, SchedulePreset preset) {
    final users = [
      for (final uid in SchedulePreset.assignedUserIdsOf(preset))
        if (appContext.userById(uid) != null) appContext.userById(uid)!
    ];
    if (users.isEmpty) return const Icon(Icons.chevron_right);
    return SizedBox(
      width: 88,
      child: MyAvatarStack(users: users, height: 32),
    );
  }
}
