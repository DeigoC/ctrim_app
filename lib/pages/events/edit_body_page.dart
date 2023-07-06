import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../utility/event_context.dart';

class EditBodyPage extends StatefulWidget {
  const EditBodyPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditBodyPage> createState() => _EditBodyPageState();
}

class _EditBodyPageState extends State<EditBodyPage> {
  late final quill.QuillController _controller;

  @override
  void initState() {
    // String sanitisedExample = _exampleJson.replaceAll('\n', '\\n');
    // var thisJson = jsonDecode(sanitisedExample);
    // _controller = quill.QuillController(
    //     document: quill.Document.fromJson(thisJson), selection: const TextSelection.collapsed(offset: 0));
    _controller = quill.QuillController(
        document: quill.Document.fromJson(widget.eventContext.body),
        selection: const TextSelection.collapsed(offset: 0));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ! This isn't perfect? Remember that the user can add empty lines
        if (!widget.eventContext.isSameJson(_controller.document.toDelta().toJson())) {
          widget.eventContext.setBodyJson(_controller.document.toDelta().toJson());
          widget.eventContext.allowSavingOfTheEdit();
        }

        return true;
      },
      child: Scaffold(
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
      ),
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
    // var path = await getApplicationDocumentsDirectory();
    // var file = File('${path.path}/someTest.txt');
    // final rawJson = _controller.document.toDelta().toJson();
    // final _exampleJson = jsonEncode(rawJson);
    // debugPrint(_exampleJson);
    // debugPrint('The example json encoded looks like $_exampleJson');
    // EventDBManager eventDBManager = EventDBManager('1');
    // eventDBManager.addBody(rawJson);

    // await file.writeAsString(_exampleJson);
    // debugPrint('Size is ${await file.length()}');
  }
}
