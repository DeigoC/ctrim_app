import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditEventDateLocationPage extends StatefulWidget {
  const EditEventDateLocationPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditEventDateLocationPage> createState() => _EditEventDateLocationPageState();
}

class _EditEventDateLocationPageState extends State<EditEventDateLocationPage> {
  static final DateFormat _startFormat = DateFormat('EEEE d MMM yyyy, HH:mm');
  static final DateFormat _endFormat = DateFormat('HH:mm');
  late final DateTime? _originalStart, _originalEnd;
  late final bool _originalAllDay;

  DateTime? _start, _end;
  bool _isAllDay = false, _online = false;

  @override
  void initState() {
    _originalStart = widget.eventContext.head.eventDate;
    _originalEnd = widget.eventContext.program.finishTime;
    _originalAllDay = widget.eventContext.program.allDay;

    _start = _originalStart;
    _end = _originalEnd;
    _isAllDay = _originalAllDay;

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _checkToUpdate();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Date & Location')),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: _start == null ? _buildJustDateSelector() : _buildEverything(),
    );
  }

  List<Widget> _buildJustDateSelector() {
    return [
      ListTile(
        title: const Text('TBD'),
        subtitle: const Text('Event Date and Time'),
        onTap: _onSelectStartDateClick,
      ),
    ];
  }

  List<Widget> _buildEverything() {
    return [
      ListTile(
        title: Text(_startFormat.format(_start!)),
        subtitle: const Text('Event Date and Time'),
        trailing: IconButton(onPressed: _onDeleteStartTimeClick, icon: const Icon(Icons.delete)),
        onTap: _onSelectStartDateClick,
      ),
      ListTile(
        title: Text(_end == null ? 'TBD' : _endFormat.format(_end!)),
        subtitle: const Text('Finish Time'),
        onTap: _onSelectEndTimeClick,
      ),
      SwitchListTile(value: _isAllDay, onChanged: _onAllDaySwitchTap, title: const Text('All Day')),
      const Divider(),
      const ListTile(
        title: Text('Belfast'),
        subtitle: Text('Location'),
        leading: Icon(Icons.map),
      ),
      SwitchListTile(value: _online, onChanged: _onOnlineSwitchTap, title: const Text('Online')),
    ];
  }

  // * Logic

  void _onSelectStartDateClick() {
    showDatePicker(
            context: context,
            initialDate: _start == null ? DateTime.now().add(const Duration(days: 1)) : _start!,
            firstDate: DateTime.now().add(const Duration(days: 1)),
            lastDate: DateTime.now().add(const Duration(days: 122)))
        .then((selectedStartDate) {
      if (selectedStartDate != null) {
        _onSelectStartTime(selectedStartDate);
      }
    });
  }

  void _onSelectStartTime(DateTime selectedStartDate) {
    showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(selectedStartDate
                .add(Duration(hours: _start == null ? 9 : _start!.hour, minutes: _start == null ? 0 : _start!.minute))))
        .then((selectedTOD) {
      if (selectedTOD != null) {
        setState(() {
          _start = DateTime(selectedStartDate.year, selectedStartDate.month, selectedStartDate.day, selectedTOD.hour,
              selectedTOD.minute);
        });
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                    title: const Text('Finish Time'),
                    content: const Text('Does the event last all day or finishes at a time?'),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _isAllDay = true;
                            });
                          },
                          child: const Text('All Day')),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _onSelectEndTimeClick();
                          },
                          child: const Text('On a Time'))
                    ]));
      }
    });
  }

  void _onSelectEndTimeClick() {
    showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_end ?? _start!.add(const Duration(hours: 4))))
        .then((selectedTOD) {
      if (selectedTOD != null) {
        setState(() {
          _end = DateTime(_start!.year, _start!.month, _start!.day, selectedTOD.hour, selectedTOD.minute);
        });
      }
    });
  }

  void _onAllDaySwitchTap(bool newState) {
    setState(() {
      _isAllDay = !_isAllDay;
    });
  }

  void _onOnlineSwitchTap(bool newState) {
    setState(() {
      _online = !_online;
    });
  }

  void _onDeleteStartTimeClick() {
    setState(() {
      _start = null;
    });
  }

  void _checkToUpdate() {
    if (_start != _originalStart || _end != _originalEnd || _isAllDay != _originalAllDay) {
      widget.eventContext.head.setEventDate(_start);
      widget.eventContext.program.setFinishTime(_end);
      widget.eventContext.program.setAllDay(_isAllDay);
      widget.eventContext.allowSavingOfTheEdit();
    }
  }
}
