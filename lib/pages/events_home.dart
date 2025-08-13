import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase/db_managers/event_db_manager.dart';
import '../models/event/event_head.dart';
import '../utility/app_context.dart';
import '../utility/dialog_manager.dart';
import '../widgets/posts/post_head.dart';

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
      final bool defaultFilter = appContext.postSortIndex == 0;
      final List<EventHead> eventHeads =
          defaultFilter ? List.empty() : List.from(appContext.eventHeads, growable: true);

      if (!defaultFilter) {
        if (appContext.postSortIndex == 1) {
          eventHeads.removeWhere(
              (e) => e.eventDate == null || e.eventDate!.add(const Duration(hours: 12)).isBefore(DateTime.now()));
        } else if (appContext.postSortIndex == 2) {
          eventHeads.removeWhere((e) => e.eventDate == null || e.eventDate!.isAfter(DateTime.now()));
        } else if (appContext.postSortIndex == 3) {
          eventHeads.removeWhere((e) => !appContext.sharedPref.bookmarkedPosts.contains(e.id));
        }
      }

      final int itemCount = defaultFilter ? appContext.eventHeads.length : eventHeads.length;
      final double webHorizontalPadding =
          MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 5 : 0;

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
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
                sliver: SliverList.separated(
                    itemCount: itemCount,
                    itemBuilder: (_, index) => PostHead(
                          thisHead: defaultFilter ? appContext.eventHeads[index] : eventHeads[index],
                          updatePost: () => widget.rebuildFunction(),
                        ),
                    separatorBuilder: (BuildContext context, int index) => const Divider(thickness: 1)),
              )
            ]),
      );
    });
  }

  void _showFilterModel(final BuildContext context) {
    showModalBottomSheet(
        showDragHandle: true,
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        builder: (_) => SafeArea(
                child: BulletinSettingSheet(
              sortIndex: _appContext.postSortIndex,
              relevancySort: () => _onSortPosts(0),
              descendingEventDate: () => _onSortPosts(1),
              ascendingEventDate: () => _onSortPosts(2),
              showBookmarks: () => _onSortPosts(3),
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
      required this.relevancySort,
      required this.descendingEventDate,
      required this.ascendingEventDate,
      required this.showBookmarks});
  final int sortIndex;
  final void Function() relevancySort, descendingEventDate, ascendingEventDate, showBookmarks;

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
      const ListTile(
        title: Text('Sort by...'),
        leading: Icon(Icons.sort),
      ),
      const Divider(indent: 16, endIndent: 16),
      ListTile(
          title: const Text('Relevancy'),
          leading: const Icon(Icons.star),
          subtitle: const Text('See the most relevant posts first'),
          selected: _sortIndex == 0,
          onTap: () => _onSortClick(0)),
      ListTile(
          title: const Text('Upcoming Events'),
          leading: const Icon(Icons.calendar_month),
          subtitle: const Text('Exciting events happening soon'),
          selected: _sortIndex == 1,
          onTap: () => _onSortClick(1)),
      ListTile(
          title: const Text('Recent Events'),
          subtitle: const Text('See what you missed'),
          leading: const Icon(Icons.calendar_month_outlined),
          selected: _sortIndex == 2,
          onTap: () => _onSortClick(2)),
      ListTile(
          title: const Text('Bookmarks'),
          leading: const Icon(Icons.bookmarks),
          subtitle: const Text('Posts you want to keep track of'),
          selected: _sortIndex == 3,
          trailing: IconButton(
            icon: const Icon(Icons.help),
            onPressed: _onBookmarkedHelp,
          ),
          onTap: () => _onSortClick(3)),
    ]));
  }

  void _onSortClick(final int sortIndex) {
    Navigator.pop(context); // close the modal
    setState(() {
      _sortIndex = sortIndex;
      switch (sortIndex) {
        case 0:
          widget.relevancySort();
          break;
        case 1:
          widget.descendingEventDate();
          break;
        case 2:
          widget.ascendingEventDate();
          break;
        case 3:
          widget.showBookmarks();
          break;
      }
    });
  }

  void _onBookmarkedHelp() {
    DialogManager.showAlertDialog(
        context: context,
        title: 'Bookmarked Posts',
        content: 'You will be notified of updates made to the posts you bookmark.');
  }
}
