import 'package:ctrim_app/pages/events/events_home_page.dart';
import 'package:ctrim_app/pages/information/information_home_page.dart';
import 'package:ctrim_app/pages/settings/settings_home_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CTRIM'),
      ),
      body: _buildSelectedBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.info)),
          BottomNavigationBarItem(icon: Icon(Icons.home)),
          BottomNavigationBarItem(icon: Icon(Icons.settings)),
        ],
        currentIndex: _selectedIndex,
        onTap: _onNavigationItemTap,
      ),
    );
  }

  _onNavigationItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildSelectedBody() {
    if (_selectedIndex == 0) {
      return const InformationHomePage();
    } else if (_selectedIndex == 1) {
      return const ViewEventsHomePage();
    }
    return const SettingsHomePage();
  }
}
