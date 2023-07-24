import 'package:ctrim_app/firebase/db_managers/event_db_manager.dart';
import 'package:ctrim_app/pages/events/edit_event_date_location_page.dart';
import 'package:ctrim_app/widgets/posts/program_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../pages/events/add_program_page.dart';
import '../../pages/events/edit_program_page.dart';
import '../../utility/event_context.dart';

class ViewAllPrograms extends StatefulWidget {
  const ViewAllPrograms({super.key, required this.eventContext, required this.onProgramChanged});
  final EventContext eventContext;
  final Function onProgramChanged;

  @override
  State<ViewAllPrograms> createState() => _ViewAllProgramsPageState();
}

class _ViewAllProgramsPageState extends State<ViewAllPrograms> {
  static final DateFormat _startFormat = DateFormat('EEEE d MMM yyyy, HH:mm');
  static final DateFormat _startFormatAllDay = DateFormat('EEEE d MMM yyyy');
  static final DateFormat _endFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eventContext.haveFetchedProgram) {
      return _buildBodyWithData();
    }
    return _buildFB();
  }

  Widget _buildFB() {
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(widget.eventContext.head.id);
    return FutureBuilder(
        future: dbManager.fetchProgram(),
        builder: (_, snap) {
          Widget result = const Center(
            child: CircularProgressIndicator(),
          );
          if (snap.hasData) {
            widget.eventContext.setFetchedProgram(snap.data!);
            result = _buildBodyWithData();
          } else if (snap.hasError) {
            // when there's no program, it goes here
            result = const Center(
              child: Text('No program fetched'),
            );
          }
          return result;
        });
  }

  Widget _buildBodyWithData() {
    if (widget.eventContext.head.eventDate != null) {
      return _buildBodyWithEventDate();
    }
    return SingleChildScrollView(child: _buildEventDateSelector());
  }

  Widget _buildBodyWithEventDate() {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
              child: CustomScrollView(
            slivers: [
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
            ],
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: _openAddProgramPage,
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Add Program')),
            ),
          )
        ],
      ),
    );
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

    return InkWell(
      onTap: _onEditPostProgram,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ListTile(title: Text(dateStr), leading: const Icon(Icons.calendar_today)),
        const ListTile(title: Text('Belfast'), leading: Icon(Icons.map)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: ElevatedButton.icon(
              onPressed: _onRemindEventClick, icon: const Icon(Icons.calendar_month), label: const Text('Remind me')),
        ),
        const Divider(
          thickness: 1,
        ),
      ]),
    );
  }

  void _showProgramDialog(Map<String, dynamic> programEntry) {
    showDialog(
        context: context,
        builder: (_) {
          return Dialog(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text('TODO - complete this!'),
                  Text(programEntry['detail']),
                  ElevatedButton.icon(
                      onPressed: () => _openEditProgramPage(programEntry),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'))
                ],
              ),
            ),
          );
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

  void _onRemindEventClick() {}

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
