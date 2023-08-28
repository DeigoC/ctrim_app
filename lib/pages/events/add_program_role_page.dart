import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../widgets/my_avatar_stack.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_selector_dialog.dart';

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
  bool _canSave = false, _forGuests = true, _isSaved = false;

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
    return WillPopScope(
      onWillPop: _isSaved ? () async => true : () => DialogManager.discardChanges(context: context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Program'),
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
          title: Text(_start == null ? 'TBD' : _timeFormat.format(_start!)),
          subtitle: const Text('Start Time*'),
          leading: const Icon(Icons.punch_clock),
          trailing: _start == null ? const Icon(Icons.warning_amber, color: Colors.amber) : const Icon(Icons.edit),
          onTap: _onStartTimeTap,
        ),
        ListTile(
          title: Text(_end == null ? 'TBD' : _timeFormat.format(_end!)),
          subtitle: const Text('Finish Time*'),
          leading: const Icon(Icons.punch_clock),
          trailing: _end == null ? const Icon(Icons.warning_amber, color: Colors.amber) : const Icon(Icons.edit),
          onTap: _start == null ? null : _onEndTimeTap,
        ),
        TextField(
          controller: _tecTitle,
          maxLength: 48,
          decoration: InputDecoration(
              label: const Text('Title*'),
              hintText: 'What is this?',
              suffixIcon: _tecTitle.text.trim().isEmpty ? const Icon(Icons.warning_amber, color: Colors.amber) : null),
          onChanged: _onRequirementsChange,
        ),
        TextField(
          controller: _tecDetail,
          maxLines: null,
          maxLength: 128,
          decoration: const InputDecoration(label: Text('Detail'), hintText: 'Go into more detail'),
        ),
        const Divider(thickness: 1),
        const SizedBox(height: 16),
        const Text('Assigned To The Program', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        InkWell(
            onTap: _selectedUsers.isNotEmpty ? _onViewAssignedMembersTap : null,
            child: MyAvatarStack(
                users: _appContext.allUsers.where((e) => _selectedUsers.contains(e.id)).toList(),
                appDir: _appContext.appDir)),
        TextButton.icon(
            onPressed: _onSelectMembersTap, icon: const Icon(Icons.person_add), label: const Text('Assign Members')),
        const Divider(thickness: 1),
        SwitchListTile(
          value: _forGuests,
          onChanged: _onForGuestsChange,
          title: const Text('For Guests'),
          subtitle: const Text('Is this something guests should see?'),
        ),
        // ListTile(
        //   title: const Text('Priority: 1'),
        //   subtitle: const Text('Should this be viewed higher than others of the same start time?'),
        //   trailing: const Icon(Icons.edit),
        //   onTap: () {},
        // ),
        const SizedBox(height: 16),
        const Divider(),
        ElevatedButton.icon(
            onPressed: _canSave ? _onSaveClick : null, icon: const Icon(Icons.save), label: const Text('Save')),
        const SizedBox(height: 32),
      ],
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
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    });
                  },
                  child: const Text('Yes'))
            ],
          );
        });
  }

  void _onForGuestsChange(bool newState) {
    setState(() {
      _forGuests = newState;
    });
  }

  void _onRequirementsChange(String _) {
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
        await DialogManager.showAlertDialog(
            context: context,
            title: 'Finish Time',
            content: 'Now please select when this program is expected to complete',
            barrierDismissible: false);
        _onEndTimeTap();
      }
    });
  }

  void _onEndTimeTap() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start!.add(const Duration(hours: 1))),
      helpText: 'When does the role finish?',
    ).then((selectedEndTime) {
      if (selectedEndTime != null && _isEndTimeValid(selectedEndTime)) {
        setState(() {
          _end = DateTime(widget.eventContext.head.eventDate!.year, widget.eventContext.head.eventDate!.month,
              widget.eventContext.head.eventDate!.day, selectedEndTime.hour, selectedEndTime.minute);
        });
        _onRequirementsChange('');
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
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save')),
            ],
          );
        });
  }

  bool _isEndTimeValid(TimeOfDay end) {
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
