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
    return WillPopScope(
      onWillPop: _isSaved ? () async => true : () => DialogManager.discardChanges(context: context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Program'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        ListTile(
            title: Text(_timeFormat.format(_start)),
            subtitle: const Text('Start Time'),
            leading: const Icon(Icons.punch_clock),
            onTap: _onStartTimeTap),
        ListTile(
            title: Text(_timeFormat.format(_end)),
            subtitle: const Text('Finish Time'),
            leading: const Icon(Icons.punch_clock),
            onTap: _onEndTimeTap),
        TextField(
            controller: _tecTitle,
            maxLength: 48,
            decoration: const InputDecoration(
              label: Text('Title*'),
              hintText: 'What is this?',
            ),
            onChanged: (_) => _hasAnythingChanged()),
        TextField(
            controller: _tecDetail,
            maxLines: null,
            maxLength: 128,
            decoration: const InputDecoration(label: Text('Detail'), hintText: 'Go into more detail'),
            onChanged: (_) => _hasAnythingChanged()),
        const Divider(thickness: 1),
        const SizedBox(height: 16),
        const Text('Assigned To The Program', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        InkWell(
            onTap: _selectedUsers.isNotEmpty ? _onViewAssignedMembersTap : null,
            child: MyAvatarStack(
              users: _appContext.allUsers.where((e) => _selectedUsers.contains(e.id)).toList(),
              appDir: _appContext.appDir,
            )),
        TextButton.icon(
            onPressed: _onSelectMembersTap, icon: const Icon(Icons.person_add), label: const Text('Assign Members')),
        const Divider(thickness: 1),
        SwitchListTile(
            value: _forGuests,
            onChanged: _onForGuestsChange,
            title: const Text('For Guests'),
            subtitle: const Text('Is this something guests should see?')),
        const SizedBox(height: 16),
        ElevatedButton.icon(
            onPressed: _canSave ? _onSaveClick : null, icon: const Icon(Icons.save), label: const Text('Update')),
        const SizedBox(height: 8),
        ElevatedButton.icon(
            onPressed: _onDeleteTap,
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Delete', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red)),
        const SizedBox(height: 32)
      ],
    );
  }

  // * Logic
  void _onForGuestsChange(bool newState) {
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
        await DialogManager.showAlertDialog(
            context: context,
            title: 'Finish Time',
            content: 'Now please select when this program is expected to complete',
            barrierDismissible: false);
        _hasAnythingChanged();
        _onEndTimeTap();
      }
    });
  }

  void _onEndTimeTap() {
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

  bool _isEndTimeValid(TimeOfDay end) {
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
            child: SizedBox(
              height: MediaQuery.of(_).size.height * 0.5,
              child: ListView.builder(
                  itemCount: _selectedUsers.length,
                  itemBuilder: (_, index) {
                    final thisUser =
                        _appContext.allUsers.firstWhere((element) => element.id.compareTo(_selectedUsers[index]) == 0);
                    return ListTile(
                      title: Text(thisUser.fullname),
                      subtitle: Text(thisUser.location),
                      leading: MyUserAvatar(thisUser),
                      trailing: IconButton(
                          onPressed: () => _onRemoveUserFromRole(thisUser.id), icon: const Icon(Icons.remove_circle)),
                    );
                  }),
            ),
          );
        });
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

  void _onRemoveUserFromRole(String uid) {
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
