import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utility/app_context.dart';
import '../utility/event_context.dart';
import '../widgets/personal_drawer.dart';
import 'events/add_event_page.dart';
import 'events_home.dart';
import 'information_home.dart';
import 'personal_home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (context, appContext, child) {
      return Scaffold(
        body: _buildSelectedBody(appContext),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark), label: 'Notice Board'),
            BottomNavigationBarItem(icon: Icon(Icons.church), label: 'CTRIM'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Personal'),
          ],
          currentIndex: _selectedIndex,
          onTap: (index) => _onNavigationItemTap(index),
        ),
        drawer: _buildDrawer(appContext),
        floatingActionButton: _buildFAB(),
      );
    });
  }

  Widget _buildSelectedBody(AppContext appContext) {
    if (_selectedIndex == 0) {
      return const ViewEventsHome();
    } else if (_selectedIndex == 1) {
      return const InformationHome();
    }
    return PersonalHome(
      appContext: appContext,
    );
  }

  Widget? _buildFAB() {
    if (_selectedIndex == 0) {
      return FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => AddEventPage(eventContext: EventContext.adding())));
          },
          label: const Text('Add Post'));
    }
    return null;
  }

  Widget? _buildDrawer(AppContext appContext) {
    if (_selectedIndex == 2 && !appContext.isCurrentUserGuest) {
      return const PersonalDrawer();
    }
    return null;
  }

  // * Logic

  void _onNavigationItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
