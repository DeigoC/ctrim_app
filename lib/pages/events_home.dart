import 'package:ctrim_app/widgets/posts/post_head.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utility/app_context.dart';

class ViewEventsHome extends StatelessWidget {
  const ViewEventsHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (context, appContext, child) {
      return ListView.builder(
          itemCount: appContext.eventHeads.length,
          itemBuilder: (_, index) {
            if (index == 1) {
              // appContext.eventHeads[index].media.add({
              //   'title': '',
              //   'src':
              //       'https://images.bauerhosting.com/legacy/empire-images/articles/57441cfbbf1bdcf50c7ed54a/garfield_2_08.jpg?q=80&auto=format&w=440&ar=16:9&fit=crop&crop=top',
              //   'type': 'img'
              // });
            }
            return PostHead(thisHead: appContext.eventHeads[index]);
          });
    });
  }
}
