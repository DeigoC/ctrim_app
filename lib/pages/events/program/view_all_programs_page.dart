import 'package:ctrim_app/models/event_role.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class ViewAllProgramsPage extends StatefulWidget {
  const ViewAllProgramsPage({super.key, required this.eventContext});
  final EventContext eventContext;
  static const String routeName = '/view_all_programs';

  @override
  State<ViewAllProgramsPage> createState() => _ViewAllProgramsPageState();
}

class _ViewAllProgramsPageState extends State<ViewAllProgramsPage> {
  late List<EventRole> _allRoles;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _allRoles = widget.eventContext.allRoles;
    _allRoles.sort((a, b) {
      // ? This time sorting could be a problem later, be weary of it
      if (a.startTime.compareTo(b.startTime) == 0) {
        return a.priorty.compareTo(b.priorty);
      }
      return a.startTime.compareTo(b.startTime);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('View all programs'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
