import 'package:ctrim_app/firebase/messaging_manager.dart';
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final TabController _informationTabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    _informationTabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfFirstOpen();
    });
    super.initState();
  }

  @override
  void dispose() {
    _informationTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (context, appContext, child) {
      return Scaffold(
          body: _buildSelectedBody(appContext),
          drawer: _buildDrawer(appContext),
          floatingActionButton: _buildFAB(),
          bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => _onNavigationItemTap(index),
              unselectedFontSize: 0,
              selectedFontSize: 0,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark), label: 'Posts'),
                BottomNavigationBarItem(icon: Icon(Icons.church), label: 'CTRIM'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Personal')
              ]));
    });
  }

  Widget _buildSelectedBody(AppContext appContext) {
    if (_selectedIndex == 0) {
      return ViewEventsHome(rebuildFunction: () {
        setState(() {});
      });
    } else if (_selectedIndex == 1) {
      return InformationHome(
        tabController: _informationTabController,
      );
    }
    return PersonalHome(
      appContext: appContext,
    );
  }

  Widget? _buildFAB() {
    final appContext = Provider.of<AppContext>(context, listen: false);
    if (_selectedIndex == 0 && appContext.currentUser.isLeader) {
      return FloatingActionButton.extended(
          onPressed: () {
            final String uid = appContext.currentUser.id;
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => AddEventPage(eventContext: EventContext.adding(uid: uid)))).then((_) {
              setState(() {});
            });
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

  void _checkIfFirstOpen() async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    if (appContext.dataManager.isFirstOpen) {
      final MessagingManager messagingManager = MessagingManager();
      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
              child: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text('Welcome! 👋',
                                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.start)),
                        const SizedBox(height: 16),
                        const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text('Please allow notifications to keep up with the latest from CTRIM!',
                                textAlign: TextAlign.start, style: TextStyle(fontSize: 16))),
                        const SizedBox(height: 8),
                        Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: TextButton(
                                    onPressed: () => Navigator.pop(_),
                                    child: const Text('Ok', style: TextStyle(fontSize: 16)))))
                      ])))));

      final token = await messagingManager.requestPermissionAndToken();
      if (token != null) {
        debugPrint('Token to save is $token');
        appContext.dataManager.saveToken(token);
      }
      messagingManager.subscribeToCTRIMBelfast();
      appContext.dataManager.nowOpened();
    }
  }
}
