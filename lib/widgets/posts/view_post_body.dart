import 'package:ctrim_app/pages/events/edit_body_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../firebase/db_managers/event_db_manager.dart';
import '../../utility/event_context.dart';

class ViewPostBody extends StatelessWidget {
  const ViewPostBody({super.key, required this.eventContext, required this.updateBody, required this.currentUID});
  final EventContext eventContext;
  final Function updateBody;
  final String currentUID;

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
    final List<Widget> children = [
      Expanded(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: quill.QuillEditor.basic(controller: controller, readOnly: true)))
    ];

    if (eventContext.isCurrentUserContributor(currentUID) || eventContext.isCurrentUserAuthor(currentUID)) {
      children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: ElevatedButton.icon(
              onPressed: () => _onEditBodyClick(context),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Text'))));
    }

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // * LOGIC
  Future<String> _fetchTestBody() async {
    final EventSupplementalDBManager manager = EventSupplementalDBManager(eventContext.head.id);
    return manager.fetchBody();
  }

  void _onEditBodyClick(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditBodyPage(eventContext: eventContext))).then((_) {
      updateBody();
    });
  }
}
