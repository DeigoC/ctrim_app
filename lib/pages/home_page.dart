import 'package:ctrim_app/pages/events/add_event_page.dart';
import 'package:ctrim_app/pages/events_home.dart';
import 'package:ctrim_app/pages/information_home.dart';
import 'package:ctrim_app/pages/personal_home.dart';
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
          BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark), label: 'Notice Board'),
          BottomNavigationBarItem(icon: Icon(Icons.church), label: 'CTRIM'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Personal'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => _onNavigationItemTap(index),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // TODO all bodies should be CustomScrollViews with Sliver Bodies!
  Widget _buildSelectedBody() {
    if (_selectedIndex == 0) {
      return const ViewEventsHome();
    } else if (_selectedIndex == 1) {
      return const InformationHome();
    }
    return const PersonalHome();
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

  void _onNavigationItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
