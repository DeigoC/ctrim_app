import 'package:ctrim_app/pages/events/add_event_page.dart';
import 'package:ctrim_app/pages/events_home.dart';
import 'package:ctrim_app/pages/information_home.dart';
import 'package:ctrim_app/pages/personal_home.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../firebase/auth_manager.dart';

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

  // TODO all bodies should be CustomScrollViews with Sliver Bodies!
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

  // TODO put this into it's own widget
  Widget? _buildDrawer(AppContext appContext) {
    if (_selectedIndex == 2 && !appContext.isCurrentUserGuest) {
      final currentUser = appContext.currentUser;
      return Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Align(alignment: Alignment.bottomLeft, child: Text('Hi, ${currentUser.forname}')),
            ),
            ListTile(
              title: const Text('View Users'),
              leading: const Icon(Icons.people),
              onTap: _onViewAllUserTap,
            ),
            ListTile(
              title: const Text('Log out'),
              leading: const Icon(Icons.logout),
              onTap: _confirmLogout,
            ),
          ],
        ),
      );
    }
    return null;
  }

  // * Logic

  void _onNavigationItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onViewAllUserTap() {}

  void _confirmLogout() async {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Sign out'),
            content: const Text('Are you sure you want to continue?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(
                  onPressed: () {
                    _logout().then((_) {
                      setState(() {});
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    });
                  },
                  child: const Text('Sign out')),
            ],
          );
        });
  }

  Future<void> _logout() async {
    final AuthManager authManager = AuthManager();
    // TODO remove the device token from UserContacts

    Provider.of<AppContext>(context, listen: false).clearCreds();
    Provider.of<AppContext>(context, listen: false).setUserToGuest();
    await authManager.signOut();
  }
}
