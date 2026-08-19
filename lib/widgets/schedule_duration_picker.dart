import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utility/dialog_manager.dart';

/// Preset lengths shown when setting a schedule item's end time.
const List<({String label, int minutes, IconData icon})>
    kScheduleDurationPresets = [
  (label: '5 minutes', minutes: 5, icon: Icons.timer),
  (label: '10 minutes', minutes: 10, icon: Icons.timer_10),
  (label: '15 minutes', minutes: 15, icon: Icons.schedule),
  (label: '20 minutes', minutes: 20, icon: Icons.schedule),
  (label: '25 minutes', minutes: 25, icon: Icons.schedule),
  (label: '30 minutes', minutes: 30, icon: Icons.schedule),
  (label: '45 minutes', minutes: 45, icon: Icons.schedule),
  (label: '1 hour', minutes: 60, icon: Icons.timer_outlined),
  (label: '1 hour 30 minutes', minutes: 90, icon: Icons.timer_outlined),
  (label: '2 hours', minutes: 120, icon: Icons.timer_outlined),
];

const _customFinishTimeSentinel = Object();

/// Picks an end [DateTime] on the same calendar day as [start].
///
/// Shows common durations first, with an option to open the system time picker.
/// Returns `null` when the user cancels.
Future<DateTime?> showScheduleDurationPicker({
  required BuildContext context,
  required DateTime start,
  DateTime? initialEnd,
  String title = 'Select Duration',
}) async {
  final timeFormat = DateFormat('HH:mm');
  final result = await showDialog<Object?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ScheduleDurationDialog(
      start: start,
      timeFormat: timeFormat,
      title: title,
    ),
  );
  if (result == null) return null;
  if (result is DateTime) return result;

  final selected = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(
      initialEnd ?? start.add(const Duration(hours: 1)),
    ),
    helpText: 'When does this finish?',
  );
  if (selected == null || !context.mounted) return null;

  if (!_isEndAfterStart(start: start, end: selected)) {
    await DialogManager.showAlertDialog(
      context: context,
      title: 'Invalid Finish Time',
      content:
          'Please set it after the start time, which is currently ${timeFormat.format(start)}.',
    );
    return null;
  }

  return DateTime(
    start.year,
    start.month,
    start.day,
    selected.hour,
    selected.minute,
  );
}

bool _isEndAfterStart({
  required DateTime start,
  required TimeOfDay end,
}) {
  if (end.hour > start.hour) return true;
  if (end.hour == start.hour && end.minute > start.minute) return true;
  return false;
}

class _ScheduleDurationDialog extends StatelessWidget {
  const _ScheduleDurationDialog({
    required this.start,
    required this.timeFormat,
    required this.title,
  });

  final DateTime start;
  final DateFormat timeFormat;
  final String title;

  DateTime _endOnStartDay(int minutes) => start.add(Duration(minutes: minutes));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                children: [
                  for (final preset in kScheduleDurationPresets)
                    Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            preset.icon,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(preset.label),
                        subtitle: Text(
                          'Ends at ${timeFormat.format(_endOnStartDay(preset.minutes))}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => Navigator.of(context).pop(
                          _endOnStartDay(preset.minutes),
                        ),
                      ),
                    ),
                  const Divider(),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.edit_calendar,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: const Text('Custom finish time'),
                    subtitle: const Text('Set a specific end time'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () =>
                        Navigator.of(context).pop(_customFinishTimeSentinel),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
