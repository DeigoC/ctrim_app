import 'package:ctrim_app/widgets/posts/post_head.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase/db_managers/event_db_manager.dart';
import '../utility/app_context.dart';

class ViewEventsHome extends StatefulWidget {
  const ViewEventsHome({super.key, required this.rebuildFunction, required this.scrollController});
  final Function() rebuildFunction;
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';
  final ScrollController scrollController;

  @override
  State<ViewEventsHome> createState() => _ViewEventsHomeState();
}

class _ViewEventsHomeState extends State<ViewEventsHome> {
  late final AppContext _appContext;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    _appContext.sortPostsByIndex();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (context, appContext, child) {
      // debugPrint('order looks like:');
      // for (var head in appContext.eventHeads) {
      //   debugPrint('head: ${head.id} has recent date of ${head.recentDate}');
      // }
      return RefreshIndicator(
        edgeOffset: (kToolbarHeight * 2) - 8,
        onRefresh: () => _onRefresh().then((value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: !appContext.currentUser.isLeader ? SnackBarBehavior.floating : null,
            content: const Text('You are up to date!')))),
        child: CustomScrollView(
            controller: widget.scrollController,
            key: const PageStorageKey<String>('events_page'),
            slivers: [
              SliverAppBar(
                  title: const Text('Bulletin'),
                  centerTitle: false,
                  floating: true,
                  actions: [IconButton(onPressed: () => _showFilterModel(context), icon: const Icon(Icons.sort))],
                  leading: Image.asset(ViewEventsHome._ctrimLogo, fit: BoxFit.contain, height: kToolbarHeight)),
              SliverList.separated(
                  itemCount: appContext.eventHeads.length,
                  itemBuilder: (_, index) => PostHead(
                        thisHead: appContext.eventHeads[index],
                        updatePost: () => widget.rebuildFunction(),
                      ),
                  separatorBuilder: (BuildContext context, int index) => const Divider(thickness: 1))
            ]),
      );
    });
  }

  void _showFilterModel(BuildContext context) {
    showModalBottomSheet(
        showDragHandle: true,
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        builder: (_) => SafeArea(
                child: BulletinSettingSheet(
              sortIndex: _appContext.postSortIndex,
              descendingRecentDate: () => _onSortPosts(0),
              descendingEventDate: () => _onSortPosts(1),
              ascendingEventDate: () => _onSortPosts(2),
              ascendingRecentDate: () => _onSortPosts(3),
            )));
  }

  // * Logic
  Future<void> _onRefresh() async {
    if (_appContext.sharedPref.canRefreshPosts) {
      debugPrint('refreshing now!');
      await _refreshPosts();
      _appContext.sharedPref.setPostRefreshTime();
    } else {
      debugPrint('cannot refresh cause of timer');
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void _onSortPosts(int newSortIndex) {
    if (newSortIndex != _appContext.postSortIndex) {
      setState(() {
        _appContext.setPostSortIndex(newSortIndex);
        _appContext.sortPostsByIndex();
      });
    }
  }

  Future<void> _refreshPosts() async {
    final EventHeadDBManager headDBManager = EventHeadDBManager();
    final heads = await headDBManager.fetchEventHeads();
    setState(() {
      _appContext.setRefreshedHeads(heads);
    });
  }
}

class BulletinSettingSheet extends StatefulWidget {
  const BulletinSettingSheet(
      {super.key,
      required this.sortIndex,
      required this.descendingRecentDate,
      required this.ascendingRecentDate,
      required this.descendingEventDate,
      required this.ascendingEventDate});
  final int sortIndex;
  final void Function() descendingRecentDate, ascendingRecentDate, descendingEventDate, ascendingEventDate;

  @override
  State<BulletinSettingSheet> createState() => _BulletinSettingSheetState();
}

class _BulletinSettingSheetState extends State<BulletinSettingSheet> {
  int _sortIndex = 0;
  @override
  void initState() {
    _sortIndex = widget.sortIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        title: const Text('Locations: Belfast'),
        subtitle: const Text('(Fixed for now!)'),
        leading: const Icon(Icons.church),
        trailing: const Icon(Icons.edit),
        onTap: () {},
      ),
      const Divider(),
      ListTile(
          title: const Text('Most Recent Activity'),
          leading: const Icon(Icons.edit_document),
          selected: _sortIndex == 0,
          onTap: () => _onSortByRecentDateDescending()),
      ListTile(
          title: const Text('Upcoming Events'),
          leading: const Icon(Icons.calendar_month),
          selected: _sortIndex == 1,
          onTap: () => _onSortByEventDateDescending()),
      ListTile(
          title: const Text('Past Events'),
          leading: const Icon(Icons.calendar_month_outlined),
          selected: _sortIndex == 2,
          onTap: () => _onSortByEventDateAscending()),
      ListTile(
          title: const Text('Stale Posts'),
          leading: const Icon(Icons.folder_outlined),
          selected: _sortIndex == 3,
          onTap: () => _onSortByRecentDateAscending())
    ]));
  }

  void _onSortByRecentDateDescending() {
    setState(() {
      widget.descendingRecentDate();
      _sortIndex = 0;
    });
  }

  void _onSortByRecentDateAscending() {
    setState(() {
      widget.ascendingRecentDate();
      _sortIndex = 3;
    });
  }

  void _onSortByEventDateDescending() {
    setState(() {
      widget.descendingEventDate();
      _sortIndex = 1;
    });
  }

  void _onSortByEventDateAscending() {
    setState(() {
      widget.ascendingEventDate();
      _sortIndex = 2;
    });
  }
}
