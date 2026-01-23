import 'dart:convert';

import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/widgets/quill_editor_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditInfoBodyPage extends StatefulWidget {
  const EditInfoBodyPage({super.key, required this.json});
  final List<dynamic> json;

  @override
  State<EditInfoBodyPage> createState() => _EditInfoBodyPageState();
}

class _EditInfoBodyPageState extends State<EditInfoBodyPage> {
  final GlobalKey<QuillEditorWidgetState> _editorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (_) async {
        _saveJsonToClipboard().then((_) => DialogManager.showConfirmationDialog(
            context: context, title: 'Leave?', content: 'Make sure you have copied the json!'));
        // ! broken dialog below :(
      },
      child: Scaffold(
          body: _buildBody(),
          appBar: AppBar(title: const Text('Edit Body'), actions: [
            IconButton(
                onPressed: () {
                  _saveJsonToClipboard().then(
                      (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Json saved!'))));
                },
                icon: const Icon(Icons.copy_all))
          ])),
    );
  }

  Widget _buildBody() {
    return QuillEditorWidget(
      key: _editorKey,
      jsonContent: widget.json,
      showAlignmentButtons: true,
      showSubscript: false,
      showSuperscript: true,
      showCodeBlock: true,
      multiRowsDisplay: true,
    );
  }

  Future<void> _saveJsonToClipboard() async {
    final rawJson = _editorKey.currentState?.getDocumentJson() ?? widget.json;
    final exampleJson = jsonEncode(rawJson);
    debugPrint(exampleJson);
    await Clipboard.setData(ClipboardData(text: exampleJson));
  }
}
