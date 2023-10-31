import 'package:ctrim_app/utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../../utility/event_context.dart';

class EditBodyPage extends StatefulWidget {
  const EditBodyPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditBodyPage> createState() => _EditBodyPageState();
}

class _EditBodyPageState extends State<EditBodyPage> {
  late final quill.QuillController _controller;

  bool _showMultirow = false;

  @override
  void initState() {
    // String sanitisedExample = _exampleJson.replaceAll('\n', '\\n');
    // var thisJson = jsonDecode(sanitisedExample);
    // _controller = quill.QuillController(
    //     document: quill.Document.fromJson(thisJson), selection: const TextSelection.collapsed(offset: 0));
    _controller = quill.QuillController(
        document: quill.Document.fromJson(widget.eventContext.body),
        selection: const TextSelection.collapsed(offset: 0));

    _showMultirow = Provider.of<AppContext>(context, listen: false).sharedPref.showMultirowTools;

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
              actions: [IconButton(onPressed: _onSettingTap, icon: const Icon(Icons.more_vert))],
            ),
            body: _buildBody()));
  }

  Widget _buildBody() {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 0;

    return Column(
      children: [
        quill.QuillToolbar.basic(
          controller: _controller,
          showAlignmentButtons: true,
          showSubscript: false,
          showSuperscript: true,
          showCodeBlock: true,
          multiRowsDisplay: _showMultirow,
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding, vertical: 16),
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

  // * Logic

  void _onSettingTap() {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
            child: BodyWritingSettingDialog(
                initialMultirowViewValue: _showMultirow, onMultiviewClick: _onShowMultirowClick)));
  }

  void _onShowMultirowClick() {
    setState(() {
      _showMultirow = !_showMultirow;
      Provider.of<AppContext>(context, listen: false).sharedPref.setShowMultirowTools(_showMultirow);
    });
  }
}

class BodyWritingSettingDialog extends StatefulWidget {
  const BodyWritingSettingDialog({super.key, required this.initialMultirowViewValue, required this.onMultiviewClick});
  final bool initialMultirowViewValue;
  final Function() onMultiviewClick;

  @override
  State<BodyWritingSettingDialog> createState() => BodyWritingSettingDialogState();
}

class BodyWritingSettingDialogState extends State<BodyWritingSettingDialog> {
  bool _enableMultirowView = false;

  @override
  void initState() {
    _enableMultirowView = widget.initialMultirowViewValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
              title: const Text('Multi-row Toolbar View'), value: _enableMultirowView, onChanged: _multirowViewClick)
        ],
      ),
    );
  }

  // * Logic

  void _multirowViewClick(final bool newState) {
    setState(() {
      _enableMultirowView = newState;
      widget.onMultiviewClick();
    });
  }
}
