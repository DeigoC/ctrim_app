import 'package:ctrim_app/pages/events/add_event_page.dart';
import 'package:ctrim_app/pages/events_home.dart';
import 'package:ctrim_app/pages/information_home.dart';
import 'package:ctrim_app/pages/settings_home.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CTRIM'),
      ),
      body: _buildSelectedBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'CTRIM'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => _onNavigationItemTap(index),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => AddEventPage(eventContext: EventContext.adding())));
          },
          label: const Text('Add Post')),
    );
  }

  _onNavigationItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildSelectedBody() {
    if (_selectedIndex == 0) {
      return const ViewEventsHome();
    } else if (_selectedIndex == 1) {
      return const InformationHome();
    }
    return const SettingsHome();
  }
}
