import 'package:ctrim_app/firebase/db_managers/event_db_manager.dart';
import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/event/event_metadata.dart';
import 'package:ctrim_app/pages/events/view_children_posts_page.dart';
import 'package:ctrim_app/pages/events/view_event_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PostMetadataSection extends StatelessWidget {
  const PostMetadataSection({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(
      builder: (context, appContext, child) {
        EventMetadata? meta = appContext.getMetadata(eventContext.id);
        if (meta != null) {
          eventContext.setFetchedMetadata(meta);
          return _buildWithData(context);
        }
        return _buildFB();
      },
    );
  }

  Widget _buildFB() {
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(eventContext.head.id);
    return FutureBuilder(
        future: dbManager.fetchMetadata(),
        builder: (_, snap) {
          Widget result = const Center(
            child: CircularProgressIndicator(),
          );

          if (snap.hasData) {
            eventContext.setFetchedMetadata(snap.data!);
            Provider.of<AppContext>(_, listen: false).addMetadata(eventContext.id, snap.data!);
            result = _buildWithData(_);
          } else if (snap.hasError) {
            debugPrint('Error with fetching metadata: ${snap.error}');
            result = const Center(
              child: Text('Something went wrong :('),
            );
          }

          return result;
        });
  }

  Widget _buildWithData(BuildContext context) {
    final List<Widget> children = [
      TextButton(onPressed: () {}, child: const Text('Name Here • Date here')),
    ];
    if (eventContext.metadata.hasParent) {
      children.add(TextButton(
          onPressed: () {
            _onViewParentPostClick(context);
          },
          child: const Text('Parent Post')));
    }
    if (eventContext.metadata.hasChildren) {
      children.add(TextButton(
          onPressed: () {
            _onViewChildrenClick(context);
          },
          child: const Text('Children Posts')));
    }

    return Wrap(children: children);
  }

  // * Logic

  void _onViewParentPostClick(BuildContext context) {
    if (eventContext.isViewingChild) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else {
      // open the view event page for the parent post - there's a chance we may need to fetch the head
      final EventHead? parent = _getParent(context);
      if (parent == null) {
        debugPrint('need to fetch parent post');
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => ViewEventPage(eventHead: parent, viewingChild: false)));
      }
    }
  }

  void _onViewChildrenClick(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ViewChildrenPosts(eventContext: eventContext)));
  }

  EventHead? _getParent(BuildContext context) {
    if (Provider.of<AppContext>(context, listen: false)
        .eventHeads
        .any((element) => element.id.compareTo(eventContext.metadata.parentID!) == 0)) {
      return Provider.of<AppContext>(context, listen: false)
          .eventHeads
          .firstWhere((element) => element.id.compareTo(eventContext.metadata.parentID!) == 0);
    }
    return null;
  }
}
