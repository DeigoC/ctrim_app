import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/user_schedule_service.dart';
import '../../widgets/two_column_masonry.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/posts/post_head.dart';

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
      final posts =
          await _scheduleService.fetchPosts(_appContext.currentUser.id);
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
      appBar: AppBar(title: const Text('My Posts'), actions: [
        IconButton(onPressed: _onHelpClick, icon: const Icon(Icons.help))
      ]),
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
        final bool isWideScreen = ResponsiveLayout.isWideScreenOf(context);
        final double horizontalPadding = isWideScreen
            ? ((contentWidth - ResponsiveLayout.maxContentWidth(contentWidth)) /
                    2)
                .clamp(16.0, double.infinity)
            : 8.0;
        final padding =
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8);

        if (!isWideScreen) {
          return ListView.separated(
            padding: padding,
            itemCount: postIDs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) => _buildPostCard(postIDs[index]),
          );
        }

        return SingleChildScrollView(
          padding: padding,
          child: TwoColumnMasonry(
            children: [
              for (final id in postIDs) _buildPostCard(id),
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
        context: context,
        title: 'My Posts Page',
        content: 'Recent posts that you can edit will show in this page');
  }

  Future<void> _pruneStalePosts() async {
    await _scheduleService.pruneStalePostInvolvements(
      user: _appContext.currentUser,
      eventHeads: _appContext.eventHeads,
    );
  }
}
