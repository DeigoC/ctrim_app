import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../widgets/my_avatar_stack.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_selector_dialog.dart';

class EditEventProgramPage extends StatefulWidget {
  const EditEventProgramPage({super.key, required this.eventContext, required this.programEntry});
  final EventContext eventContext;
  final Map<String, dynamic> programEntry;

  @override
  State<EditEventProgramPage> createState() => _EditEventProgramPageState();
}

class _EditEventProgramPageState extends State<EditEventProgramPage> {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  late final TextEditingController _tecDetail, _tecTitle;
  late final AppContext _appContext;
  late final List<String> _selectedUsers;

  late DateTime _start, _end;
  bool _canSave = false, _forGuests = true, _isSaved = false;

  @override
  void initState() {
    _forGuests = widget.programEntry['for_guests'];
    _start = widget.programEntry['start'];
    _end = widget.programEntry['end'];
    _tecDetail = TextEditingController(text: widget.programEntry['detail']);
    _tecTitle = TextEditingController(text: widget.programEntry['title']);
    _selectedUsers = List<String>.from(widget.programEntry['uids']);
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
      canPop: false,
      onPopInvoked: (_) => _isSaved
          ? null
          : DialogManager.discardChanges(context: context)
              .then((popping) => popping ? Navigator.of(context).pop() : null),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Program'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 16;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: webHorizontalPadding),
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
                          onTap: _onStartTimeTap,
                          icon: Icons.play_arrow,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeSelector(
                          label: 'End Time',
                          time: _end,
                          onTap: _onEndTimeTap,
                          icon: Icons.stop,
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
                    decoration: const InputDecoration(
                      label: Text('Title*'),
                      hintText: 'What is this program about?',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    onChanged: (_) => _hasAnythingChanged(),
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
                    onChanged: (_) => _hasAnythingChanged(),
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
                                  size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                              const SizedBox(height: 8),
                              Text(
                                'No team members assigned',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
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

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _canSave ? _onSaveClick : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Update'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _onDeleteTap,
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Delete Program', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: Colors.red),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required DateTime time,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _timeFormat.format(time),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // * Logic
  void _onForGuestsChange(final bool newState) {
    setState(() {
      _forGuests = newState;
    });
    _hasAnythingChanged();
  }

  void _hasAnythingChanged() {
    if (_canSave &&
        (_areTimesTheSame() &&
            _tecDetail.text.trim().compareTo(widget.programEntry['detail']) == 0 &&
            (_tecTitle.text.trim().compareTo(widget.programEntry['title']) == 0 || _tecTitle.text.trim().isEmpty)) &&
        _forGuests == widget.programEntry['for_guests'] &&
        _selectedUsers.toString().compareTo((widget.programEntry['uids'] as List<String>).toString()) == 0) {
      setState(() {
        _canSave = false;
      });
    } else if (!_canSave) {
      setState(() {
        _canSave = true;
      });
    }
  }

  bool _areTimesTheSame() {
    return (_start.hour.compareTo((widget.programEntry['start'] as DateTime).hour) == 0 &&
        _start.minute.compareTo((widget.programEntry['start'] as DateTime).minute) == 0 &&
        _end.hour.compareTo((widget.programEntry['end'] as DateTime).hour) == 0 &&
        _end.minute.compareTo((widget.programEntry['end'] as DateTime).minute) == 0);
  }

  void _onStartTimeTap() {
    showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start), helpText: 'When does the role start?')
        .then((selectedStartTime) async {
      if (selectedStartTime != null) {
        setState(() {
          _start = DateTime(widget.eventContext.head.eventDate!.year, widget.eventContext.head.eventDate!.month,
              widget.eventContext.head.eventDate!.day, selectedStartTime.hour, selectedStartTime.minute);
        });
        _hasAnythingChanged();
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
        subtitle: Text("Ends at ${_timeFormat.format(_start.add(Duration(minutes: minutes)))}"),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _setPresetDurationForEndTime(minutes),
      ),
    );
  }

  void _selectCustomTimeForEndTime() {
    Navigator.of(context).pop();

    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
      helpText: 'When does the role finish?',
    ).then((selectedEndTime) {
      if (selectedEndTime != null && _isEndTimeValid(selectedEndTime)) {
        setState(() {
          _end = DateTime(widget.eventContext.head.eventDate!.year, widget.eventContext.head.eventDate!.month,
              widget.eventContext.head.eventDate!.day, selectedEndTime.hour, selectedEndTime.minute);
        });
        _hasAnythingChanged();
      }
    });
  }

  void _setPresetDurationForEndTime(final int minutes) {
    Navigator.of(context).pop();
    setState(() {
      _end = _start.add(Duration(minutes: minutes));
    });
    _hasAnythingChanged();
  }

  bool _isEndTimeValid(final TimeOfDay end) {
    if (end.hour.compareTo(_start.hour) > 0 ||
        (end.hour.compareTo(_start.hour) == 0 && end.minute.compareTo(_start.minute) > 0)) {
      return true;
    }
    DialogManager.showAlertDialog(
        context: context,
        title: 'Invalid Finish Time',
        content: 'Please set it after the Start Time which is currently at ${_timeFormat.format(_start)}');
    return false;
  }

  void _onViewAssignedMembersTap() {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(_).size.height * 0.6,
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

  void _onSelectMembersTap() {
    showDialog(
        context: context,
        builder: (_) => UserSelectorDialog(
            alreadySelectedUIDs: _selectedUsers,
            includeCurrentUser: true,
            allowTaskCheck: true,
            onSelected: (newID) => setState(() {
                  _selectedUsers.add(newID);
                  _hasAnythingChanged();
                })));
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
                      widget.eventContext.addRoleDeletionTitle(widget.programEntry['id'], widget.programEntry['title']);
                      _hasAnythingChanged();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    });
                  },
                  child: const Text('Yes'))
            ],
          );
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
                    _saveAllChanges();
                    widget.eventContext.allowSavingOfTheEdit();
                    _isSaved = true;
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save')),
            ],
          );
        });
  }

  void _saveAllChanges() {
    _sortNotifications();
    widget.programEntry['uids'] = _selectedUsers;
    widget.programEntry['detail'] = _tecDetail.text.trim();
    widget.programEntry['title'] = _tecTitle.text.trim();
    widget.programEntry['start'] = _start;
    widget.programEntry['end'] = _end;
    widget.programEntry['for_guests'] = _forGuests;
    widget.programEntry['priority'] = 1; // ! remember to change this!
  }

  void _sortNotifications() {
    final List<String> originalList = List<String>.from(widget.programEntry['uids']);

    // figure out the removed members
    final removedMembers = originalList.where((e) => !_selectedUsers.contains(e));
    debugPrint('Sending role removal to the following: $removedMembers');
    if (removedMembers.isNotEmpty) {
      widget.eventContext.addRoleRemovalNotification(removedMembers, widget.programEntry['id']);
    }

    // figure out the new members
    final newMembers = _selectedUsers.where((e) => !originalList.contains(e));
    debugPrint('Sending role addition to the following: $newMembers');
    if (newMembers.isNotEmpty) {
      widget.eventContext.addRoleAdditionNotification(newMembers, widget.programEntry['id']);
    }
    debugPrint('--------role addition now looks like: ${widget.eventContext.roleAdditions}');
  }

  void _onDeleteTap() {
    // remember to send all from the original about the removal of role
    DialogManager.showConfirmationDialog(
            context: context, title: 'Delete Schedule Item', content: 'Are you sure you want to delete this item?')
        .then((confirmation) {
      if (confirmation) {
        widget.eventContext.removeRoleAdditionNotification(widget.programEntry['id']);
        widget.eventContext.addRoleRemovalNotification(widget.programEntry['uids'], widget.programEntry['id']);
        widget.eventContext.addRoleDeletionTitle(widget.programEntry['id'], widget.programEntry['title']);

        widget.eventContext.program.removeRole(widget.programEntry['id']);
        widget.eventContext.allowSavingOfTheEdit();

        _isSaved = true;
        Navigator.of(context).pop();
      }
    });
  }
}
