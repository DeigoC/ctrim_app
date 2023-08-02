import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class EditInfoBodyPage extends StatefulWidget {
  const EditInfoBodyPage({super.key, required this.json});
  final String json;

  @override
  State<EditInfoBodyPage> createState() => _EditInfoBodyPageState();
}

class _EditInfoBodyPageState extends State<EditInfoBodyPage> {
  late final quill.QuillController _controller;

  @override
  void initState() {
    _controller = quill.QuillController(
        document: quill.Document.fromJson(jsonDecode(widget.json.replaceAll('\n', '\\n'))),
        selection: const TextSelection.collapsed(offset: 0));
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _buildBody(),
        appBar: AppBar(title: const Text('Edit Body'), actions: [
          IconButton(
              onPressed: () {
                final rawJson = _controller.document.toDelta().toJson();
                final exampleJson = jsonEncode(rawJson);
                Clipboard.setData(ClipboardData(text: exampleJson)).then(
                    (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Json saved!'))));
                debugPrint(exampleJson);
              },
              icon: const Icon(Icons.copy_all))
        ]));
  }

  Widget _buildBody() {
    return Column(children: [
      quill.QuillToolbar.basic(
        controller: _controller,
      ),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: quill.QuillEditor.basic(
                controller: _controller,
                readOnly: false,
              )))
    ]);
  }
}
