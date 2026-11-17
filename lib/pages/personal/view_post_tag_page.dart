import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/post_tag.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/activity_time_series.dart';
import '../../utility/app_context.dart';
import '../../utility/app_links.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/person_display_name.dart';
import '../../utility/post_tag_activity_stats.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/catalog/colored_chip.dart';
import '../../widgets/catalog/post_tag_chip.dart';
import '../../widgets/catalog/user_tag_graphic.dart';
import '../../widgets/common/activity_trend_section.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/information/info_section_card.dart';
import '../../widgets/posts/post_head.dart';
import '../../widgets/role_access_gate.dart';
import '../../widgets/two_column_masonry.dart';
import '../../widgets/user_avatar.dart';

/// Signed-in progress for one post tag: past totals, a weekly chart, and the
/// posts themselves.
///
/// Heads stay on this page. They are not written into [AppContext.eventHeads].
class ViewPostTagPage extends StatefulWidget {
  const ViewPostTagPage({
    super.key,
    required this.tagId,
    this.onEdit,
  });

  final String tagId;

  /// Area-admin edit of the catalogue fields. Omitted for other readers.
  final VoidCallback? onEdit;

  @override
  State<ViewPostTagPage> createState() => _ViewPostTagPageState();
}

class _ViewPostTagPageState extends State<ViewPostTagPage> {
  static const int _visiblePosts = 4;
  static const int _visibleSpeakers = 8;

  final EventHeadDBManager _headsDb = EventHeadDBManager();

  List<EventHead> _heads = [];
  DateTime? _windowAnchor;
  String? _locationName;
  bool _loading = true;
  Object? _error;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool showProgress = true}) async {
    final generation = ++_loadGeneration;
    final now = DateTime.now();
    if (showProgress) {
      setState(() {
        _loading = true;
        _error = null;
        _windowAnchor = now;
      });
    }

    try {
      final heads = await _headsDb.fetchHeadsWithEventDateInRange(
        startInclusive: PostTagActivityStats.rangeStartInclusive(now),
        endExclusive: PostTagActivityStats.rangeEndExclusive(now),
      );
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _heads = heads;
        _windowAnchor = now;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      debugPrint('Could not load post tag activity: $e\n$st');
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  void _selectLocation(String? name) {
    setState(() => _locationName = name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.select<AppContext, int>((appContext) => appContext.sessionEpoch);
    context.select<AppContext, int>((appContext) => appContext.catalogsEpoch);
    context.select<AppContext, int>((appContext) => appContext.usersEpoch);
    final appContext = Provider.of<AppContext>(context, listen: false);
    final tag = appContext.postTagById(widget.tagId);
    final colorScheme = Theme.of(context).colorScheme;

    return RoleAccessGate(
      allow: (user) => user.id != '0',
      deniedMessage: l10n.postTagsSignedInOnly,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tag?.name ?? l10n.managePostTagsTitle),
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          actions: [
            if (widget.onEdit != null && tag != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.managePostTagsEdit,
                onPressed: widget.onEdit,
              ),
          ],
        ),
        body: _insetBody(
          context,
          _body(context, l10n, appContext, tag),
        ),
      ),
    );
  }

  /// Same side inset as church statistics and an open post: a share of the
  /// window once it is wide, and 16 on a phone. [ResponsiveContent]'s max-width
  /// mode leaves a 1,200–1,400 window flush, which is a normal web width.
  Widget _insetBody(BuildContext context, Widget child) {
    final window = MediaQuery.sizeOf(context).width;
    final horizontal = ResponsiveLayout.horizontalGutter(
          window,
          narrowPadding: 0,
        ) +
        16;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.maxContentWidth(window),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    AppContext appContext,
    PostTag? tag,
  ) {
    if (_loading) {
      return LoadProgressBody(
        message: l10n.postTagDetailLoading,
        completedSteps: 0,
        totalSteps: 1,
      );
    }
    if (_error != null) {
      return LoadProgressBody(
        message: l10n.postTagDetailLoading,
        completedSteps: 0,
        totalSteps: 1,
        error: _error,
        errorTitle: l10n.postTagDetailLoadError,
        onRetry: _load,
      );
    }
    if (tag == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.postTagDetailUnavailable,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final activity = _activity(appContext, tag);
    return _detail(context, l10n, appContext, tag, activity);
  }

  _TagActivity _activity(AppContext appContext, PostTag tag) {
    final snapshot = PostTagActivityStats.compute(
      tagId: tag.id,
      heads: _heads,
      locations: appContext.allLocations,
      now: _windowAnchor,
      locationName: _locationName,
    );
    final selected = _locationName;
    final active = selected != null &&
            snapshot.locations.any((row) => row.locationName == selected)
        ? selected
        : null;
    return _TagActivity(snapshot: snapshot, locationName: active);
  }

  Widget _detail(
    BuildContext context,
    AppLocalizations l10n,
    AppContext appContext,
    PostTag tag,
    _TagActivity activity,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final description = tag.description;
    final snapshot = activity.snapshot;
    final locationName = activity.locationName;
    final anchor = _windowAnchor ?? DateTime.now();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        if (tag.imageUrl != null) ...[
          UserTagGraphic(
            imageUrl: tag.imageUrl,
            height: 200,
            heroTag: 'post_tag_cover_${tag.id}',
          ),
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: PostTagChip(tag: tag),
        ),
        const SizedBox(height: 16),
        Text(
          tag.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description ?? l10n.postTagDetailDescriptionEmpty,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: description == null
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        if (snapshot.locations.isEmpty)
          InfoSectionCard(
            icon: Icons.insights_outlined,
            title: l10n.postTagDetailProgressTitle,
            subtitle: l10n.postTagDetailProgressSubtitle,
            content: Text(
              l10n.postTagDetailEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          Text(
            l10n.postTagDetailLocation,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ColoredChip(
                label: l10n.postTagDetailAllLocations,
                selected: locationName == null,
                onTap: () => _selectLocation(null),
              ),
              for (final row in snapshot.locations)
                ColoredChip(
                  label: row.locationName,
                  selected: row.locationName == locationName,
                  onTap: () => _selectLocation(
                    row.locationName == locationName ? null : row.locationName,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _stackSectionCards([
            _ProgressCard(
              snapshot: snapshot,
              locationName: locationName,
              anchor: anchor,
            ),
            _LocationsCard(
              rows: snapshot.locations,
              selectedName: locationName,
              onSelect: _selectLocation,
            ),
            _PostsCard(
              icon: Icons.event_outlined,
              title: l10n.postTagDetailUpcomingTitle,
              subtitle: locationName == null
                  ? l10n.postTagDetailUpcomingSubtitle
                  : l10n.postTagDetailUpcomingSubtitleAt(locationName),
              empty: l10n.postTagDetailUpcomingEmpty,
              posts: snapshot.upcomingHeads,
              visibleLimit: _visiblePosts,
              onReturn: () => _load(showProgress: false),
            ),
            _PostsCard(
              icon: Icons.history,
              title: l10n.postTagDetailRecentTitle,
              subtitle: locationName == null
                  ? l10n.postTagDetailRecentSubtitle
                  : l10n.postTagDetailRecentSubtitleAt(locationName),
              empty: l10n.postTagDetailRecentEmpty,
              posts: snapshot.pastHeads,
              visibleLimit: _visiblePosts,
              onReturn: () => _load(showProgress: false),
            ),
            if (snapshot.speakers.isNotEmpty)
              _SpeakersCard(
                speakers: snapshot.speakers,
                locationName: locationName,
                visibleLimit: _visibleSpeakers,
                guest: appContext.isCurrentUserGuest,
              ),
          ]),
        ],
      ],
    );
  }

  Widget _stackSectionCards(List<Widget> cards) {
    if (!ResponsiveLayout.isWideScreenOf(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            cards[i],
          ],
        ],
      );
    }
    return TwoColumnMasonry(children: cards);
  }
}

class _TagActivity {
  const _TagActivity({required this.snapshot, required this.locationName});

  final PostTagActivitySnapshot snapshot;
  final String? locationName;
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.snapshot,
    required this.locationName,
    required this.anchor,
  });

  final PostTagActivitySnapshot snapshot;
  final String? locationName;
  final DateTime anchor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final past = snapshot.past;
    final average = past.averageAttendance;
    final chartStart = PostTagActivityStats.rangeStartInclusive(anchor);
    final chartEnd = PostTagActivityStats.pastRangeEndExclusive(anchor);

    return InfoSectionCard(
      icon: Icons.insights_outlined,
      title: l10n.postTagDetailProgressTitle,
      subtitle: locationName == null
          ? l10n.postTagDetailProgressSubtitle
          : l10n.postTagDetailProgressSubtitleAt(locationName!),
      content: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatGrid(
              tiles: [
                _StatTile(
                  icon: Icons.event_note_outlined,
                  value: '${past.eventCount}',
                  label: l10n.postTagDetailEventsLabel,
                  hint: l10n.postTagDetailEventsHint,
                ),
                _StatTile(
                  icon: Icons.groups_outlined,
                  value: '${past.attendanceTotal}',
                  label: l10n.postTagDetailAttendedLabel,
                  hint: l10n.postTagDetailAttendedHint,
                ),
                _StatTile(
                  icon: Icons.show_chart,
                  value: average == null ? '—' : _formatAverage(average),
                  label: l10n.postTagDetailAverageLabel,
                  hint: l10n.postTagDetailAverageHint,
                ),
                _StatTile(
                  icon: Icons.favorite_border,
                  value: '${past.interestedTotal}',
                  label: l10n.postTagDetailInterestedLabel,
                  hint: l10n.postTagDetailInterestedHint,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.postTagDetailProgressFootnote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (snapshot.pastHeads.isNotEmpty) ...[
              const SizedBox(height: 20),
              ActivityTrendSection(
                title: l10n.churchHubActivityTrendTitle,
                subtitle: l10n.postTagDetailTrendSubtitle,
                countLabel: l10n.churchHubActivityTrendMetricPosts,
                countPoints: ActivityTimeSeries.fromPosts(
                  posts: snapshot.pastHeads,
                  metric: ActivityTimeSeriesMetric.count,
                  startInclusive: chartStart,
                  endExclusive: chartEnd,
                ),
                attendancePoints: ActivityTimeSeries.fromPosts(
                  posts: snapshot.pastHeads,
                  metric: ActivityTimeSeriesMetric.attendance,
                  startInclusive: chartStart,
                  endExclusive: chartEnd,
                ),
                emptyMessage: l10n.activityTrendEmpty,
                weeklyHint: l10n.postTagDetailTrendWeeklyHint,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationsCard extends StatelessWidget {
  const _LocationsCard({
    required this.rows,
    required this.selectedName,
    required this.onSelect,
  });

  final List<PostTagLocationRow> rows;
  final String? selectedName;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxAttendance = rows.fold<int>(
      0,
      (max, row) =>
          row.past.attendanceTotal > max ? row.past.attendanceTotal : max,
    );

    return InfoSectionCard(
      icon: Icons.location_on_outlined,
      title: l10n.postTagDetailStatsTitle,
      subtitle: l10n.postTagDetailStatsSubtitle,
      content: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _LocationRow(
              row: rows[i],
              selected: rows[i].locationName == selectedName,
              maxAttendance: maxAttendance,
              onTap: () => onSelect(
                rows[i].locationName == selectedName
                    ? null
                    : rows[i].locationName,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.row,
    required this.selected,
    required this.maxAttendance,
    required this.onTap,
  });

  final PostTagLocationRow row;
  final bool selected;
  final int maxAttendance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final average = row.past.averageAttendance;
    final parts = <String>[
      l10n.postTagDetailEvents(row.past.eventCount),
      l10n.postTagDetailAttendance(row.past.attendanceTotal),
      if (average != null)
        l10n.postTagDetailAverageShort(_formatAverage(average)),
      if (row.upcomingEventCount > 0)
        l10n.postTagDetailComingUp(row.upcomingEventCount),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.15),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.locationName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          parts.join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (maxAttendance > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: row.past.attendanceTotal / maxAttendance,
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PostsCard extends StatelessWidget {
  const _PostsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.empty,
    required this.posts,
    required this.visibleLimit,
    required this.onReturn,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String empty;
  final List<EventHead> posts;
  final int visibleLimit;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final visible =
        posts.length > visibleLimit ? posts.take(visibleLimit).toList() : posts;
    final overflow = posts.length - visible.length;

    return InfoSectionCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      content: posts.isEmpty
          ? SizedBox(
              width: double.infinity,
              child: Text(
                empty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final head in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PostHead(
                      thisHead: head,
                      updatePost: onReturn,
                    ),
                  ),
                if (overflow > 0)
                  Text(
                    l10n.postTagDetailAndMore(overflow),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SpeakersCard extends StatelessWidget {
  const _SpeakersCard({
    required this.speakers,
    required this.locationName,
    required this.visibleLimit,
    required this.guest,
  });

  final List<PostTagSpeaker> speakers;
  final String? locationName;
  final int visibleLimit;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visible = speakers.length > visibleLimit
        ? speakers.take(visibleLimit).toList()
        : speakers;
    final overflow = speakers.length - visible.length;

    return InfoSectionCard(
      icon: Icons.record_voice_over_outlined,
      title: l10n.postTagDetailSpeakersTitle,
      subtitle: locationName == null
          ? l10n.postTagDetailSpeakersSubtitle
          : l10n.postTagDetailSpeakersSubtitleAt(locationName!),
      content: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                for (final speaker in visible)
                  _SpeakerTile(speaker: speaker, guest: guest),
              ],
            ),
            if (overflow > 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.postTagDetailAndMore(overflow),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpeakerTile extends StatelessWidget {
  const _SpeakerTile({required this.speaker, required this.guest});

  final PostTagSpeaker speaker;
  final bool guest;

  static const double _radius = 28;
  static const double _width = 96;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appContext = Provider.of<AppContext>(context, listen: false);
    final user = appContext.userById(speaker.uid);
    final name = PersonDisplayName.leadSpeakerLabel(
      storedName: speaker.storedName,
      user: user,
      guest: guest,
    );

    return SizedBox(
      width: _width,
      child: InkWell(
        onTap: user == null
            ? null
            : () => AppLinks.openPerson(context, id: user.id, extra: user),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _avatar(user, colorScheme),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (speaker.appearanceCount > 1) ...[
              const SizedBox(height: 2),
              Text(
                l10n.postTagDetailSpeakerPosts(speaker.appearanceCount),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _avatar(User? user, ColorScheme colorScheme) {
    if (user != null) return MyUserAvatar(user, radius: _radius);
    final src = speaker.imgSrc;
    if (src == null) {
      return CircleAvatar(
        radius: _radius,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.person, color: colorScheme.onSurfaceVariant),
      );
    }
    return CircleAvatar(
      radius: _radius,
      backgroundImage: NetworkImage(NetworkImageHelper.getImageUrl(src)),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    const columns = 2;
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += columns) {
      final end = i + columns > tiles.length ? tiles.length : i + columns;
      final slice = tiles.sublist(i, end);
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: 12),
              Expanded(
                child: j < slice.length ? slice[j] : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(children: rows);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.hint,
  });

  final IconData icon;
  final String value;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatAverage(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}
