import 'package:avatar_stack/avatar_stack.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../widgets/user_avatar.dart';

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
        const Text('Assigned Members To Program'),
        ElevatedButton.icon(
            onPressed: _onSelectMembersTap, icon: const Icon(Icons.person_add), label: const Text('Assign Members')),
        const SizedBox(height: 16),
        InkWell(
            onTap: _selectedUsers.isNotEmpty ? _onViewAssignedMembersTap : null,
            child: AvatarStack(height: 50, avatars: _getSelectedUsersAvatar())),
        const SizedBox(height: 16),
        const Divider(thickness: 1),
        SwitchListTile(
            value: _forGuests,
            onChanged: _onForGuestsChange,
            title: const Text('For Guests'),
            subtitle: const Text('Is this something guests should see?')),
        ListTile(
            title: const Text('Priority: 1'),
            subtitle: const Text('Should this be viewed higher than others of the same start time?'),
            trailing: const Icon(Icons.edit),
            onTap: () {}),
        const SizedBox(height: 16),
        ElevatedButton.icon(
            onPressed: _canSave ? _onSaveClick : null, icon: const Icon(Icons.save), label: const Text('Update')),
      ],
    );
  }

  List<ImageProvider> _getSelectedUsersAvatar() {
    if (_selectedUsers.isEmpty) {
      return List.empty();
    }

    final List<ImageProvider> result = List<ImageProvider>.empty(growable: true);
    for (final uid in _selectedUsers) {
      final thisU = _appContext.allUsers.firstWhere((user) => user.id.compareTo(uid) == 0);
      if (thisU.imgSrc.isNotEmpty) {
        result.add(NetworkImage(thisU.imgSrc));
      } else {
        result.add(const AssetImage('assets/images/Generic-Profile.jpg'));
      }
    }

    return result;
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
    final availableUsers = _appContext.allUsers.where((element) => !_selectedUsers.contains(element.id)).toList();
    showDialog(
        context: context,
        builder: (_) {
          return Dialog(
            child: SizedBox(
              height: MediaQuery.of(_).size.height * 0.6,
              child: Column(
                children: [
                  const ListTile(
                    title: Text('Select User For Role'),
                    leading: Icon(Icons.people),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                        itemCount: availableUsers.length,
                        itemBuilder: (_, index) {
                          final thisUser = availableUsers[index];
                          return ListTile(
                            title: Text(thisUser.fullname),
                            subtitle: Text(thisUser.location),
                            leading: MyUserAvatar(thisUser),
                            onTap: () {
                              setState(() {
                                _selectedUsers.add(thisUser.id);
                                Navigator.of(context).pop();
                              });
                              _hasAnythingChanged();
                            },
                          );
                        }),
                  ),
                ],
              ),
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
    widget.programEntry['detail'] = _tecDetail.text.trim();
  }
}
