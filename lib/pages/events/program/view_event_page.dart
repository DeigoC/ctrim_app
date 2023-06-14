import 'package:ctrim_app/widgets/rich_text_view.dart';
import 'package:flutter/material.dart';

import '../../../models/event_body.dart';
import '../../../models/event_role.dart';
import '../../../utility/event_context.dart';
import '../../../widgets/view_all_programs.dart';

class ViewEventPage extends StatefulWidget {
  const ViewEventPage({super.key});

  @override
  State<ViewEventPage> createState() => _ViewEventPageState();
}

class _ViewEventPageState extends State<ViewEventPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final EventContext _eventContext;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _eventContext = EventContext(eventBody: EventBody('[{"insert":"Hello, time to start writing!\n"}]'));
    _eventContext.addManyRoles([
      EventRole(
          id: '1',
          title: 'Role 1',
          startTime: DateTime.now(),
          finishTime: DateTime.now().add(const Duration(minutes: 20))),
      EventRole(
          id: '2',
          title: 'Role 2',
          startTime: DateTime.now(),
          finishTime: DateTime.now().add(const Duration(minutes: 35))),
      EventRole(
          id: '3',
          title: 'Role 3',
          startTime: DateTime.now().add(const Duration(hours: 1)),
          finishTime: DateTime.now().add(const Duration(hours: 1, minutes: 20))),
      EventRole(
          id: '4',
          title: 'Role 4',
          startTime: DateTime.now().add(const Duration(minutes: 30)),
          finishTime: DateTime.now().add(const Duration(minutes: 45))),
    ]);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return NestedScrollView(
        headerSliverBuilder: (_, __) {
          return _buildHeaderSliver();
        },
        body: _buildTabBody());
  }

  List<Widget> _buildHeaderSliver() {
    return [
      SliverAppBar(
        expandedHeight: MediaQuery.of(context).size.height * 0.33,
      ),
      SliverPadding(
        padding: const EdgeInsets.all(0.0),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            TabBar(
              labelColor: Colors.black,
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.info_outline),
                  text: 'About',
                ),
                Tab(
                  icon: Icon(Icons.calendar_today),
                  text: 'Program',
                ),
              ],
            ),
          ]),
        ),
      )
    ];
  }

  Widget _buildTabBody() {
    return TabBarView(controller: _tabController, children: [
      EventBodyView(
        eventContext: _eventContext,
      ),
      ViewAllPrograms(eventContext: _eventContext)
    ]);
  }
}
