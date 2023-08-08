import 'package:ctrim_app/widgets/posts/post_head.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utility/app_context.dart';

class ViewEventsHome extends StatefulWidget {
  const ViewEventsHome({super.key, required this.rebuildFunction});
  final Function() rebuildFunction;
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';

  @override
  State<ViewEventsHome> createState() => _ViewEventsHomeState();
}

class _ViewEventsHomeState extends State<ViewEventsHome> {
  int _sortIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (context, appContext, child) {
      appContext.orderEventDatesByRecency();
      return RefreshIndicator(
        edgeOffset: kToolbarHeight * 2,
        onRefresh: _onRefresh,
        child: CustomScrollView(key: const PageStorageKey<String>('events_page'), slivers: [
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
              sortIndex: _sortIndex,
              descendingRecentDate: _onSortByRecentDateDescending,
              ascendingRecentDate: _onSortByRecentDateAscending,
              descendingEventDate: _onSortByEventDateDescending,
              ascendingEventDate: _onSortByEventDateAscending,
            )));
  }

  // * Logic
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('refresh called');
  }

  void _onSortByRecentDateDescending() {
    setState(() {
      _sortIndex = 0;
    });
  }

  void _onSortByRecentDateAscending() {
    setState(() {
      _sortIndex = 1;
    });
  }

  void _onSortByEventDateDescending() {
    setState(() {
      _sortIndex = 2;
    });
  }

  void _onSortByEventDateAscending() {
    setState(() {
      _sortIndex = 3;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('Locations: Belfast'),
            subtitle: Text('(Fixed for now!)'),
            leading: Icon(Icons.church),
            trailing: Icon(Icons.edit),
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
              selected: _sortIndex == 2,
              onTap: () => _onSortByEventDateDescending()),
          ListTile(
              title: const Text('Past Events'),
              leading: const Icon(Icons.calendar_month_outlined),
              selected: _sortIndex == 3,
              onTap: () => _onSortByEventDateAscending()),
          ListTile(
              title: const Text('Stale Posts'),
              leading: const Icon(Icons.folder_outlined),
              selected: _sortIndex == 1,
              onTap: () => _onSortByRecentDateAscending()),
        ],
      ),
    );
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
      _sortIndex = 1;
    });
  }

  void _onSortByEventDateDescending() {
    setState(() {
      widget.descendingEventDate();
      _sortIndex = 2;
    });
  }

  void _onSortByEventDateAscending() {
    setState(() {
      widget.ascendingEventDate();
      _sortIndex = 3;
    });
  }
}
