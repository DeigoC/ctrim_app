import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/utility/user_schedule_service.dart';
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

  @override
  void initState() {
    _appContext = Provider.of(context, listen: false);
    super.initState();
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
    if (_appContext.currentUser.posts == null) {
      return _buildFBBody();
    }
    return _buildBodyWithData();
  }

  Widget _buildFBBody() {
    return FutureBuilder(
        future: _scheduleService.fetchPosts(_appContext.currentUser.id),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator.adaptive());

          if (snap.hasData) {
            _appContext.currentUser.setPosts(snap.data!);
            result = _buildBodyWithData();
            WidgetsBinding.instance.addPostFrameCallback((_) => _pruneStalePosts());
          } else if (snap.hasError) {
            result = Center(child: Text('Something went wrong!\n\n${snap.error}'));
          }

          return result;
        });
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
        thisHead: _appContext.getPostHead(postID),
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
