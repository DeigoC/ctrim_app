import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/event/event_metadata.dart';
import '../../utility/app_context.dart';
import '../../utility/event_context.dart';
import 'post_head.dart';

class ViewRelatedPostsTab extends StatefulWidget {
  const ViewRelatedPostsTab({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<ViewRelatedPostsTab> createState() => _ViewRelatedPostsTabState();
}

enum RelatedPostFilter { all, parent, siblings, children }

class _ViewRelatedPostsTabState extends State<ViewRelatedPostsTab> {
  late final AppContext _appContext;
  final EventHeadDBManager _headDbManager = EventHeadDBManager();
  RelatedPostFilter _currentFilter = RelatedPostFilter.all;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: SafeArea(
        top: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (widget.eventContext.metadata.hasParent || widget.eventContext.metadata.hasChildren) _buildFilterSection(),
          Expanded(child: _buildBody())
        ]),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.eventContext.metadata.hasParent || widget.eventContext.metadata.hasChildren) {
      return _buildRelatedFB();
    }

    // Empty state with better design
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No related posts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
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

  Widget _buildFilterSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFilterChip(
              label: 'All',
              icon: Icons.view_list,
              filter: RelatedPostFilter.all,
              colorScheme: colorScheme,
            ),
            if (widget.eventContext.metadata.hasParent) ...[
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Parent',
                icon: Icons.arrow_upward,
                filter: RelatedPostFilter.parent,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Siblings',
                icon: Icons.compare_arrows,
                filter: RelatedPostFilter.siblings,
                colorScheme: colorScheme,
              ),
            ],
            if (widget.eventContext.metadata.hasChildren) ...[
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Children',
                icon: Icons.arrow_downward,
                filter: RelatedPostFilter.children,
                colorScheme: colorScheme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required RelatedPostFilter filter,
    required ColorScheme colorScheme,
  }) {
    final bool isSelected = _currentFilter == filter;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilter = filter;
        });
      },
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outline,
        width: 1,
      ),
    );
  }

  Widget _buildBodyWithData() {
    final List<PostHead> relatedPosts = _getFilteredPosts();

    if (relatedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts in this category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
        separatorBuilder: (context, index) => const Divider(),
        itemCount: relatedPosts.length,
        itemBuilder: (_, index) => relatedPosts[index]);
  }

  List<PostHead> _getFilteredPosts() {
    switch (_currentFilter) {
      case RelatedPostFilter.all:
        return _getAllPosts();
      case RelatedPostFilter.parent:
        return widget.eventContext.metadata.hasParent ? [_getParentPostHead()] : [];
      case RelatedPostFilter.siblings:
        return _getSiblingPosts();
      case RelatedPostFilter.children:
        return _buildChildrenPosts();
    }
  }

  List<PostHead> _getAllPosts() {
    final List<PostHead> relatedPosts = List.empty(growable: true);

    relatedPosts.addAll(_buildChildrenPosts());
    if (widget.eventContext.metadata.hasParent) {
      relatedPosts.addAll(_getSiblingPosts());
      relatedPosts.add(_getParentPostHead());
    }

    return relatedPosts;
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

  // this is going to be a major method to fetch all the data needed
  // parent post + meta, sibling posts, children posts - all if needed
  Future<bool> _fetchAllRelatedPosts() async {
    final String? parentID = widget.eventContext.metadata.parentID;

    // fetch parent + siblings
    if (parentID != null) {
      // fetch parent head
      if (!_appContext.eventHeads.any((e) => e.id == parentID)) {
        _appContext.addOrUpdatePostHead(await _headDbManager.fetchHead(parentID));
      }

      // fetch the parent metadata
      if (_appContext.getMetadata(parentID) == null) {
        debugPrint('fetching parent');
        final EventSupplementalDBManager dbManager = EventSupplementalDBManager(parentID);
        _appContext.setMetadata(parentID, await dbManager.fetchMetadata());
      }

      // fetch siblings - we know for sure that we have the parent meta
      await _getSiblingPostID(_appContext.getMetadata(parentID)!);
    }

    // fetch children
    for (final childrenID in widget.eventContext.metadata.childrenPostIDs) {
      if (!_appContext.eventHeads.any((e) => e.id == childrenID)) {
        _appContext.addOrUpdatePostHead(await _headDbManager.fetchHead(childrenID));
      }
    }

    return true;
  }

  Future<void> _getSiblingPostID(final EventMetadata parentMeta) async {
    for (final siblingID in parentMeta.childrenPostIDs) {
      if (!_appContext.eventHeads.any((e) => e.id == siblingID)) {
        _appContext.addOrUpdatePostHead(await _headDbManager.fetchHead(siblingID));
      }
    }
  }
}
