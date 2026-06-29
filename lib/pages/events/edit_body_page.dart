import 'dart:convert';

import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/widgets/quill_editor_wrapper.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utility/event_context.dart';
import '../../utility/responsive_layout.dart';

class EditBodyPage extends StatefulWidget {
  const EditBodyPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditBodyPage> createState() => _EditBodyPageState();
}

class _EditBodyPageState extends State<EditBodyPage> {
  final GlobalKey<QuillEditorWidgetState> _editorKey = GlobalKey();

  bool _showMultirow = false;

  @override
  void initState() {
    _showMultirow = Provider.of<AppContext>(context, listen: false).sharedPref.showMultirowTools;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        onPopInvoked: (popped) {
          // ! This isn't perfect? Remember that the user can add empty lines
          final currentJson = _editorKey.currentState?.getDocumentJson();
          if (currentJson != null && !widget.eventContext.isSameJson(currentJson)) {
            widget.eventContext.setBodyJson(currentJson);
            widget.eventContext.allowSavingOfTheEdit();
          }
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
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 8);

    return QuillEditorWidget(
      key: _editorKey,
      jsonContent: widget.eventContext.body,
      showAlignmentButtons: true,
      showSubscript: false,
      showSuperscript: true,
      showCodeBlock: true,
      multiRowsDisplay: _showMultirow,
      editorPadding: EdgeInsets.symmetric(horizontal: webHorizontalPadding, vertical: 16),
    );
  }

  // * Logic

  void _onSettingTap() {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
                child: BodyWritingSettingDialog(
              initialMultirowViewValue: _showMultirow,
              onMultiviewClick: _onShowMultirowClick,
              onCopyClick: _onCopyClick,
            )));
  }

  void _onShowMultirowClick() {
    setState(() {
      _showMultirow = !_showMultirow;
      Provider.of<AppContext>(context, listen: false).sharedPref.setShowMultirowTools(_showMultirow);
    });
  }

  void _onCopyClick() {
    final rawJson = _editorKey.currentState?.getDocumentJson() ?? widget.eventContext.body;
    final exampleJson = jsonEncode(rawJson);
    Clipboard.setData(ClipboardData(text: exampleJson));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied Json'), behavior: SnackBarBehavior.floating));
  }
}

class BodyWritingSettingDialog extends StatefulWidget {
  const BodyWritingSettingDialog(
      {super.key, required this.initialMultirowViewValue, required this.onMultiviewClick, required this.onCopyClick});
  final bool initialMultirowViewValue;
  final Function() onMultiviewClick, onCopyClick;

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
              title: const Text('Multi-row Toolbar View'), value: _enableMultirowView, onChanged: _multirowViewClick),
          ListTile(title: const Text('Copy JSON Data'), onTap: _copyBodyDataClick)
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

  void _copyBodyDataClick() {
    widget.onCopyClick();
  }
}
