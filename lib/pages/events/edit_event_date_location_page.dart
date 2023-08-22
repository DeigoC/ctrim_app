import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';

class EditEventDateLocationPage extends StatefulWidget {
  const EditEventDateLocationPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditEventDateLocationPage> createState() => _EditEventDateLocationPageState();
}

class _EditEventDateLocationPageState extends State<EditEventDateLocationPage> {
  static final DateFormat _startFormat = DateFormat('EEEE d MMM yyyy, HH:mm');
  static final DateFormat _endFormat = DateFormat('HH:mm');
  // static final List<String> _locations = ['Belfast'];
  late final DateTime? _originalStart, _originalEnd;
  late final bool _originalAllDay, _originalOnline;
  late final String _originalAddress, _originalLocation, _originalMapLink;

  late TextEditingController _tecAddress, _tecMapLink;
  String _location = 'Belfast';
  String _webLink = '';
  DateTime? _start, _end;
  bool _isAllDay = false, _online = false;

  @override
  void initState() {
    _originalStart = widget.eventContext.head.eventDate;
    _originalEnd = widget.eventContext.program.finishTime;
    _originalAllDay = widget.eventContext.program.allDay;
    _originalAddress = widget.eventContext.program.address;
    _originalOnline = widget.eventContext.program.online;
    _originalLocation = widget.eventContext.head.location.replaceAll(' (Online)', '');
    _originalMapLink = widget.eventContext.program.mapLink;

    _location = widget.eventContext.head.location.replaceAll(' (Online)', '');
    _tecAddress = TextEditingController(text: _originalAddress);
    _tecMapLink = TextEditingController(text: _originalMapLink);
    _online = widget.eventContext.program.online;

    if (_online) {
      _webLink = _originalAddress;
    }

    _start = _originalStart;
    _end = _originalEnd;
    _isAllDay = _originalAllDay;

    super.initState();
  }

  @override
  void dispose() {
    _tecAddress.dispose();
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
    final List<Widget> children = [
      ListTile(
        title: Text(_startFormat.format(_start!)),
        subtitle: const Text('Event Date and Time'),
        leading: const Icon(Icons.calendar_today),
        trailing: IconButton(onPressed: _onDeleteStartTimeClick, icon: const Icon(Icons.delete)),
        onTap: _onSelectStartDateClick,
      ),
      ListTile(
        title: Text(_end == null ? 'TBD' : _endFormat.format(_end!)),
        subtitle: const Text('Finish Time'),
        onTap: _onSelectEndTimeClick,
      ),
      const Divider(thickness: 1),
      const SizedBox(height: 8),
      SwitchListTile(value: _isAllDay, onChanged: _onAllDaySwitchTap, title: const Text('All Day')),
      const SizedBox(height: 8),
      const Divider(thickness: 1),
      const SizedBox(height: 8),
      ListTile(
        title: Text(_location),
        subtitle: const Text('Location (fixed for now!)'),
        leading: const Icon(Icons.map),
        onTap: _onSelectLocationClick,
        trailing: const Icon(Icons.edit),
      ),
      SwitchListTile(value: _online, onChanged: _onOnlineSwitchTap, title: const Text('Online')),
      const SizedBox(height: 8),
      const Divider(thickness: 1),
      const SizedBox(height: 8),
      TextField(
        controller: _tecAddress,
        maxLines: null,
        decoration: InputDecoration(
            hintText: _online ? 'https://...' : '8A Princes Dr, Newtownabbey, BT37 0AZ, Northern Ireland',
            label: _online ? const Text('Online Meeting Link') : const Text('Address'),
            suffixIcon:
                _online ? IconButton(onPressed: _onOnlineMeetingLinkHelpClick, icon: const Icon(Icons.help)) : null),
      ),
    ];

    if (!_online) {
      children.add(TextField(
        controller: _tecMapLink,
        maxLines: null,
        decoration: InputDecoration(
            hintText: 'https://...',
            label: const Text('Map Link'),
            suffixIcon: IconButton(onPressed: _mapLinkHelpClick, icon: const Icon(Icons.help))),
      ));
    }

    return children;
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
            barrierDismissible: false,
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
      _online = newState;
      if (newState) {
        _tecAddress = TextEditingController(text: _webLink);
      } else {
        _webLink = _tecAddress.text.trim();
        if (_location == 'Belfast') {
          _tecAddress = TextEditingController(text: '8A Princes Dr, Newtownabbey, BT37 0AZ, Northern Ireland');
        }
      }
    });
  }

  void _onSelectLocationClick() {
    // showDialog(
    //     context: context,
    //     builder: (_) => Dialog(
    //           child: SizedBox(
    //             height: MediaQuery.of(context).size.height * 0.6,
    //             child: ListView.builder(
    //                 itemCount: _locations.length,
    //                 itemBuilder: (_, index) => ListTile(
    //                       title: Text(_locations[index]),
    //                       onTap: () {
    //                         setState(() {
    //                           _location = _locations[index];
    //                         });
    //                       },
    //                     )),
    //           ),
    //         ));
  }

  void _onDeleteStartTimeClick() {
    setState(() {
      _start = null;
    });
  }

  void _checkToUpdate() {
    if (_start != _originalStart ||
        _end != _originalEnd ||
        _isAllDay != _originalAllDay ||
        _tecAddress.text.trim().toLowerCase().compareTo(_originalAddress.toLowerCase()) != 0 ||
        widget.eventContext.program.online != _originalOnline ||
        widget.eventContext.head.location.compareTo(_originalLocation) != 0) {
      widget.eventContext.program.setFinishTime(_end ?? _start!.add(const Duration(hours: 4)));
      widget.eventContext.program.setAllDay(_isAllDay);
      widget.eventContext.program.setAddress(_tecAddress.text.trim());
      widget.eventContext.program.setOnline(_online);

      final String newLocation = _location + (_online ? ' (Online)' : '');
      widget.eventContext.head.setLocation(newLocation);
      widget.eventContext.head.setEventDate(_start);

      widget.eventContext.allowSavingOfTheEdit();
    }
  }

  void _mapLinkHelpClick() {
    DialogManager.showAlertDialog(
        context: context,
        title: 'Map Link',
        content:
            'Link to open the maps app (google maps seems to be a solid pick) for the address. \n\nTo get the link from google maps, enter the address of the location then create a share link. Paste that link here.');
  }

  void _onOnlineMeetingLinkHelpClick() {
    DialogManager.showAlertDialog(
        context: context, title: 'Online Link', content: 'Insert the meeting link here, typically for Zoom meetings!');
  }
}
