import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../widgets/my_avatar_stack.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_selector_dialog.dart';
import '../../utility/responsive_layout.dart';

class AddEventProgramPage extends StatefulWidget {
  const AddEventProgramPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<AddEventProgramPage> createState() => _AddEventProgramPageState();
}

class _AddEventProgramPageState extends State<AddEventProgramPage> {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  late final AppContext _appContext;

  final TextEditingController _tecTitle = TextEditingController(), _tecDetail = TextEditingController();
  final List<String> _selectedUsers = List.empty(growable: true);

  DateTime? _start, _end;
  bool _canSave = false, _forGuests = true, _isSaved = false, _allowPop = false;

  void _popRouteAfterAllowing() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();
  }

  @override
  void dispose() {
    _tecTitle.dispose();
    _tecDetail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop || _isSaved,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowPop || _isSaved) return;
        final shouldPop = await DialogManager.discardChanges(context: context);
        if (shouldPop && mounted) {
          _popRouteAfterAllowing();
        }
      },
      child: Scaffold(appBar: AppBar(title: const Text('Add Schedule')), body: _buildBody()),
    );
  }

  Widget _buildBody() {
    final double webHorizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 16);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: webHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Selection Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Schedule Time',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeSelector(
                          label: 'Start Time',
                          time: _start,
                          isRequired: true,
                          onTap: _onStartTimeTap,
                          icon: Icons.play_arrow,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeSelector(
                          label: 'End Time',
                          time: _end,
                          isRequired: true,
                          onTap: _start == null ? null : _onEndTimeTap,
                          icon: Icons.stop,
                          isEnabled: _start != null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Program Details Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Program Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tecTitle,
                    maxLength: 48,
                    decoration: InputDecoration(
                      label: const Text('Title*'),
                      hintText: 'What is this program about?',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.title),
                      suffixIcon: _tecTitle.text.trim().isEmpty
                          ? const Icon(Icons.warning_amber, color: Colors.amber)
                          : const Icon(Icons.check_circle, color: Colors.green),
                    ),
                    onChanged: _onRequirementsChange,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tecDetail,
                    maxLines: 3,
                    maxLength: 128,
                    decoration: const InputDecoration(
                      label: Text('Additional Details'),
                      hintText: 'Provide more information about this program...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Team Assignment Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Team Assignment',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Column(
                      children: [
                        if (_selectedUsers.isEmpty)
                          Column(
                            children: [
                              Icon(Icons.person_add_alt_1,
                                  size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              Text(
                                'No team members assigned',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                            ],
                          )
                        else
                          InkWell(
                            onTap: _onViewAssignedMembersTap,
                            child: Column(
                              children: [
                                MyAvatarStack(
                                  users: _appContext.allUsers.where((e) => _selectedUsers.contains(e.id)).toList(),
                                  appDir: _appContext.appDir,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_selectedUsers.length} member${_selectedUsers.length == 1 ? '' : 's'} assigned',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _onSelectMembersTap,
                          icon: const Icon(Icons.person_add),
                          label: Text(_selectedUsers.isEmpty ? 'Assign Members' : 'Add More Members'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Settings Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Visibility Settings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _forGuests,
                    onChanged: _onForGuestsChange,
                    title: const Text('Visible to Guests'),
                    subtitle: const Text('Allow guests to see this program item'),
                    secondary: Icon(
                      _forGuests ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          FilledButton.icon(
            onPressed: _canSave ? _onSaveClick : null,
            icon: const Icon(Icons.save),
            label: const Text('Save Program'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required DateTime? time,
    required bool isRequired,
    required VoidCallback? onTap,
    required IconData icon,
    bool isEnabled = true,
  }) {
    final bool hasTime = time != null;
    final bool showWarning = isRequired && !hasTime;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: showWarning
                ? Colors.amber
                : isEnabled
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            width: showWarning ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isEnabled
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isEnabled
                      ? (showWarning ? Colors.amber : Theme.of(context).colorScheme.primary)
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  label + (isRequired ? '*' : ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showWarning) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.warning_amber, size: 14, color: Colors.amber),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasTime ? _timeFormat.format(time) : 'Tap to set',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isEnabled
                    ? (hasTime
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // * Logic

  void _onSelectMembersTap() {
    showDialog(
        context: context,
        builder: (_) => UserSelectorDialog(
            alreadySelectedUIDs: _selectedUsers,
            includeCurrentUser: true,
            allowTaskCheck: true,
            onSelected: (id) => setState(() {
                  _selectedUsers.add(id);
                })));
  }

  void _onViewAssignedMembersTap() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.6,
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.group, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Assigned Members (${_selectedUsers.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: _selectedUsers.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.person_off, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No members assigned'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _selectedUsers.length,
                          itemBuilder: (_, index) {
                            final thisUser = _appContext.allUsers
                                .firstWhere((element) => element.id.compareTo(_selectedUsers[index]) == 0);
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: ListTile(
                                title: Text(thisUser.fullname),
                                subtitle: Text(thisUser.location),
                                leading: MyUserAvatar(thisUser),
                                trailing: IconButton(
                                  onPressed: () => _onRemoveUserFromRole(thisUser.id),
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  tooltip: 'Remove from assignment',
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onRemoveUserFromRole(final String uid) {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Remove From Role'),
            content: const Text('Are you sure you want to continue'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedUsers.removeWhere((element) => element.compareTo(uid) == 0);
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    });
                  },
                  child: const Text('Yes'))
            ],
          );
        });
  }

  void _onForGuestsChange(final bool newState) {
    setState(() {
      _forGuests = newState;
    });
  }

  void _onRequirementsChange(final String _) {
    if (_tecTitle.text.trim().isEmpty || _start == null || _end == null && _canSave) {
      setState(() {
        _canSave = false;
      });
    } else if (_tecTitle.text.trim().isNotEmpty && _start != null && _end != null && !_canSave) {
      setState(() {
        _canSave = true;
      });
    }
  }

  void _onStartTimeTap() {
    showTimePicker(
            context: context,
            initialTime: widget.eventContext.head.startTimeOfEvent,
            helpText: 'When does the role start?')
        .then((selectedStartTime) async {
      if (selectedStartTime != null) {
        setState(() {
          _start = DateTime(widget.eventContext.head.eventDate!.year, widget.eventContext.head.eventDate!.month,
              widget.eventContext.head.eventDate!.day, selectedStartTime.hour, selectedStartTime.minute);
        });
        _onEndTimeTap();
      }
    });
  }

  void _onEndTimeTap() {
    // select from a range of pre-set durations
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: 400,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Select Duration',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                    _buildDurationOption("5 minutes", 5, Icons.timer),
                    _buildDurationOption("10 minutes", 10, Icons.timer_10),
                    _buildDurationOption("15 minutes", 15, Icons.schedule),
                    _buildDurationOption("20 minutes", 20, Icons.schedule),
                    _buildDurationOption("25 minutes", 25, Icons.schedule),
                    _buildDurationOption("30 minutes", 30, Icons.schedule),
                    _buildDurationOption("45 minutes", 45, Icons.schedule),
                    _buildDurationOption("1 hour", 60, Icons.timer_outlined),
                    _buildDurationOption("1 hour 30 minutes", 90, Icons.timer_outlined),
                    _buildDurationOption("2 hours", 120, Icons.timer_outlined),
                    const Divider(),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(Icons.edit_calendar, color: Theme.of(context).colorScheme.onPrimaryContainer),
                      ),
                      title: const Text("Custom finish time"),
                      subtitle: const Text("Set a specific end time"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _selectCustomTimeForEndTime(),
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
      ),
    );
  }

  Widget _buildDurationOption(String title, int minutes, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(title),
        subtitle: Text("Ends at ${_timeFormat.format(_start!.add(Duration(minutes: minutes)))}"),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _setPresetDurationForEndTime(minutes),
      ),
    );
  }

  void _setPresetDurationForEndTime(final int minutes) {
    Navigator.of(context).pop();
    setState(() {
      _end = _start!.add(Duration(minutes: minutes));
    });
    _onRequirementsChange("");
  }

  void _selectCustomTimeForEndTime() {
    Navigator.of(context).pop();

    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start!.add(Duration(hours: 1))),
      helpText: 'When does the role finish?',
    ).then((selectedEndTime) {
      if (selectedEndTime != null && _isEndTimeValid(selectedEndTime)) {
        setState(() {
          _end = DateTime(widget.eventContext.head.eventDate!.year, widget.eventContext.head.eventDate!.month,
              widget.eventContext.head.eventDate!.day, selectedEndTime.hour, selectedEndTime.minute);
        });
        _onRequirementsChange("");
      }
    });
  }

  void _onSaveClick() {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Save Program Details'),
            content: const Text('Are you sure the details are correct?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(
                  onPressed: () {
                    _addProgramRoleToEventContext();
                    widget.eventContext.allowSavingOfTheEdit();
                    _isSaved = true;
                    Navigator.of(context).pop();
                    _popRouteAfterAllowing();
                  },
                  child: const Text('Save')),
            ],
          );
        });
  }

  bool _isEndTimeValid(final TimeOfDay end) {
    if (end.hour.compareTo(_start!.hour) > 0 ||
        (end.hour.compareTo(_start!.hour) == 0 && end.minute.compareTo(_start!.minute) > 0)) {
      return true;
    }
    DialogManager.showAlertDialog(
        context: context,
        title: 'Invalid Finish Time',
        content: 'Please set it after the Start Time which is currently at ${_timeFormat.format(_start!)}');
    return false;
  }

  void _addProgramRoleToEventContext() {
    final int id = DateTime.now().millisecondsSinceEpoch;
    debugPrint('sending the role addition to the following: $_selectedUsers');
    if (_selectedUsers.isNotEmpty) {
      widget.eventContext.addRoleAdditionNotification(_selectedUsers, id);
    }

    widget.eventContext.program.addRole(
        uids: _selectedUsers,
        title: _tecTitle.text.trim(),
        detail: _tecDetail.text.trim(),
        start: _start,
        end: _end,
        forGuests: _forGuests,
        priority: 1,
        id: id);
  }
}
