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

    final double webHorizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 0);

    return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
        itemCount: postIDs.length,
        itemBuilder: (_, index) {
          final thisHead = _appContext.getPostHead(postIDs[index]);
          return PostHead(
              thisHead: thisHead,
              updatePost: () {
                setState(() {});
              });
        });
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
