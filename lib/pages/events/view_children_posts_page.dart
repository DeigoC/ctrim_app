import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/pages/events/view_event_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewChildrenPosts extends StatelessWidget {
  const ViewChildrenPosts({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Related Posts'),
      ),
      body: _needToFetchChildren() ? _buildFBBody() : _buildBodyWithData(),
    );
  }

  Widget _buildFBBody() {
    return Container();
  }

  Widget _buildBodyWithData() {
    return Consumer<AppContext>(builder: (context, appContext, child) {
      final List<EventHead> children =
          appContext.eventHeads.where((element) => eventContext.metadata.children.contains(element.id)).toList();
      return ListView.builder(
          itemCount: children.length,
          itemBuilder: (_, index) {
            final EventHead thisHead = children[index];
            return ListTile(
              title: Text(thisHead.title),
              subtitle: Text(thisHead.subtitle),
              onTap: () => _openChildPost(context, thisHead),
            );
          });
    });
  }

  // * Logic
  bool _needToFetchChildren() {
    return false;
  }

  void _openChildPost(BuildContext context, EventHead thisHead) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ViewEventPage(
                  eventHead: thisHead,
                  viewingChild: true,
                )));
  }
}
