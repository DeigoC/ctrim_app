import 'package:ctrim_app/firebase/db_managers/event_db_manager.dart';
import 'package:ctrim_app/models/event/event_metadata.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../pages/events/select_post_template_page.dart';
import '../../utility/app_context.dart';
import '../../utility/event_context.dart';
import 'post_head.dart';

class ViewRelatedPostsTab extends StatefulWidget {
  const ViewRelatedPostsTab({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<ViewRelatedPostsTab> createState() => _ViewRelatedPostsTabState();
}

class _ViewRelatedPostsTabState extends State<ViewRelatedPostsTab> {
  late final AppContext _appContext;
  final EventHeadDBManager _headDbManager = EventHeadDBManager();

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [Expanded(child: _buildBody())];

    if (_appContext.currentUser.isLeader) {
      children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: ElevatedButton.icon(
              onPressed: _onCreatePost, icon: const Icon(Icons.post_add), label: const Text('Create Related Post'))));
    }
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: SafeArea(
        top: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.eventContext.metadata.hasParent || widget.eventContext.metadata.hasChildren) {
      return _buildRelatedFB();
    }
    return const Center(child: Text('No related posts'));
  }

  Widget _buildRelatedFB() {
    return FutureBuilder(
        future: _fetchAllRelatedPosts(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            result = _buildBodyWithData();
          } else if (snap.hasError) {
            debugPrint('error with fetching all related posts: ${snap.error}');
            result = const Center(child: Text('Something went wrong'));
          }

          return result;
        });
  }

  Widget _buildBodyWithData() {
    final List<PostHead> relatedPosts = List.empty(growable: true);

    if (widget.eventContext.metadata.hasParent) {
      relatedPosts.add(_getParentPostHead());
      relatedPosts.addAll(_getSiblingPosts());
    }

    relatedPosts.addAll(_buildChildrenPosts());

    return ListView.separated(
        separatorBuilder: (context, index) => const Divider(),
        itemCount: relatedPosts.length,
        itemBuilder: (_, index) => relatedPosts[index]);
  }

  PostHead _getParentPostHead() {
    // remember that this parent may not exist so we have to fetch and add via FB
    final thisParent =
        _appContext.eventHeads.firstWhere((e) => e.id.compareTo(widget.eventContext.metadata.parentID!) == 0);
    return PostHead(
        thisHead: thisParent,
        updatePost: () {
          setState(() {});
        });
  }

  List<PostHead> _getSiblingPosts() {
    final siblingPostsID = _appContext.getMetadata(widget.eventContext.metadata.parentID!)!.childrenPostIDs;
    final sublingPosts =
        _appContext.eventHeads.where((head) => head.id != widget.eventContext.id && siblingPostsID.contains(head.id));
    return sublingPosts
        .map((e) => PostHead(
            thisHead: e,
            updatePost: () {
              setState(() {});
            }))
        .toList();
  }

  List<PostHead> _buildChildrenPosts() {
    final childrenHeads =
        _appContext.eventHeads.where((head) => widget.eventContext.metadata.childrenPostIDs.contains(head.id));
    return childrenHeads
        .map((e) => PostHead(
            thisHead: e,
            updatePost: () {
              setState(() {});
            }))
        .toList();
  }

  // * Logic

  void _onCreatePost() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SelectPostTemplatePage(
                eventContext: EventContext.adding(
                    currentUserID: _appContext.currentUser.id, parentID: widget.eventContext.id)))).then((_) {
      setState(() {
        // rebuild?
      });
    });
  }

  // this is going to be a major method to fetch all the data needed
  // parent post + meta, sibling posts, children posts - all if needed
  Future<bool> _fetchAllRelatedPosts() async {
    final String? parentID = widget.eventContext.metadata.parentID;

    // fetch parent
    if (parentID != null && !_appContext.eventHeads.any((e) => e.id == parentID)) {
      _appContext.addOrUpdatePostHead(await _headDbManager.fetchHead(parentID));
    }

    // fetch siblings
    await _getSiblingPostID();

    // fetch children
    for (final childrenID in widget.eventContext.metadata.childrenPostIDs) {
      if (!_appContext.eventHeads.any((e) => e.id == childrenID)) {
        _appContext.addOrUpdatePostHead(await _headDbManager.fetchHead(childrenID));
      }
    }

    return true;
  }

  Future<void> _getSiblingPostID() async {
    final String? parentID = widget.eventContext.metadata.parentID;
    if (parentID == null) {
      return;
    }
    EventMetadata? parentMeta = _appContext.getMetadata(parentID);

    // make sure the metadata exists
    if (parentMeta == null) {
      // fetch from DB. Technically it could also exist in local storage but... screw it!
      final EventSupplementalDBManager dbManager = EventSupplementalDBManager(parentID);
      parentMeta = await dbManager.fetchMetadata();
      _appContext.setMetadata(parentID, parentMeta);
    }

    for (final siblingID in parentMeta.childrenPostIDs) {
      if (!_appContext.eventHeads.any((e) => e.id == siblingID)) {
        _appContext.addOrUpdatePostHead(await _headDbManager.fetchHead(siblingID));
      }
    }
  }
}
