import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event/event_program.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/schedule_timeline_layout.dart';
import '../../widgets/posts/schedule_coverage_band.dart';
import '../../widgets/posts/schedule_timeline.dart';

/// Rearranges a post's running order by dragging blocks on the timeline.
///
/// Pops `true` when the arrangement was kept, so the caller can flag the post
/// as edited.
class ArrangeSchedulePage extends StatefulWidget {
  const ArrangeSchedulePage({super.key, required this.eventContext});

  final EventContext eventContext;

  @override
  State<ArrangeSchedulePage> createState() => _ArrangeSchedulePageState();
}

class _ArrangeSchedulePageState extends State<ArrangeSchedulePage> {
  late final AppContext _appContext;

  /// Role timings as they were on entry, so a discard can put them back.
  late final List<({int id, DateTime start, DateTime end})> _originalTimings;

  ProgramShiftMode _mode = ProgramShiftMode.cascade;
  bool _dirty = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _appContext = Provider.of<AppContext>(context, listen: false);
    _originalTimings = [
      for (final role in widget.eventContext.program.roles)
        if (role['start'] != null && role['end'] != null)
          (
            id: role['id'] as int,
            start: role['start'] as DateTime,
            end: role['end'] as DateTime,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _allowPop || !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowPop || !_dirty) return;
        final shouldDiscard = await DialogManager.discardChanges(
          context: context,
        );
        if (!shouldDiscard || !mounted) return;
        _restoreOriginalTimings();
        _popWith(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.scheduleArrangeTitle),
          actions: [
            TextButton(
              onPressed: _onDone,
              child: Text(l10n.scheduleArrangeDone),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    widget.eventContext.program.ensureUniqueRoleIds();
    final isWide = ResponsiveLayout.isWideScreenOf(context);
    final layout = ScheduleTimelineLayout.build(
      roles: widget.eventContext.program.roles,
      laneCap: isWide
          ? ScheduleTimelineLayout.wideLaneCap
          : ScheduleTimelineLayout.phoneLaneCap,
      finishTime: widget.eventContext.program.finishTime,
    );

    if (layout.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            AppLocalizations.of(context)!.scheduleArrangeEmpty,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final horizontalPadding = ResponsiveLayout.horizontalGutter(
      MediaQuery.sizeOf(context).width,
      narrowPadding: 12,
    );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModeSelector(horizontalPadding),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (layout.coverageRoles.isNotEmpty) ...[
                    ScheduleCoverageBand(
                      coverageRoles: layout.coverageRoles,
                      usersForRole: _usersForRole,
                      onRoleTap: _showCoverageRoleHint,
                    ),
                    const SizedBox(height: 24),
                  ],
                  ScheduleTimeline(
                    layout: layout,
                    usersForRole: _usersForRole,
                    onRoleTap: _showRoleTimingHint,
                    onRoleMoved: _onRoleMoved,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(final double horizontalPadding) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<ProgramShiftMode>(
            segments: [
              ButtonSegment(
                value: ProgramShiftMode.cascade,
                icon: const Icon(Icons.low_priority),
                label: Text(l10n.scheduleArrangeModeCascade),
              ),
              ButtonSegment(
                value: ProgramShiftMode.parallel,
                icon: const Icon(Icons.call_split),
                label: Text(l10n.scheduleArrangeModeParallel),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) =>
                setState(() => _mode = selection.first),
          ),
          const SizedBox(height: 8),
          Text(
            _mode == ProgramShiftMode.cascade
                ? l10n.scheduleArrangeCascadeHint
                : l10n.scheduleArrangeParallelHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<User> _usersForRole(final Map<String, dynamic> role) {
    return (role['uids'] as List<String>)
        .map((e) => _appContext.userById(e))
        .whereType<User>()
        .toList();
  }

  void _onRoleMoved(final Map<String, dynamic> role, final DateTime newStart) {
    final moved = widget.eventContext.program.moveRoleToStart(
      roleId: role['id'] as int,
      newStart: newStart,
      mode: _mode,
    );
    if (!moved) return;
    setState(() => _dirty = true);
  }

  void _showCoverageRoleHint(final Map<String, dynamic> role) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .scheduleAllEventArrangeHint(role['title'] as String),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _showRoleTimingHint(final Map<String, dynamic> role) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .scheduleArrangeDragHint(role['title'] as String),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _restoreOriginalTimings() {
    for (final timing in _originalTimings) {
      widget.eventContext.program.updateRoleTiming(
        roleId: timing.id,
        newStart: timing.start,
        newEnd: timing.end,
        shiftFollowing: false,
      );
    }
  }

  void _onDone() {
    if (_dirty) {
      widget.eventContext.allowSavingOfTheEdit();
    }
    _popWith(_dirty);
  }

  void _popWith(final bool changed) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(changed);
    });
  }
}
