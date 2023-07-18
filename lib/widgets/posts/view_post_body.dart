import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../../firebase/db_managers/event_db_manager.dart';
import '../../utility/event_context.dart';

class ViewPostBody extends StatelessWidget {
  const ViewPostBody({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  Widget build(BuildContext context) {
    if (eventContext.haveFetchedBody) {
      final quill.QuillController controller = quill.QuillController(
          document: quill.Document.fromJson(eventContext.body), selection: const TextSelection.collapsed(offset: 0));
      return _buildBodyWithData(controller, context);
    }
    return _buildFB();
  }

  Widget _buildFB() {
    return FutureBuilder<String>(
        future: _fetchTestBody(),
        builder: (_, snap) {
          if (snap.hasData) {
            eventContext.setFetchedBody(snap.data!);

            final quill.QuillController controller = quill.QuillController(
                document: quill.Document.fromJson(eventContext.body),
                selection: const TextSelection.collapsed(offset: 0));

            return _buildBodyWithData(controller, _);
          } else if (snap.hasError) {
            return const Center(
              child: Text('Something went wrong :('),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }

  Widget _buildBodyWithData(final quill.QuillController controller, BuildContext context) {
    final thisUser = Provider.of<AppContext>(context).currentUser; // ! This should be the author
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const Divider(),
              ListTile(
                title: Text(thisUser.fullname),
                leading: MyUserAvatar(thisUser),
                subtitle: const Text('Author'),
                onTap: () => DialogManager.showUserProfile(selectedUser: thisUser, context: context),
              ),
              const Divider(),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: quill.QuillEditor.basic(controller: controller, readOnly: true),
          ),
        )
      ],
    );
  }

  // * LOGIC
  Future<String> _fetchTestBody() async {
    final EventSupplementalDBManager manager = EventSupplementalDBManager(eventContext.head.id);
    return manager.fetchBody();
  }
}
