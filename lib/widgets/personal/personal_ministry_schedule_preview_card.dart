import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event/event_program.dart';
import '../../pages/personal/view_team_rota_page.dart';
import '../../pages/personal/view_team_rota_schedule_page.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/ministry_schedule_preview.dart';
import '../../utility/team_rota.dart';
import '../information/info_section_card.dart';

/// Personal home card: one square per ministry, across the dashboard width.
///
/// A square opens that ministry's next service. The button opens the month list.
class PersonalMinistrySchedulePreviewCard extends StatefulWidget {
  const PersonalMinistrySchedulePreviewCard({
    super.key,
    required this.appContext,
  });

  final AppContext appContext;

  @override
  State<PersonalMinistrySchedulePreviewCard> createState() =>
      _PersonalMinistrySchedulePreviewCardState();
}

class _PersonalMinistrySchedulePreviewCardState
    extends State<PersonalMinistrySchedulePreviewCard> {
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');

  MinistrySchedulePreviewSnapshot? _snapshot;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && (!_loading || _error != null)) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final snapshot = await MinistrySchedulePreview.load(
        user: widget.appContext.currentUser,
        allTags: widget.appContext.allTags,
        locations: widget.appContext.allLocations,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      debugPrint('Could not load ministry schedule preview: $e\n$st');
      if (!mounted) return;
      if (silent && _snapshot != null) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  void _applyProgram(String postId, EventProgram program) {
    final current = _snapshot;
    if (current == null) return;
    final programs = Map<String, EventProgram>.from(current.programs);
    programs[postId] = program;
    TeamRotaPost? existing;
    for (final post in current.posts) {
      if (post.head.id == postId) {
        existing = post;
        break;
      }
    }
    final updated = existing == null
        ? null
        : MinistrySchedulePreview.singlePost(
            head: existing.head,
            program: program,
            selectedTagIDs: current.selectedTagIDs,
            locationFilter: current.locationFilter,
          );
    final posts = <TeamRotaPost>[
      for (final post in current.posts)
        if (post.head.id != postId) post else if (updated != null) updated,
    ];
    setState(() {
      _snapshot = MinistrySchedulePreviewSnapshot(
        posts: posts,
        programs: programs,
        selectedTagIDs: current.selectedTagIDs,
        locationFilter: current.locationFilter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.select((AppContext c) => (c.usersEpoch, c.catalogsEpoch));

    return InfoSectionCard(
      icon: Icons.groups_rounded,
      title: l10n.teamRota,
      subtitle: l10n.teamRotaSubtitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBody(l10n),
          if (!_loading) ...[
            const SizedBox(height: 12),
            _buildViewButton(l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.teamRotaCouldNotLoad,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.personalMinistryScheduleRetry),
          ),
        ],
      );
    }
    final snapshot = _snapshot;
    final ministries = snapshot == null
        ? const <MinistryScheduleMinistry>[]
        : MinistrySchedulePreview.ministryStates(
            posts: snapshot.posts,
            allTags: widget.appContext.allTags,
            selectedTagIDs: snapshot.selectedTagIDs,
            viewerId: widget.appContext.currentUser.id,
          );
    if (ministries.isEmpty) {
      return Text(
        l10n.personalMinistryScheduleEmpty,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }
    return _MinistryGrid(
      ministries: ministries,
      dateLabel: (ministry) => _dateLabel(l10n, ministry),
      onOpen: _openMinistry,
    );
  }

  Widget _buildViewButton(AppLocalizations l10n) {
    final open = _snapshot?.hasOpenSlot ?? false;
    final icon = const Icon(Icons.groups_rounded);
    final label = Text(l10n.personalMinistryScheduleView);
    if (open) {
      return FilledButton.icon(
        onPressed: _openFullSchedule,
        icon: icon,
        label: label,
      );
    }
    return OutlinedButton.icon(
      onPressed: _openFullSchedule,
      icon: icon,
      label: label,
    );
  }

  String? _dateLabel(AppLocalizations l10n, MinistryScheduleMinistry ministry) {
    final date = ministry.nextPost?.head.eventDate;
    if (ministry.nextPost == null) return null;
    if (date == null) return l10n.personalScheduleDateTbc;
    return _eventDateFormat.format(date);
  }

  Future<void> _openFullSchedule() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ViewTeamRotaPage()),
    );
    if (mounted) _load(silent: true);
  }

  void _openMinistry(MinistryScheduleMinistry ministry) {
    final post = ministry.nextPost;
    if (post == null) return;
    final program = _snapshot?.programs[post.head.id];
    if (program == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewTeamRotaSchedulePage(
          head: post.head,
          program: program,
          selectedTagIDs: {ministry.tagId},
          onProgramUpdated: (updated) => _applyProgram(post.head.id, updated),
        ),
      ),
    );
  }
}

int _ministryColumnCount(double width) {
  final count = (width / 156).floor();
  if (count < 2) return 2;
  if (count > 8) return 8;
  return count;
}

class _MinistryGrid extends StatelessWidget {
  const _MinistryGrid({
    required this.ministries,
    required this.dateLabel,
    required this.onOpen,
  });

  final List<MinistryScheduleMinistry> ministries;
  final String? Function(MinistryScheduleMinistry ministry) dateLabel;
  final ValueChanged<MinistryScheduleMinistry> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _ministryColumnCount(constraints.maxWidth);
        final tileWidth = (constraints.maxWidth - 12 * (columns - 1)) / columns;
        final minHeight = tileWidth.clamp(120.0, 156.0);
        final rows = <Widget>[];
        for (var i = 0; i < ministries.length; i += columns) {
          final end =
              i + columns > ministries.length ? ministries.length : i + columns;
          final slice = ministries.sublist(i, end);
          if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) const SizedBox(width: 12),
                  Expanded(
                    child: j < slice.length
                        ? _MinistrySquare(
                            ministry: slice[j],
                            dateLabel: dateLabel(slice[j]),
                            minHeight: minHeight,
                            onTap: slice[j].nextPost == null
                                ? null
                                : () => onOpen(slice[j]),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

class _MinistrySquare extends StatelessWidget {
  const _MinistrySquare({
    required this.ministry,
    required this.dateLabel,
    required this.minHeight,
    required this.onTap,
  });

  final MinistryScheduleMinistry ministry;
  final String? dateLabel;
  final double minHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent =
        UserTagHelpers.parseColor(ministry.colorHex) ?? colorScheme.primary;
    final open = ministry.openSlots > 0;
    final serving = ministry.viewerIsServing;
    final borderColor = open
        ? colorScheme.error.withValues(alpha: 0.45)
        : serving
            ? colorScheme.primary.withValues(alpha: 0.45)
            : colorScheme.outlineVariant;

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 6, color: accent),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ministry.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (open)
                      Text(
                        l10n.teamRotaCardGaps(ministry.openSlots),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (ministry.nextPost == null)
                      Text(
                        l10n.personalMinistryScheduleQuiet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (!serving)
                      Text(
                        l10n.personalMinistryScheduleCovered,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (serving) ...[
                      if (open) const SizedBox(height: 2),
                      Text(
                        l10n.teamRotaYoureServing,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (dateLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
