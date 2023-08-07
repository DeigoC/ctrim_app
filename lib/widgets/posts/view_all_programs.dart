import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../pages/events/add_program_role_page.dart';
import '../../pages/events/edit_event_date_location_page.dart';
import '../../pages/events/edit_program_page.dart';
import '../../utility/app_context.dart';
import '../../utility/event_context.dart';
import '../user_avatar.dart';
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
  static final DateFormat _startFormat = DateFormat('EEEE d MMM yyyy, HH:mm');
  static final DateFormat _startFormatAllDay = DateFormat('EEEE d MMM yyyy');
  static final DateFormat _endFormat = DateFormat('HH:mm');
  late final AppContext _appContext;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget.eventContext.program.orderProgramsByStartDate();
    if (widget.eventContext.head.eventDate != null) {
      return _buildBodyWithEventDate();
    }
    return SingleChildScrollView(child: _buildEventDateSelector());
  }

  Widget _buildBodyWithEventDate() {
    final List<Widget> children = [
      Expanded(
          child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildEventDateSelector()),
        SliverList.separated(
          itemCount: widget.eventContext.allPrograms.length,
          itemBuilder: (_, index) {
            return ProgramTile(
              programEntry: widget.eventContext.allPrograms[index],
              onTap: (_) => _showProgramDialog(_),
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider();
          },
        )
      ]))
    ];

    if (widget.eventContext.isCurrentUserAuthor(_appContext.currentUser.id) ||
        widget.eventContext.isCurrentUserContributor(_appContext.currentUser.id)) {
      children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: _openAddProgramPage,
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Add Program')))));
    }

    return SafeArea(top: false, child: Column(children: children));
  }

  Widget _buildEventDateSelector() {
    String dateStr = "No Date Selected";
    if (widget.eventContext.head.eventDate != null) {
      if (widget.eventContext.program.allDay) {
        dateStr = "${_startFormatAllDay.format(widget.eventContext.head.eventDate!)} (All Day)";
      } else {
        dateStr =
            "${_startFormat.format(widget.eventContext.head.eventDate!)} to ${_endFormat.format(widget.eventContext.program.finishTime!)}";
      }
    }

    final List<Widget> children = [
      ListTile(title: Text(dateStr), leading: const Icon(Icons.calendar_today)),
      const ListTile(title: Text('Belfast'), leading: Icon(Icons.map)),
    ];

    if (widget.eventContext.head.eventDate != null &&
        DateTime.now().compareTo(widget.eventContext.head.eventDate!) < 0 &&
        !widget.isAddingPost) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: ElevatedButton.icon(
            onPressed: _onRemindEventClick, icon: const Icon(Icons.calendar_month), label: const Text('Remind me')),
      ));
    }

    children.add(const Divider(thickness: 1));

    return InkWell(
        onTap: widget.eventContext.isCurrentUserAuthor(_appContext.currentUser.id) ? _onEditPostProgram : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
  }

  void _showProgramDialog(final Map<String, dynamic> programEntry) {
    final List<User> assignedUsers =
        _appContext.allUsers.where((e) => (programEntry["uids"] as List).contains(e.id)).toList();

    final List<Widget> children = [
      const SizedBox(height: 16),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(programEntry['title'], style: const TextStyle(fontSize: 21))),
      const SizedBox(height: 8),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('${_endFormat.format(programEntry['start'])} - ${_endFormat.format(programEntry['end'])}',
              textAlign: TextAlign.start))
    ];

    if ((programEntry['detail'] as String).isNotEmpty) {
      children.addAll([
        const SizedBox(height: 16),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(programEntry['detail'], style: const TextStyle(fontSize: 16), textAlign: TextAlign.start))
      ]);
    }

    if (!programEntry['for_guests']) {
      children
          .add(const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('(Do not show for Guests)')));
    }

    if (assignedUsers.isNotEmpty) {
      children.addAll([const Divider()]);

      for (final user in assignedUsers) {
        children.add(ListTile(title: Text(user.fullname), leading: MyUserAvatar(user)));
      }
    }

    if (widget.eventContext.isCurrentUserAuthor(_appContext.currentUser.id) ||
        widget.eventContext.isCurrentUserContributor(_appContext.currentUser.id)) {
      children.add(Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
              onPressed: () => _openEditProgramPage(programEntry),
              icon: const Icon(Icons.edit),
              label: const Text('Edit'))));
    } else {
      children.add(const SizedBox(height: 16));
    }

    showDialog(
        context: context,
        builder: (_) {
          return Dialog(
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children)));
        });
  }

  // * LOGIC
  void _openAddProgramPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddEventProgramPage(eventContext: widget.eventContext)))
        .then((_) {
      setState(() {
        // rebuild in case of update
        if (widget.eventContext.canSaveTheEditing) {
          widget.onProgramChanged();
        }
      });
    });
  }

  void _openEditProgramPage(Map<String, dynamic> programEntry) {
    Navigator.of(context).pop();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EditEventProgramPage(
                  eventContext: widget.eventContext,
                  programEntry: programEntry,
                ))).then((_) {
      setState(() {
        // rebuild in case of update
        if (widget.eventContext.canSaveTheEditing) {
          widget.onProgramChanged();
        }
      });
    });
  }

  void _onRemindEventClick() {
    // in theory, there should be an event date start and end (or all day)
    final String description =
        '${widget.eventContext.head.subtitle}\n\n***************\nPlease keep track of the event via the CTRIM app for any updates. Thank you! 🙏 \n***************';
    // remember about the online event url, we'll add it to the description another time.
    final Event event = Event(
      title: widget.eventContext.head.title,
      description: description,
      location: widget.eventContext.head.location,
      startDate: widget.eventContext.head.eventDate!,
      endDate:
          widget.eventContext.program.finishTime ?? widget.eventContext.head.eventDate!.add(const Duration(hours: 1)),
      allDay: widget.eventContext.program.allDay,
    );
    Add2Calendar.addEvent2Cal(event);
  }

  void _onEditPostProgram() {
    Navigator.push(
            context, MaterialPageRoute(builder: (_) => EditEventDateLocationPage(eventContext: widget.eventContext)))
        .then((_) {
      setState(() {
        if (widget.eventContext.canSaveTheEditing) {
          widget.onProgramChanged();
        }
      });
    });
  }
}
