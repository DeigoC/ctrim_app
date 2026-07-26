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
    final document = _safeDocumentFromJson(jsonContent);
    final controller = quill.QuillController(
      document: document,
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

  quill.Document _safeDocumentFromJson(final List<dynamic> content) {
    try {
      return quill.Document.fromJson(content);
    } catch (_) {
      final normalized = _normalizeDelta(content);
      try {
        return quill.Document.fromJson(normalized);
      } catch (_) {
        return quill.Document.fromJson(_fallbackDelta);
      }
    }
  }

  List<dynamic> _normalizeDelta(final List<dynamic> content) {
    if (content.isEmpty) {
      return List<dynamic>.from(_fallbackDelta);
    }

    final sanitized = <dynamic>[];
    for (final op in content) {
      if (op is Map && op['insert'] is String && (op['insert'] as String).isEmpty) {
        continue;
      }
      sanitized.add(op);
    }

    if (sanitized.isEmpty) {
      return List<dynamic>.from(_fallbackDelta);
    }

    final lastOp = sanitized.last;
    if (lastOp is Map && lastOp['insert'] is String) {
      final lastInsert = (lastOp['insert'] as String);
      if (!lastInsert.endsWith('\n')) {
        sanitized.add(const <String, dynamic>{'insert': '\n'});
      }
    }

    return sanitized;
  }

  static const List<Map<String, dynamic>> _fallbackDelta = <Map<String, dynamic>>[
    <String, dynamic>{'insert': '\n'}
  ];
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
    this.placeholder,
    this.minHeight = 160,
  });

  final List<dynamic> jsonContent;
  final void Function(List<dynamic> json)? onDocumentChanged;
  final bool showAlignmentButtons;
  final bool showSubscript;
  final bool showSuperscript;
  final bool showCodeBlock;
  final bool multiRowsDisplay;
  final EdgeInsetsGeometry? editorPadding;
  final String? placeholder;
  final double minHeight;

  @override
  State<QuillEditorWidget> createState() => QuillEditorWidgetState();
}

class QuillEditorWidgetState extends State<QuillEditorWidget> {
  late final quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
    final document = _safeDocumentFromJson(widget.jsonContent);
    _controller = quill.QuillController(
      document: document,
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
    final editor = quill.QuillEditor.basic(
      controller: _controller,
      config: quill.QuillEditorConfig(
        placeholder: widget.placeholder,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        minHeight: widget.minHeight,
      ),
    );

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
                child: editor,
              )
            : editor,
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

  quill.Document _safeDocumentFromJson(final List<dynamic> content) {
    try {
      return quill.Document.fromJson(content);
    } catch (_) {
      final normalized = _normalizeDelta(content);
      try {
        return quill.Document.fromJson(normalized);
      } catch (_) {
        return quill.Document.fromJson(_fallbackDelta);
      }
    }
  }

  List<dynamic> _normalizeDelta(final List<dynamic> content) {
    if (content.isEmpty) {
      return List<dynamic>.from(_fallbackDelta);
    }

    final sanitized = <dynamic>[];
    for (final op in content) {
      if (op is Map && op['insert'] is String && (op['insert'] as String).isEmpty) {
        continue;
      }
      sanitized.add(op);
    }

    if (sanitized.isEmpty) {
      return List<dynamic>.from(_fallbackDelta);
    }

    final lastOp = sanitized.last;
    if (lastOp is Map && lastOp['insert'] is String) {
      final lastInsert = (lastOp['insert'] as String);
      if (!lastInsert.endsWith('\n')) {
        sanitized.add(const <String, dynamic>{'insert': '\n'});
      }
    }

    return sanitized;
  }

  static const List<Map<String, dynamic>> _fallbackDelta = <Map<String, dynamic>>[
    <String, dynamic>{'insert': '\n'}
  ];
}
