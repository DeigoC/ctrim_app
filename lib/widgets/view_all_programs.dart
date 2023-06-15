import 'package:ctrim_app/models/event_role.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ViewAllPrograms extends StatefulWidget {
  const ViewAllPrograms({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<ViewAllPrograms> createState() => _ViewAllProgramsPageState();
}

class _ViewAllProgramsPageState extends State<ViewAllPrograms> {
  late List<EventRole> _allRoles;

  @override
  void initState() {
    widget.eventContext.sortEventsByTime();
    _allRoles = widget.eventContext.allRoles;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
              itemCount: _allRoles.length,
              itemBuilder: (_, index) {
                EventRole thisRole = _allRoles[index];
                return _buildRoleTile(thisRole);
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

  Widget _buildRoleTile(EventRole thisRole) {
    return ListTile(
      title: Text(thisRole.title),
      subtitle: Text(thisRole.startTime.toString()),
      onTap: () => _buildProgramDialog(thisRole),
    );
  }

  _buildProgramDialog(EventRole thisRole) {
    showDialog(
        context: context,
        builder: (_) {
          // ? Do we need to rebuild this Dialog after an edit's been done?
          // obv we can use the AppContext Provider but... is that feasible?
          return Dialog(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text('TODO ${thisRole.id}'),
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
    // TODO this isn't a future, so that means we'll depend on the AppProvider at the highest level to
    // make changes from one page to another.
    context.goNamed('add_program', extra: widget.eventContext);
  }

  _openEditProgramPage() {
    // set the programID to edit to the context we pass
    context.goNamed('edit_program', extra: widget.eventContext);
  }
}
