import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:path_provider/path_provider.dart';

class EditBodyPage extends StatefulWidget {
  const EditBodyPage({super.key});

  @override
  State<EditBodyPage> createState() => _EditBodyPageState();
}

class _EditBodyPageState extends State<EditBodyPage> {
  late final quill.QuillController _controller;
  String _exampleJson = '[{"insert":"Hello, time to start writing!\n"}]';

  @override
  void initState() {
    String sanitisedExample = _exampleJson.replaceAll('\n', '\\n');
    var thisJson = jsonDecode(sanitisedExample);
    _controller = quill.QuillController(
        document: quill.Document.fromJson(thisJson), selection: const TextSelection.collapsed(offset: 0));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Body'),
        actions: [
          IconButton(
              onPressed: () {
                // var json = jsonEncode(_controller.document.toDelta().toJson());
                // debugPrint(json);
                _getSizeOfText();
              },
              icon: const Icon(Icons.save))
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        quill.QuillToolbar.basic(
          controller: _controller,
          multiRowsDisplay: false,
          // embedButtons: FlutterQuillEmbeds.buttons(showCameraButton: false),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: quill.QuillEditor.basic(
              // embedBuilders: FlutterQuillEmbeds.builders(),
              controller: _controller,
              readOnly: false, // true for view only mode
            ),
          ),
        )
      ],
    );
  }

  _getSizeOfText() async {
    var path = await getApplicationDocumentsDirectory();
    var file = File('${path.path}/someTest.txt');
    _exampleJson = jsonEncode(_controller.document.toDelta().toJson());
    debugPrint('The example json looks like $_exampleJson');
    await file.writeAsString(_exampleJson);
    debugPrint('Size is ${await file.length()}');
  }
}
