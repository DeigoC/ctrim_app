import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/post_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/post_tag_activity_stats.dart';
import '../../widgets/catalog/post_tag_chip.dart';
import '../../widgets/catalog/user_tag_graphic.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/information/info_section_card.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/role_access_gate.dart';

/// Signed-in totals for one post tag: dated posts and attendance, by location.
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
  final EventHeadDBManager _headsDb = EventHeadDBManager();

  List<EventHead> _heads = [];
  DateTime? _windowAnchor;
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

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    setState(() {
      _loading = true;
      _error = null;
      _windowAnchor = now;
    });

    try {
      final heads = await _headsDb.fetchHeadsWithEventDateInRange(
        startInclusive: PostTagActivityStats.rangeStartInclusive(now),
        endExclusive: PostTagActivityStats.rangeEndExclusive(now),
      );
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _heads = heads;
        _loading = false;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.select<AppContext, int>((appContext) => appContext.sessionEpoch);
    context.select<AppContext, int>((appContext) => appContext.catalogsEpoch);
    final appContext = Provider.of<AppContext>(context, listen: false);
    final tag = appContext.postTagById(widget.tagId);

    return RoleAccessGate(
      allow: (user) => user.id != '0',
      deniedMessage: l10n.postTagsSignedInOnly,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tag?.name ?? l10n.managePostTagsTitle),
          actions: [
            if (widget.onEdit != null && tag != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.managePostTagsEdit,
                onPressed: widget.onEdit,
              ),
          ],
        ),
        body: ResponsiveContent(
          child: _body(context, l10n, appContext, tag),
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

    final rows = PostTagActivityStats.byLocation(
      tagId: tag.id,
      heads: _heads,
      locations: appContext.allLocations,
      now: _windowAnchor,
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        const SizedBox(height: 24),
        InfoSectionCard(
          icon: Icons.insights_outlined,
          title: l10n.postTagDetailStatsTitle,
          subtitle: l10n.postTagDetailStatsSubtitle,
          content: rows.isEmpty
              ? Text(
                  l10n.postTagDetailEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _LocationRow(row: rows[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.row});

  final PostTagLocationRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      child: Row(
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
                  '${l10n.postTagDetailEvents(row.eventCount)} · '
                  '${l10n.postTagDetailAttendance(row.attendanceTotal)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
