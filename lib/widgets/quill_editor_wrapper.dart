import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// A wrapper widget for QuillEditor in read-only mode.
/// Use this for displaying quill content without editing capabilities.
class QuillViewerWidget extends StatelessWidget {
  const QuillViewerWidget({
    super.key,
    required this.jsonContent,
    this.padding,
    this.locale = const Locale('en'),
  });

  final List<dynamic> jsonContent;
  final EdgeInsetsGeometry? padding;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final controller = quill.QuillController(
      document: quill.Document.fromJson(jsonContent),
      selection: const TextSelection.collapsed(offset: 0),
    );

    final editor = quill.QuillEditor.basic(
      controller: controller,
    );

    if (padding != null) {
      return Padding(
        padding: padding!,
        child: editor,
      );
    }

    return editor;
  }
}

/// A wrapper widget for QuillEditor with editing capabilities.
/// Includes toolbar and editor in a Column layout.
class QuillEditorWidget extends StatefulWidget {
  const QuillEditorWidget({
    super.key,
    required this.jsonContent,
    this.onDocumentChanged,
    this.showAlignmentButtons = true,
    this.showSubscript = false,
    this.showSuperscript = true,
    this.showCodeBlock = true,
    this.multiRowsDisplay = true,
    this.editorPadding,
  });

  final List<dynamic> jsonContent;
  final void Function(List<dynamic> json)? onDocumentChanged;
  final bool showAlignmentButtons;
  final bool showSubscript;
  final bool showSuperscript;
  final bool showCodeBlock;
  final bool multiRowsDisplay;
  final EdgeInsetsGeometry? editorPadding;

  @override
  State<QuillEditorWidget> createState() => QuillEditorWidgetState();
}

class QuillEditorWidgetState extends State<QuillEditorWidget> {
  late final quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController(
      document: quill.Document.fromJson(widget.jsonContent),
      selection: const TextSelection.collapsed(offset: 0),
    );

    if (widget.onDocumentChanged != null) {
      _controller.document.changes.listen((event) {
        widget.onDocumentChanged!(_controller.document.toDelta().toJson());
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        quill.QuillSimpleToolbar(
          controller: _controller,
          config: quill.QuillSimpleToolbarConfig(
            showAlignmentButtons: widget.showAlignmentButtons,
            showSubscript: widget.showSubscript,
            showSuperscript: widget.showSuperscript,
            showCodeBlock: widget.showCodeBlock,
            multiRowsDisplay: widget.multiRowsDisplay,
          ),
        ),
        widget.editorPadding != null
            ? Padding(
                padding: widget.editorPadding!,
                child: quill.QuillEditor.basic(controller: _controller),
              )
            : quill.QuillEditor.basic(controller: _controller),
      ],
    );
  }

  /// Get the current document as JSON
  List<dynamic> getDocumentJson() {
    return _controller.document.toDelta().toJson();
  }

  /// Get the document as plain text
  String getPlainText() {
    return _controller.document.toPlainText();
  }

  /// Exposes the controller for advanced use cases
  quill.QuillController get controller => _controller;
}
