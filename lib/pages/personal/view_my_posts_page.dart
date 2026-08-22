import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/utility/user_schedule_service.dart';
import 'package:ctrim_app/widgets/load_progress_body.dart';
import 'package:ctrim_app/widgets/posts/post_head.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utility/responsive_layout.dart';

class ViewMyPostsPage extends StatefulWidget {
  const ViewMyPostsPage({super.key});
  @override
  State<ViewMyPostsPage> createState() => _ViewMyPostsPageState();
}

class _ViewMyPostsPageState extends State<ViewMyPostsPage> {
  late final AppContext _appContext;
  final UserScheduleService _scheduleService = UserScheduleService();

  bool _loading = false;
  Object? _loadError;
  String _statusMessage = 'Loading posts…';
  int _completedSteps = 0;
  int _totalSteps = 2;

  @override
  void initState() {
    _appContext = Provider.of(context, listen: false);
    super.initState();
    if (_appContext.currentUser.posts == null) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadPosts();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pruneStalePosts());
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _statusMessage = 'Fetching posts…';
      _completedSteps = 0;
      _totalSteps = 2;
    });

    try {
      final posts = await _scheduleService.fetchPosts(_appContext.currentUser.id);
      if (!mounted) return;

      setState(() {
        _completedSteps = 1;
        _statusMessage = 'Cleaning up posts…';
      });

      _appContext.currentUser.setPosts(posts);
      await _pruneStalePosts();
      if (!mounted) return;

      setState(() {
        _loading = false;
        _completedSteps = 2;
        _statusMessage = 'Done';
      });
    } catch (e, st) {
      debugPrint('Error fetching my posts: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('My Posts'), actions: [IconButton(onPressed: _onHelpClick, icon: const Icon(Icons.help))]),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading || _loadError != null) {
      return LoadProgressBody(
        message: _statusMessage,
        completedSteps: _completedSteps,
        totalSteps: _totalSteps,
        error: _loadError,
        errorTitle: 'Could not load posts',
        onRetry: _loadPosts,
      );
    }

    if (_appContext.currentUser.posts == null) {
      return LoadProgressBody(
        message: 'Loading posts…',
        completedSteps: 0,
        totalSteps: 1,
        onRetry: _loadPosts,
      );
    }

    return _buildBodyWithData();
  }

  Widget _buildBodyWithData() {
    final List<String> postIDs = _appContext.currentUser.posts!
        .where((e) => _appContext.eventHeads.any((head) => head.id == e.postID))
        .map((e) => e.postID)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double contentWidth = constraints.maxWidth;
        final bool isWideScreen = ResponsiveLayout.isWideScreen(contentWidth);
        final double horizontalPadding = isWideScreen
            ? ((contentWidth - ResponsiveLayout.maxContentWidth(contentWidth)) / 2)
                .clamp(16.0, double.infinity)
            : 8.0;

        if (!isWideScreen) {
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
            itemCount: postIDs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) => _buildPostCard(postIDs[index]),
          );
        }

        final left = <String>[];
        final right = <String>[];
        for (var i = 0; i < postIDs.length; i++) {
          (i.isEven ? left : right).add(postIDs[i]);
        }

        Widget column(List<String> ids) {
          return Column(
            children: [
              for (var i = 0; i < ids.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _buildPostCard(ids[i]),
              ],
            ],
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: column(left)),
              const SizedBox(width: 16),
              Expanded(child: column(right)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostCard(String postID) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PostHead(
        thisHead: _appContext.headById(postID)!,
        updatePost: () {
          setState(() {});
        },
      ),
    );
  }

  void _onHelpClick() {
    DialogManager.showAlertDialog(
        context: context, title: 'My Posts Page', content: 'Recent posts that you can edit will show in this page');
  }

  Future<void> _pruneStalePosts() async {
    await _scheduleService.pruneStalePostInvolvements(
      user: _appContext.currentUser,
      eventHeads: _appContext.eventHeads,
    );
  }
}
