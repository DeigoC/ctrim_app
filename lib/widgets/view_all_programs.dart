import 'package:ctrim_app/models/event_role.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

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
    return ListView.builder(
        itemCount: _allRoles.length,
        itemBuilder: (_, index) {
          EventRole thisRole = _allRoles[index];
          return _buildRoleTile(thisRole);
        });
  }

  Widget _buildRoleTile(EventRole thisRole) {
    return ListTile(
      title: Text(thisRole.title),
      subtitle: Text(thisRole.startTime.toString()),
    );
  }
}
