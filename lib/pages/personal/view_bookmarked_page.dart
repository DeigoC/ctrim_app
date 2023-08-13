import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event/event_head.dart';
import '../../utility/app_context.dart';
import '../../widgets/posts/post_head.dart';

class ViewBookmarksPage extends StatefulWidget {
  const ViewBookmarksPage({super.key});

  @override
  State<ViewBookmarksPage> createState() => _ViewBookmarksPageState();
}

class _ViewBookmarksPageState extends State<ViewBookmarksPage> {
  @override
  void initState() {
    // TODO remember to remove bookmarks of posts that aren't being fetched anymore
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    return Consumer<AppContext>(builder: (context, appContext, child) {
      final List<EventHead> bookedmarked =
          appContext.eventHeads.where((head) => appContext.dataManager.bookmarkedPosts.contains(head.id)).toList();
      return CustomScrollView(key: const PageStorageKey<String>('events_page'), slivers: [
        SliverAppBar(
          title: const Text('Bookmarked'),
          actions: [
            IconButton(
                onPressed: () {
                  DialogManager.showAlertDialog(
                      context: context,
                      title: 'Bookmarked Posts',
                      content: 'You will be notified of updates made to the posts you bookmark.');
                },
                icon: const Icon(Icons.help))
          ],
        ),
        SliverList.separated(
            itemCount: bookedmarked.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(thickness: 1),
            itemBuilder: (_, index) => PostHead(
                thisHead: bookedmarked[index],
                updatePost: () {
                  setState(() {});
                }))
      ]);
    });
  }
}
