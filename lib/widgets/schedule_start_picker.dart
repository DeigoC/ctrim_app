import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'common/app_dialog.dart';

/// Preset offsets from the event start when setting a schedule item's start time.
const List<({String label, int minutesOffset, IconData icon})>
    kScheduleStartPresets = [
  (label: '1 hour before event', minutesOffset: -60, icon: Icons.schedule),
  (label: '30 minutes before event', minutesOffset: -30, icon: Icons.schedule),
  (label: '15 minutes before event', minutesOffset: -15, icon: Icons.schedule),
  (label: 'Event start', minutesOffset: 0, icon: Icons.event),
  (label: '15 minutes after event', minutesOffset: 15, icon: Icons.schedule),
  (label: '30 minutes after event', minutesOffset: 30, icon: Icons.schedule),
];

const _customStartTimeSentinel = Object();

/// Picks a start [DateTime] on the same calendar day as [eventStart].
///
/// Shows common offsets from the event start first, with an option to open
/// the system time picker. Returns `null` when the user cancels.
Future<DateTime?> showScheduleStartTimePicker({
  required BuildContext context,
  required DateTime eventStart,
  DateTime? initialStart,
  String title = 'Select Start Time',
}) async {
  final timeFormat = DateFormat('HH:mm');
  final result = await showDialog<Object?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ScheduleStartTimeDialog(
      eventStart: eventStart,
      timeFormat: timeFormat,
      title: title,
    ),
  );
  if (result == null) return null;
  if (result is DateTime) return result;

  final selected = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(
      initialStart ?? eventStart,
    ),
    helpText: 'When does the role start?',
  );
  if (selected == null || !context.mounted) return null;

  return DateTime(
    eventStart.year,
    eventStart.month,
    eventStart.day,
    selected.hour,
    selected.minute,
  );
}

class _ScheduleStartTimeDialog extends StatelessWidget {
  const _ScheduleStartTimeDialog({
    required this.eventStart,
    required this.timeFormat,
    required this.title,
  });

  final DateTime eventStart;
  final DateFormat timeFormat;
  final String title;

  DateTime _startAtOffset(int minutesOffset) =>
      eventStart.add(Duration(minutes: minutesOffset));

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialog(
      icon: Icons.play_arrow,
      title: title,
      scrollable: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.45,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            for (final preset in kScheduleStartPresets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    preset.icon,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(preset.label),
                subtitle: Text(
                  'Starts at ${timeFormat.format(_startAtOffset(preset.minutesOffset))}',
                ),
                trailing: Icon(Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant),
                onTap: () => Navigator.of(context).pop(
                  _startAtOffset(preset.minutesOffset),
                ),
              ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.edit_calendar,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              title: const Text('Custom start time'),
              subtitle: const Text('Set a specific start time'),
              trailing: Icon(Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant),
              onTap: () => Navigator.of(context).pop(_customStartTimeSentinel),
            ),
          ],
        ),
      ),
      actions: AppDialogActions(
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}
