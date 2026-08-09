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
///
/// By default fills remaining height (`expands: true`) and scrolls inside the
/// editor — required for large pastes and phone scrolling. Use
/// [expands] `false` with [maxHeight] when embedding inside another scroll view.
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
    this.maxHeight = 420,
    this.expands = true,
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

  /// Used when [expands] is false (embedded in an outer scroll view).
  final double maxHeight;

  /// When true, fill the parent (must be under [Expanded]/[SizedBox] with a
  /// finite height) and scroll inside the editor.
  final bool expands;

  @override
  State<QuillEditorWidget> createState() => QuillEditorWidgetState();
}

class QuillEditorWidgetState extends State<QuillEditorWidget> {
  late final quill.QuillController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final document = _safeDocumentFromJson(widget.jsonContent);
    _controller = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _focusNode = FocusNode();
    _scrollController = ScrollController();

    if (widget.onDocumentChanged != null) {
      _controller.document.changes.listen((event) {
        widget.onDocumentChanged!(_controller.document.toDelta().toJson());
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Extra trailing space so the last lines can scroll above the keyboard /
    // home indicator into a comfortable edit zone on phones.
    final bottomPad = 24 +
        media.padding.bottom +
        media.viewInsets.bottom +
        (media.size.shortestSide < 600 ? 140.0 : 72.0);

    final editor = quill.QuillEditor(
      controller: _controller,
      focusNode: _focusNode,
      scrollController: _scrollController,
      config: quill.QuillEditorConfig(
        placeholder: widget.placeholder,
        padding: EdgeInsets.fromLTRB(8, 12, 8, bottomPad),
        scrollable: true,
        // Always expand into a bounded parent (Expanded or ConstrainedBox).
        expands: true,
        scrollPhysics: const ClampingScrollPhysics(),
      ),
    );

    final paddedEditor = widget.editorPadding != null
        ? Padding(padding: widget.editorPadding!, child: editor)
        : editor;

    final toolbar = quill.QuillSimpleToolbar(
      controller: _controller,
      config: quill.QuillSimpleToolbarConfig(
        showAlignmentButtons: widget.showAlignmentButtons,
        showSubscript: widget.showSubscript,
        showSuperscript: widget.showSuperscript,
        showCodeBlock: widget.showCodeBlock,
        multiRowsDisplay: widget.multiRowsDisplay,
      ),
    );

    if (widget.expands) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          toolbar,
          Expanded(child: paddedEditor),
        ],
      );
    }

    // Embedded in an outer scroll view: fixed viewport, scroll inside Quill.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        toolbar,
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: widget.minHeight,
            maxHeight: widget.maxHeight,
          ),
          child: paddedEditor,
        ),
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
