import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
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
      return _buildBodyWithData(controller);
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

            return _buildBodyWithData(controller);
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

  Widget _buildBodyWithData(final quill.QuillController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: quill.QuillEditor.basic(controller: controller, readOnly: true),
    );
  }

  // * LOGIC
  Future<String> _fetchTestBody() async {
    final EventSupplementalDBManager manager = EventSupplementalDBManager(eventContext.head.id);
    return manager.fetchBody();
  }
}
