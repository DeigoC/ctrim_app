import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../pages/events/edit_event_date_location_page.dart';
import '../../pages/events/edit_program_role_page.dart';
import '../../utility/app_context.dart';
import '../../utility/event_context.dart';
import 'program_tile.dart';

class ViewAllPrograms extends StatefulWidget {
  const ViewAllPrograms(
      {super.key, required this.eventContext, required this.onProgramChanged, this.isAddingPost = false});
  final EventContext eventContext;
  final Function onProgramChanged;
  final bool isAddingPost;

  @override
  State<ViewAllPrograms> createState() => _ViewAllProgramsPageState();
}

class _ViewAllProgramsPageState extends State<ViewAllPrograms> {
  static final DateFormat _startFormat = DateFormat('EEEE d MMM yyyy');
  static final DateFormat _startFormatAllDay = DateFormat('EEEE d MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  late final AppContext _appContext;
  int? _selectedIndex;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget.eventContext.program.orderProgramsByStartTime();
    if (widget.eventContext.head.eventDate != null) {
      return _buildBodyWithEventDate();
    }
    return SingleChildScrollView(child: _buildEventDateSelector());
  }

  Widget _buildBodyWithEventDate() {
    final List<Map<String, dynamic>> programRoles = List<Map<String, dynamic>>.from(_appContext.isCurrentUserGuest
        ? widget.eventContext.program.roles.where((e) => e['for_guests'])
        : widget.eventContext.program.roles);

    final List<Widget> children = [
      Expanded(
          child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildEventDateSelector()),
        SliverList.separated(
          itemCount: programRoles.length,
          itemBuilder: (_, index) {
            final DateTime roleStart = programRoles[index]['start'];
            final bool canEdit = (widget.eventContext.isCurrentUserAuthor(_appContext.currentUser.id) ||
                    widget.eventContext.isCurrentUserContributor(_appContext.currentUser.id)) &&
                DateTime.now().isBefore(roleStart);

            return ProgramTile(
              programEntry: programRoles[index],
              onTap: (_) => _programTap(_, index),
              selected: _selectedIndex == index,
              assignedUsers:
                  (programRoles[index]["uids"] as List<String>).map((e) => _appContext.getUserFromID(e)).toList(),
              canEdit: _canEditPostProgram() ? true : canEdit,
              onEditClick: () => _openEditProgramPage(programRoles[index]),
            );
          },
          separatorBuilder: (BuildContext context, int index) => const Divider(),
        )
      ]))
    ];

    return SafeArea(top: false, child: Column(children: children));
  }

  Widget _buildEventDateSelector() {
    String dateStr = "No Date Selected";
    String timeStr = '';
    if (widget.eventContext.head.eventDate != null) {
      if (widget.eventContext.program.allDay) {
        dateStr = "${_startFormatAllDay.format(widget.eventContext.head.eventDate!)} (All Day)";
      } else {
        dateStr = _startFormat.format(widget.eventContext.head.eventDate!);
        timeStr =
            'From ${_timeFormat.format(widget.eventContext.head.eventDate!)} to ${_timeFormat.format(widget.eventContext.program.finishTime!)}';
      }
    }

    final List<Widget> children = [
      ListTile(
          title: Text(dateStr),
          subtitle: timeStr.isNotEmpty ? Text(timeStr) : null,
          leading: const Icon(Icons.calendar_month)),
      ListTile(
          title: Text(widget.eventContext.head.location),
          subtitle: Text(
            widget.eventContext.program.address,
            maxLines: null,
          ),
          trailing: _buildLocationTrailingIcon(),
          leading: const Icon(Icons.map)),
      const SizedBox(height: 8),
    ];

    if (widget.eventContext.head.eventDate != null &&
        DateTime.now().isBefore(widget.eventContext.head.eventDate!) &&
        !widget.isAddingPost) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: ElevatedButton.icon(
            onPressed: _onRemindEventClick, icon: const Icon(Icons.calendar_month), label: const Text('Remind me')),
      ));
    }

    children.add(const Divider(thickness: 1));

    return InkWell(
        onTap: _canEditPostProgram() ? _onEditPostProgram : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
  }

  bool _canEditPostProgram() {
    if (widget.isAddingPost) return true;
    return DateTime.now()
            .isBefore(widget.eventContext.head.eventDate ?? DateTime.now().subtract(const Duration(days: 1))) &&
        widget.eventContext.isCurrentUserAuthor(_appContext.currentUser.id);
  }

  void _programTap(final Map<String, dynamic> programEntry, final int index) {
    setState(() {
      if (_selectedIndex != index) {
        _selectedIndex = index;
      } else {
        _selectedIndex = null;
      }
    });
  }

  Widget _buildLocationTrailingIcon() {
    if (widget.eventContext.program.online) {
      return TextButton(onPressed: _onClickLocationTrailingIcon, child: const Text('Join'));
    }
    return TextButton(onPressed: _onClickLocationTrailingIcon, child: const Text('Maps'));
  }

  // * LOGIC
  void _openEditProgramPage(Map<String, dynamic> programEntry) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EditEventProgramPage(
                  eventContext: widget.eventContext,
                  programEntry: programEntry,
                ))).then((_) {
      setState(() {
        // rebuild in case of update
      });
      if (widget.eventContext.canSaveTheEditing) {
        widget.onProgramChanged();
      }
    });
  }

  void _onRemindEventClick() {
    // in theory, there should be an event date start and end (or all day)
    final IOSParams iosParams = IOSParams(
        reminder: const Duration(minutes: 30),
        url: widget.eventContext.program.online ? widget.eventContext.program.address : null);
    final String joinOnlineLink =
        widget.eventContext.program.online ? '\nJoin here:\n${widget.eventContext.program.address}\n' : '';
    final String description =
        '${widget.eventContext.head.subtitle}\n$joinOnlineLink\n******************************\nPlease keep track of the event via the CTRIM app for any updates. Thank you and see you there! 🙏 \n******************************';
    // remember about the online event url, we'll add it to the description another time.
    final Event event = Event(
      title: widget.eventContext.head.title,
      description: description,
      location: widget.eventContext.head.location,
      startDate: widget.eventContext.head.eventDate!,
      iosParams: iosParams,
      endDate:
          widget.eventContext.program.finishTime ?? widget.eventContext.head.eventDate!.add(const Duration(hours: 1)),
      allDay: widget.eventContext.program.allDay,
    );

    if (!kIsWeb) {
      Add2Calendar.addEvent2Cal(event).then((added) {
        if (added) {
          _appContext.analytics.logEvent(
              name: 'Reminder Added', parameters: {'PostID': widget.eventContext.id, 'DateTime': DateTime.now()});
        }
      });
    } else {
      DialogManager.showAlertDialog(
          context: context,
          title: 'Adding to Calendar',
          content:
              "Sorry, this feature only works on native mobile apps (iOS or Android), not on WebApps. Please look to install the app when it's available!");
    }
  }

  void _onClickLocationTrailingIcon() {
    final String link =
        widget.eventContext.program.online ? widget.eventContext.program.address : widget.eventContext.program.mapLink;
    launchUrlString(link, mode: LaunchMode.externalApplication).onError((error, stackTrace) async {
      debugPrint('error with link: $link');
      DialogManager.showAlertDialog(
          context: context,
          title: 'Error!',
          content: 'Attempted to open the following link:\n\n$link. \n\nError message: $error');
      return false; // ???
    }).then((success) {
      if (!success) {
        DialogManager.showAlertDialog(
            context: context, title: 'Error!', content: 'Attempted to open the following link:\n\n$link');
      }
    });
  }

  void _onEditPostProgram() {
    Navigator.push(
            context, MaterialPageRoute(builder: (_) => EditEventDateLocationPage(eventContext: widget.eventContext)))
        .then((_) {
      widget.eventContext.program.orderProgramsByStartTime();
      setState(() {});
      if (widget.eventContext.canSaveTheEditing) {
        widget.onProgramChanged();
      }
    });
  }
}
