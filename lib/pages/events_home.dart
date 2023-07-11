import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event/event_head.dart';
import '../utility/app_context.dart';
import 'events/view_event_page.dart';

class ViewEventsHome extends StatelessWidget {
  const ViewEventsHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (context, appContext, child) {
      return ListView.builder(
          itemCount: appContext.eventHeads.length,
          itemBuilder: (_, index) {
            final EventHead thisHead = appContext.eventHeads[index];
            return ListTile(
              title: Text(thisHead.title),
              subtitle: Text(thisHead.subtitle),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ViewEventPage(
                              eventHead: thisHead,
                              viewingChild: false,
                            )));
              },
            );
          });
    });
  }
}
