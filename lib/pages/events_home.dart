import 'package:ctrim_app/widgets/posts/post_head.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utility/app_context.dart';

class ViewEventsHome extends StatelessWidget {
  const ViewEventsHome({super.key, required this.rebuildFunction});
  final Function() rebuildFunction;
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';
  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (context, appContext, child) {
      appContext.orderEventDatesByRecency();
      return CustomScrollView(key: const PageStorageKey<String>('events_page'), slivers: [
        SliverAppBar(
            title: const Text('Bulletin'),
            centerTitle: false,
            floating: true,
            leading: Image.asset(_ctrimLogo, fit: BoxFit.contain, height: kToolbarHeight)),
        SliverList.separated(
            itemCount: appContext.eventHeads.length,
            itemBuilder: (_, index) => PostHead(
                  thisHead: appContext.eventHeads[index],
                  updatePost: () => rebuildFunction(),
                ),
            separatorBuilder: (BuildContext context, int index) => const Divider(thickness: 1))
      ]);
    });
  }
}
