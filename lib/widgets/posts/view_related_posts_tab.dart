import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:ctrim_app/widgets/posts/post_head.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewRelatedPostsTab extends StatefulWidget {
  const ViewRelatedPostsTab({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<ViewRelatedPostsTab> createState() => _ViewRelatedPostsTabState();
}

class _ViewRelatedPostsTabState extends State<ViewRelatedPostsTab> {
  late final AppContext _appContext;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: _buildBody()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: ElevatedButton.icon(
              onPressed: _onCreatePost, icon: const Icon(Icons.post_add), label: const Text('Create Related Post')),
        )
      ]),
    );
  }

  Widget _buildBody() {
    if (widget.eventContext.metadata.hasParent || widget.eventContext.metadata.hasChildren) {
      return CustomScrollView(slivers: _buildScrollChildren());
    }
    return const Center(child: Text('No related posts'));
  }

  List<Widget> _buildScrollChildren() {
    final List<Widget> results = List.empty(growable: true);

    if (widget.eventContext.metadata.hasParent) {
      results.add(_buildParentPost());
    }

    if (widget.eventContext.metadata.hasChildren) {
      results.addAll(_buildPostChildren());
    }

    return results;
  }

  Widget _buildParentPost() {
    // remember that this parent may not exist so we have to fetch and add via FB
    final thisParent =
        _appContext.eventHeads.firstWhere((e) => e.id.compareTo(widget.eventContext.metadata.parentID!) == 0);
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // const Text('Parent Post'),
          // kinda wacky logic here
          // so if we came from the parent post looking at a child post and see this post
          // clicking this parent should pop the page back to the parent as opposed to pushing
          // another page, hence the 'childToParent' field
          PostHead(thisHead: thisParent, childToParent: widget.eventContext.isViewingChild)
          // const SizedBox(height: 16),
          // const Divider()
        ],
      ),
    );
  }

  List<Widget> _buildPostChildren() {
    final childrenHeads =
        _appContext.eventHeads.where((head) => widget.eventContext.metadata.children.contains(head.id)).toList();
    return [
      // const SliverToBoxAdapter(
      //     child: Column(
      //   crossAxisAlignment: CrossAxisAlignment.center,
      //   children: [
      //     Divider(),
      //     Padding(
      //         padding: EdgeInsets.only(left: 8.0),
      //         child: Text('Children Posts', style: TextStyle(fontSize: 16, decoration: TextDecoration.underline))),
      //     Divider(),
      //   ],
      // )),
      SliverList.separated(
          itemCount: childrenHeads.length,
          itemBuilder: (_, index) => PostHead(
                thisHead: childrenHeads[index],
                viewingChild: true,
              ),
          separatorBuilder: (_, index) => const Divider())
    ];
  }

  // * Logic

  void _onCreatePost() {}
}
