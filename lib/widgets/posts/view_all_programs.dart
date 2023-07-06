import 'package:ctrim_app/firebase/db_managers/event_db_manager.dart';
import 'package:flutter/material.dart';
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
  @override
  void initState() {
    // TODO sort the program here!
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
            widget.eventContext.setProgram(snap.data!);
            result = _buildBodyWithData();
          } else if (snap.hasError) {
            result = const Center(
              child: Text('Something went wrong! :('),
            );
          }
          return result;
        });
  }

  Widget _buildBodyWithData() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
              itemCount: widget.eventContext.allPrograms.length,
              itemBuilder: (_, index) {
                return _buildRoleTile(widget.eventContext.allPrograms[index]);
              }),
        ),
        SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
                onPressed: _openAddProgramPage,
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Add Program')),
          ),
        ))
      ],
    );
  }

  Widget _buildRoleTile(Map<String, dynamic> programEntry) {
    return ListTile(
      title: Text(programEntry['detail']),
      subtitle: Text((programEntry['start'] as DateTime).toString()),
      onTap: () => _showProgramDialog(programEntry),
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
    // context.goNamed('add_program', extra: widget.eventContext); // ! Doesn't work
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
    // context.goNamed('edit_program', extra: widget.eventContext); // ! Doesn't work
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
}
