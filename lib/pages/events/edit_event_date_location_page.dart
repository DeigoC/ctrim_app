import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utility/event_context.dart';
import '../../utility/responsive_layout.dart';

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
    return PopScope(
      onPopInvokedWithResult: (didPop, result) => _checkToUpdate(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('Edit Date & Location'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final double webHorizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 16);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: webHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _start == null ? _buildJustDateSelector() : _buildEverything(),
      ),
    );
  }

  List<Widget> _buildJustDateSelector() {
    return [
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_available,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Set Event Date',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose when your event will take place',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _onSelectStartDateClick,
                icon: const Icon(Icons.calendar_today),
                label: const Text('Select Date & Time'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildEverything() {
    final List<Widget> children = [
      // Date & Time Section
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Date & Time',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Start Date/Time
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    _startFormat.format(_start!),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  subtitle: Text(
                    'Event starts',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                  leading: Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _onSelectStartDateClick,
                        icon: Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Edit start time',
                      ),
                      IconButton(
                        onPressed: _onDeleteStartTimeClick,
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        tooltip: 'Remove date',
                      ),
                    ],
                  ),
                  onTap: _onSelectStartDateClick,
                ),
              ),
              const SizedBox(height: 8),
              // End Time
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    _end == null ? 'Not set' : _endFormat.format(_end!),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: _end == null ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5) : null,
                        ),
                  ),
                  subtitle: Text(
                    'Event ends',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                  leading: Icon(
                    Icons.stop,
                    color: _end == null
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                        : Theme.of(context).colorScheme.secondary,
                  ),
                  trailing: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: _onSelectEndTimeClick,
                ),
              ),
              const SizedBox(height: 16),
              // All Day Switch
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.today,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All Day Event',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    Switch(
                      value: _isAllDay,
                      onChanged: _onAllDaySwitchTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      // Location Section
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Location Selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    _location,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  subtitle: Text(
                    'Event location (currently fixed)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                  leading: Icon(
                    Icons.place,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  trailing: Icon(
                    Icons.lock,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  onTap: _onSelectLocationClick,
                ),
              ),
              const SizedBox(height: 16),
              // Online Switch
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.videocam,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Online Event',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          Text(
                            'Event will be held online',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _online,
                      onChanged: _onOnlineSwitchTap,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Address/Link Field
              TextFormField(
                controller: _tecAddress,
                maxLines: null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  hintText:
                      _online ? 'https://zoom.us/j/...' : '8A Princes Dr, Newtownabbey, BT37 0AZ, Northern Ireland',
                  labelText: _online ? 'Online Meeting Link' : 'Physical Address',
                  prefixIcon: Icon(
                    _online ? Icons.link : Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  suffixIcon: IconButton(
                    onPressed: _online ? _onOnlineMeetingLinkHelpClick : null,
                    icon: Icon(
                      Icons.help_outline,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    tooltip: 'Help',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    if (!_online) {
      children.add(
        const SizedBox(height: 16),
      );
      children.add(
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.map,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Map Link',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Provide a link to help attendees find the location',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tecMapLink,
                  maxLines: null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    hintText: 'https://maps.google.com/...',
                    labelText: 'Google Maps Link (Optional)',
                    prefixIcon: Icon(
                      Icons.map_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    suffixIcon: IconButton(
                      onPressed: _mapLinkHelpClick,
                      icon: Icon(
                        Icons.help_outline,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      tooltip: 'How to get map link',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    children.add(const SizedBox(height: 24));
    return children;
  }

  // * Logic

  void _onSelectStartDateClick() {
    showDatePicker(
            context: context,
            initialDate: _start == null ? DateTime.now().add(const Duration(days: 1)) : _start!,
            firstDate: DateTime.now().subtract(const Duration(days: 30)),
            lastDate: DateTime.now().add(const Duration(days: 122)))
        .then((selectedStartDate) {
      if (selectedStartDate != null) {
        _onSelectStartTime(selectedStartDate);
      }
    });
  }

  Future<void> _onSelectStartTime(final DateTime selectedStartDate) async {
    final selectedTOD = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedStartDate
            .add(Duration(hours: _start == null ? 9 : _start!.hour, minutes: _start == null ? 0 : _start!.minute))));
    if (selectedTOD == null || !mounted) return;
    setState(() {
      _start = DateTime(selectedStartDate.year, selectedStartDate.month, selectedStartDate.day, selectedTOD.hour,
          selectedTOD.minute);
    });
    if (!mounted) return;
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.schedule,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Event Duration'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How long will your event last?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Choose whether this is an all-day event or has a specific end time.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _isAllDay = true;
                          });
                        },
                        icon: const Icon(Icons.today),
                        label: const Text('All Day'),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _onSelectEndTimeClick();
                        },
                        icon: const Icon(Icons.schedule),
                        label: const Text('Set End Time'),
                      ),
                    ]));
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
        widget.eventContext.head.location.compareTo(_originalLocation) != 0 ||
        _originalMapLink.compareTo(_tecMapLink.text.trim()) != 0) {
      widget.eventContext.program.setFinishTime(_end ?? _start!.add(const Duration(hours: 4)));
      widget.eventContext.program.setAllDay(_isAllDay);
      widget.eventContext.program.setAddress(_tecAddress.text.trim());
      widget.eventContext.program.setOnline(_online);
      widget.eventContext.program.setMapLink(_tecMapLink.text.trim());

      final String newLocation = _location + (_online ? ' (Online)' : '');
      widget.eventContext.head.setLocation(newLocation);
      widget.eventContext.head.setEventDate(_start);

      widget.eventContext.allowSavingOfTheEdit();
    }
  }

  void _mapLinkHelpClick() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.map,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Map Link Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help attendees find your event location with a direct map link.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How to get a Google Maps link:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Go to Google Maps\n2. Search for your event address\n3. Click the "Share" button\n4. Copy the link and paste it here',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _onOnlineMeetingLinkHelpClick() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.videocam,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Online Meeting Link'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provide the link where attendees can join your online event.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.video_call,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Examples:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Zoom meeting links\n• Microsoft Teams links\n• Google Meet links\n• YouTube live streams',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
