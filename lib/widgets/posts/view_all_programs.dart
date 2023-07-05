import 'package:ctrim_app/firebase/db_managers/event_db_manager.dart';
import 'package:flutter/material.dart';
import '../../pages/events/add_program_page.dart';
import '../../pages/events/edit_program_page.dart';
import '../../utility/event_context.dart';

class ViewAllPrograms extends StatefulWidget {
  const ViewAllPrograms({super.key, required this.eventContext});
  final EventContext eventContext;

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
            child: ElevatedButton.icon(
                onPressed: () => _openAddProgramPage(),
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Add Program')))
      ],
    );
  }

  Widget _buildRoleTile(Map<String, dynamic> programEntry) {
    return ListTile(
      title: Text(programEntry['detail']),
      subtitle: Text((programEntry['start'] as DateTime).toString()),
      onTap: () => _buildProgramDialog(programEntry),
    );
  }

  _buildProgramDialog(Map<String, dynamic> programEntry) {
    showDialog(
        context: context,
        builder: (_) {
          // ? Do we need to rebuild this Dialog after an edit's been done?
          // obv we can use the AppContext Provider but... is that feasible?
          return Dialog(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text('TODO - complete this! '),
                  Text(programEntry['detail']),
                  ElevatedButton.icon(
                      onPressed: () => _openEditProgramPage(), icon: const Icon(Icons.edit), label: const Text('Edit'))
                ],
              ),
            ),
          );
        });
  }

  // * LOGIC
  _openAddProgramPage() {
    // context.goNamed('add_program', extra: widget.eventContext); // ! Doesn't work
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddEventProgramPage(eventContext: widget.eventContext)));
  }

  _openEditProgramPage() {
    // context.goNamed('edit_program', extra: widget.eventContext); // ! Doesn't work
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditEventProgramPage(eventContext: widget.eventContext)))
        .then((_) {
      setState(() {
        // rebuild in case of update
      });
    });
  }
}
