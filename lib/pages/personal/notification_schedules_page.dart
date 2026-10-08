import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/db_managers/notification_schedule_db_manager.dart';
import '../../firebase/functions_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/notification_schedule.dart';
import '../../models/post_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/notifications/notification_device_status.dart';
import '../../utility/notifications/notification_schedule_planner.dart';
import '../../utility/notifications/notification_topics.dart';
import '../../widgets/common/action_sheet.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/responsive_content.dart';

/// Area-admin list of repeating reminders. Not a permalink.
class NotificationSchedulesPage extends StatefulWidget {
  const NotificationSchedulesPage({super.key});

  @override
  State<NotificationSchedulesPage> createState() =>
      _NotificationSchedulesPageState();
}

class _NotificationSchedulesPageState extends State<NotificationSchedulesPage> {
  final NotificationScheduleDBManager _db = NotificationScheduleDBManager();
  final EventHeadDBManager _headsDb = EventHeadDBManager();

  bool _loading = true;
  bool _started = false;
  String? _testingScheduleId;
  Object? _error;
  List<NotificationSchedule> _schedules = const [];
  List<EventHead> _heads = const [];
  DateTime _loadedAt = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final allowed = Provider.of<AppContext>(context, listen: false)
        .currentUser
        .canManageVolunteers;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!allowed) {
        setState(() => _loading = false);
        return;
      }
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        _db.fetchAll(),
        _headsDb.fetchHeadsWithEventDateInRange(
          startInclusive: now.subtract(NotificationSchedulePlanner.lookback),
          endExclusive: now.add(NotificationSchedulePlanner.previewLookahead),
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _schedules = results[0] as List<NotificationSchedule>;
        _heads = results[1] as List<EventHead>;
        _loadedAt = now;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Failed to load notification schedules: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _openEditor({NotificationSchedule? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final draft = await showModalBottomSheet<NotificationScheduleDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: _NotificationScheduleEditor(
            existing: existing,
            heads: _heads,
            now: _loadedAt,
          ),
        );
      },
    );
    if (draft == null || !mounted) return;

    final saved = await DialogManager.runWithProgressDialog(
      context: context,
      title: l10n.notificationSchedulesSaving,
      errorDescription: (_) => l10n.notificationSchedulesSaveFailed,
      action: () async {
        final row = draft.toSchedule(id: existing?.id ?? 'new');
        if (existing == null) {
          await _db.create(row);
        } else {
          await _db.updateConfig(row);
        }
      },
    );
    if (saved && mounted) await _load();
  }

  Future<void> _setEnabled(NotificationSchedule schedule, bool enabled) async {
    final previous = schedule.enabled;
    setState(() => schedule.setEnabled(enabled));
    try {
      await _db.setEnabled(id: schedule.id, enabled: enabled);
    } catch (e, st) {
      debugPrint('Failed to update notification schedule: $e\n$st');
      if (!mounted) return;
      setState(() => schedule.setEnabled(previous));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.notificationSchedulesSaveFailed,
          ),
        ),
      );
    }
  }

  Future<void> _sendTest(
    NotificationSchedule schedule,
    SchedulePreview preview,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final title = preview.head.title.trim();
    if (title.isEmpty) {
      DialogManager.showSnackBar(
        context: context,
        message: l10n.notificationSchedulesTestFailed,
        isError: true,
      );
      return;
    }

    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: l10n.notificationSchedulesTestTitle,
      content: l10n.notificationSchedulesTestBody(title),
      confirmText: l10n.notificationSchedulesTest,
      cancelText: l10n.cancel,
    );
    if (!confirmed || !mounted) return;

    setState(() => _testingScheduleId = schedule.id);
    try {
      final authId = AuthManager().currentAuthUID;
      final token = await NotificationDeviceStatusService().currentDeviceToken(
        webAuthId: kIsWeb && authId.isNotEmpty ? authId : null,
      );
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        DialogManager.showSnackBar(
          context: context,
          message: l10n.notificationSchedulesTestNoToken,
          isError: true,
        );
        return;
      }

      final result = await CloudFunctionManager().sendMessageToSelectedTokens(
        tokens: [token],
        title: title,
        body: NotificationSchedulePlanner.reminderBody(preview.head),
        data: {'PostID': preview.head.id},
      );
      if (!mounted) return;
      final ok = result.hasSuccess || result.successCount > 0;
      DialogManager.showSnackBar(
        context: context,
        message: ok
            ? l10n.notificationSchedulesTestSent
            : result.feedbackMessage,
        isError: !ok,
      );
    } catch (e, st) {
      debugPrint('Scheduled notification test failed: $e\n$st');
      if (!mounted) return;
      DialogManager.showSnackBar(
        context: context,
        message: l10n.notificationSchedulesTestFailed,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _testingScheduleId = null);
    }
  }

  Future<void> _delete(NotificationSchedule schedule) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: l10n.notificationSchedulesDeleteTitle,
      content: l10n.notificationSchedulesDeleteBody,
      confirmText: l10n.notificationSchedulesDelete,
      cancelText: l10n.cancel,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final deleted = await DialogManager.runWithProgressDialog(
      context: context,
      title: l10n.notificationSchedulesDeleting,
      errorDescription: (_) => l10n.notificationSchedulesSaveFailed,
      action: () => _db.delete(schedule.id),
    );
    if (deleted && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final allowed = context.select<AppContext, bool>(
      (app) => app.currentUser.canManageVolunteers,
    );
    final catalogTick = context.select<AppContext, int>(
      (app) => app.catalogsEpoch,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.notificationSchedulesTitle),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      floatingActionButton: allowed && !_loading && _error == null
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: Text(l10n.notificationSchedulesAdd),
            )
          : null,
      body: ResponsiveContent(
        narrowPadding: 16,
        child: _buildBody(l10n, allowed, catalogTick),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool allowed, int catalogTick) {
    if (!allowed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.notificationSchedulesNotAllowed,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_loading) {
      return LoadProgressBody(
        message: l10n.notificationSchedulesLoading,
        completedSteps: 0,
        totalSteps: 1,
      );
    }
    if (_error != null) {
      return LoadProgressBody(
        message: l10n.notificationSchedulesLoading,
        completedSteps: 0,
        totalSteps: 1,
        error: _error,
        onRetry: _load,
        errorTitle: l10n.notificationSchedulesLoadFailed,
      );
    }
    if (_schedules.isEmpty) {
      return _EmptySchedules(onAdd: () => _openEditor());
    }

    final appContext = Provider.of<AppContext>(context, listen: false);
    return ListView.separated(
      key: ValueKey(catalogTick),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 88),
      itemCount: _schedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        final tag = appContext.postTagById(schedule.postTagId);
        final preview = NotificationSchedulePlanner.preview(
          schedule: schedule,
          heads: _heads,
          now: _loadedAt,
        );
        return _ScheduleCard(
          schedule: schedule,
          tagName: tag?.name ?? l10n.notificationSchedulesUnknownTag,
          preview: preview,
          testing: _testingScheduleId == schedule.id,
          onEdit: () => _openEditor(existing: schedule),
          onEnabled: (enabled) => _setEnabled(schedule, enabled),
          onTest: preview == null
              ? null
              : () => _sendTest(schedule, preview),
          onDelete: () => _delete(schedule),
        );
      },
    );
  }
}

class _EmptySchedules extends StatelessWidget {
  const _EmptySchedules({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_send_rounded,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.notificationSchedulesEmptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.notificationSchedulesEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.notificationSchedulesAdd),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.tagName,
    required this.preview,
    required this.testing,
    required this.onEdit,
    required this.onEnabled,
    required this.onTest,
    required this.onDelete,
  });

  final NotificationSchedule schedule;
  final String tagName;
  final SchedulePreview? preview;
  final bool testing;
  final VoidCallback onEdit;
  final ValueChanged<bool> onEnabled;
  final VoidCallback? onTest;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tagName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: schedule.enabled,
                    onChanged: onEnabled,
                  ),
                ],
              ),
              Text(
                '${schedule.location} · ${_timingLabel(l10n, schedule)}',
                style: muted,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.notificationSchedulesAudience(
                  NotificationTopics.locationUmbrellaLabel(schedule.location),
                ),
                style: muted,
              ),
              const SizedBox(height: 8),
              ..._previewLines(l10n, theme, colorScheme),
              if (schedule.lastSentAt != null)
                Text(
                  l10n.notificationSchedulesLastSent(
                    NotificationSchedulePlanner.formatWhen(
                        schedule.lastSentAt!),
                  ),
                  style: muted,
                ),
              if (schedule.lastError != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.notificationSchedulesLastError(schedule.lastError!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
              Row(
                children: [
                  if (onTest != null)
                    TextButton.icon(
                      onPressed: testing ? null : onTest,
                      icon: testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notification_important_outlined),
                      label: Text(
                        testing
                            ? l10n.notificationSchedulesTestSending
                            : l10n.notificationSchedulesTest,
                      ),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.notificationSchedulesDelete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _previewLines(
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final body = theme.textTheme.bodyMedium;
    if (preview == null) {
      return [
        Text(l10n.notificationSchedulesNoUpcoming, style: body),
        const SizedBox(height: 4),
      ];
    }
    final lines = <Widget>[
      Text(
        l10n.notificationSchedulesNext(preview!.head.title),
        style: body?.copyWith(fontWeight: FontWeight.w600),
      ),
    ];
    if (preview!.morningOfAfterStart) {
      lines.add(
        Text(
          l10n.notificationSchedulesMorningAfterStart,
          style: body?.copyWith(color: colorScheme.error),
        ),
      );
    } else if (preview!.trigger != null) {
      lines.add(
        Text(
          l10n.notificationSchedulesSendsAt(
            NotificationSchedulePlanner.formatWhen(preview!.trigger!),
          ),
          style: body?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }
    lines.add(const SizedBox(height: 4));
    return lines;
  }
}

String _timingChipLabel(
  AppLocalizations l10n,
  NotificationScheduleTiming timing,
) {
  switch (timing) {
    case NotificationScheduleTiming.dayBefore:
      return l10n.notificationSchedulesTimingDayBefore;
    case NotificationScheduleTiming.morningOf:
      return l10n.notificationSchedulesTimingMorningOf;
    case NotificationScheduleTiming.hoursBefore:
      return l10n.notificationSchedulesTimingHoursBefore;
  }
}

String _timingLabel(AppLocalizations l10n, NotificationSchedule schedule) {
  switch (schedule.timing) {
    case NotificationScheduleTiming.dayBefore:
      return l10n.notificationSchedulesTimingDayBeforeAt(schedule.clockTime);
    case NotificationScheduleTiming.morningOf:
      return l10n.notificationSchedulesTimingMorningAt(schedule.clockTime);
    case NotificationScheduleTiming.hoursBefore:
      return l10n.notificationSchedulesTimingHours(schedule.hoursBefore);
    case null:
      return schedule.clockTime;
  }
}

class NotificationScheduleDraft {
  const NotificationScheduleDraft({
    required this.postTagId,
    required this.location,
    required this.timing,
    required this.clockTime,
    required this.hoursBefore,
    required this.enabled,
  });

  final String postTagId;
  final String location;
  final NotificationScheduleTiming timing;
  final String clockTime;
  final int hoursBefore;
  final bool enabled;

  NotificationSchedule toSchedule({required String id}) {
    return NotificationSchedule(
      id: id,
      enabled: enabled,
      postTagId: postTagId,
      location: location,
      timing: timing,
      clockTime: clockTime,
      hoursBefore: hoursBefore,
    );
  }
}

class _NotificationScheduleEditor extends StatefulWidget {
  const _NotificationScheduleEditor({
    required this.existing,
    required this.heads,
    required this.now,
  });

  final NotificationSchedule? existing;
  final List<EventHead> heads;
  final DateTime now;

  @override
  State<_NotificationScheduleEditor> createState() =>
      _NotificationScheduleEditorState();
}

class _NotificationScheduleEditorState
    extends State<_NotificationScheduleEditor> {
  late NotificationScheduleTiming _timing;
  late TimeOfDay _clock;
  late bool _enabled;
  late String _tagId;
  late String _location;
  late final TextEditingController _hoursController;
  bool _hoursError = false;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _timing = existing?.timing ?? NotificationScheduleTiming.dayBefore;
    _clock = _clockFrom(existing);
    _enabled = existing?.enabled ?? true;
    _tagId = existing?.postTagId ?? '';
    _location = existing?.location ?? '';
    _hoursController = TextEditingController(
      text: '${existing?.hoursBefore ?? 2}',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final app = Provider.of<AppContext>(context, listen: false);
    final tags = _tags(app);
    final locations = _locations(app);
    if (_tagId.isEmpty && tags.isNotEmpty) _tagId = tags.first.id;
    if (_location.isEmpty && locations.isNotEmpty) {
      _location = locations.first.name;
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  TimeOfDay _clockFrom(NotificationSchedule? existing) {
    final raw = existing?.clockTime ??
        (existing?.timing == NotificationScheduleTiming.morningOf
            ? '09:00'
            : '18:00');
    final parts = raw.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 18, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 18,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  List<PostTag> _tags(AppContext app) {
    final tags = app.activePostTags.toList();
    final existingId = widget.existing?.postTagId;
    if (existingId != null && tags.every((tag) => tag.id != existingId)) {
      final current = app.postTagById(existingId);
      if (current != null) tags.insert(0, current);
    }
    return tags;
  }

  List<({String name})> _locations(AppContext app) {
    final names = app.activeLocations.map((location) => location.name).toList();
    final existing = widget.existing?.location;
    if (existing != null && existing.isNotEmpty && !names.contains(existing)) {
      names.insert(0, existing);
    }
    return [for (final name in names) (name: name)];
  }

  String get _clockText {
    final hour = _clock.hour.toString().padLeft(2, '0');
    final minute = _clock.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int? _parsedHours() {
    final value = int.tryParse(_hoursController.text.trim());
    if (value == null) return null;
    if (value < NotificationSchedule.minHoursBefore ||
        value > NotificationSchedule.maxHoursBefore) {
      return null;
    }
    return value;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _clock,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _clock = picked);
  }

  String _previewText(AppLocalizations l10n, SchedulePreview preview) {
    final next = l10n.notificationSchedulesNext(preview.head.title);
    if (preview.morningOfAfterStart) {
      return '$next\n${l10n.notificationSchedulesMorningAfterStart}';
    }
    final trigger = preview.trigger;
    if (trigger == null) return next;
    return '$next\n${l10n.notificationSchedulesSendsAt(NotificationSchedulePlanner.formatWhen(trigger))}';
  }

  void _selectTiming(NotificationScheduleTiming timing) {
    setState(() {
      _timing = timing;
      if (timing == NotificationScheduleTiming.dayBefore) {
        _clock = const TimeOfDay(hour: 18, minute: 0);
      } else if (timing == NotificationScheduleTiming.morningOf) {
        _clock = const TimeOfDay(hour: 9, minute: 0);
      }
    });
  }

  void _save() {
    final hours =
        _timing == NotificationScheduleTiming.hoursBefore ? _parsedHours() : 2;
    if (_tagId.isEmpty || _location.isEmpty || hours == null) {
      setState(() => _hoursError = hours == null);
      return;
    }
    Navigator.of(context).pop(
      NotificationScheduleDraft(
        postTagId: _tagId,
        location: _location,
        timing: _timing,
        clockTime: _clockText,
        hoursBefore: hours,
        enabled: _enabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final app = Provider.of<AppContext>(context);
    final tags = _tags(app);
    final locations = _locations(app);
    final preview = _tagId.isEmpty || _location.isEmpty
        ? null
        : NotificationSchedulePlanner.preview(
            schedule: NotificationScheduleDraft(
              postTagId: _tagId,
              location: _location,
              timing: _timing,
              clockTime: _clockText,
              hoursBefore: _parsedHours() ?? 2,
              enabled: _enabled,
            ).toSchedule(id: widget.existing?.id ?? 'draft'),
            heads: widget.heads,
            now: widget.now,
          );

    return ActionSheetShell(
      icon: Icons.schedule_send_rounded,
      title: widget.existing == null
          ? l10n.notificationSchedulesAddTitle
          : l10n.notificationSchedulesEditTitle,
      subtitle: l10n.notificationSchedulesEditSubtitle,
      children: [
        if (tags.isEmpty)
          _EditorNote(text: l10n.notificationSchedulesNeedTag)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: DropdownButtonFormField<String>(
              initialValue: tags.any((tag) => tag.id == _tagId) ? _tagId : null,
              decoration: _fieldDecoration(
                colorScheme,
                l10n.notificationSchedulesTagLabel,
              ),
              items: [
                for (final tag in tags)
                  DropdownMenuItem(value: tag.id, child: Text(tag.name)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _tagId = value);
              },
            ),
          ),
        if (locations.isEmpty)
          _EditorNote(text: l10n.notificationSchedulesNeedLocation)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: DropdownButtonFormField<String>(
              initialValue:
                  locations.any((location) => location.name == _location)
                      ? _location
                      : null,
              decoration: _fieldDecoration(
                colorScheme,
                l10n.notificationSchedulesLocationLabel,
              ),
              items: [
                for (final location in locations)
                  DropdownMenuItem(
                    value: location.name,
                    child: Text(location.name),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _location = value);
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Text(
            l10n.notificationSchedulesTimingLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final timing in NotificationScheduleTiming.values)
                ChoiceChip(
                  label: Text(_timingChipLabel(l10n, timing)),
                  selected: _timing == timing,
                  onSelected: (_) => _selectTiming(timing),
                ),
            ],
          ),
        ),
        if (_timing == NotificationScheduleTiming.hoursBefore)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration(
                colorScheme,
                l10n.notificationSchedulesHoursLabel,
              ).copyWith(
                errorText:
                    _hoursError ? l10n.notificationSchedulesHoursInvalid : null,
              ),
              onChanged: (_) => setState(() => _hoursError = false),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule),
              label:
                  Text('${l10n.notificationSchedulesClockLabel} · $_clockText'),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Switch(
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
          ),
        ),
        if (_location.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              l10n.notificationSchedulesAudience(
                NotificationTopics.locationUmbrellaLabel(_location),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        if (preview != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              _previewText(l10n, preview),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else if (_tagId.isNotEmpty && _location.isNotEmpty)
          _EditorNote(text: l10n.notificationSchedulesNoUpcoming),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: FilledButton(
            onPressed: tags.isEmpty || locations.isEmpty ? null : _save,
            child: Text(l10n.notificationSchedulesSave),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ),
      ],
    );
  }
}

class _EditorNote extends StatelessWidget {
  const _EditorNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(ColorScheme colorScheme, String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  );
}
