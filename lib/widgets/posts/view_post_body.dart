import 'dart:convert';

import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class ViewPostBody extends StatefulWidget {
  const ViewPostBody({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<ViewPostBody> createState() => _ViewPostBodyState();
}

class _ViewPostBodyState extends State<ViewPostBody> {
  late final quill.QuillController _controller;

  @override
  void initState() {
    if (widget.eventContext.haveFetchedBody) {
      _controller = quill.QuillController(
          document: quill.Document.fromJson(jsonDecode(widget.eventContext.body.json!.replaceAll('\n', '\\n'))),
          selection: const TextSelection.collapsed(offset: 0));
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eventContext.haveFetchedBody) {
      return _buildBodyWithData();
    }
    return _buildFB();
  }

  Widget _buildFB() {
    return FutureBuilder<String>(
        future: _fetchTestBody(),
        builder: (_, snap) {
          if (snap.hasData) {
            widget.eventContext.body.setJson(snap.data!);
            widget.eventContext.flagFetchedBody();

            _controller = quill.QuillController(
                document: quill.Document.fromJson(jsonDecode(widget.eventContext.body.json!.replaceAll('\n', '\\n'))),
                selection: const TextSelection.collapsed(offset: 0));

            return _buildBodyWithData();
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

  Widget _buildBodyWithData() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: quill.QuillEditor.basic(controller: _controller, readOnly: true),
    );
  }

  // * LOGIC
  Future<String> _fetchTestBody() async {
    const String json = '[{"insert":"Hello, this is from fetching!\n"}]';
    await Future.delayed(const Duration(seconds: 1));
    return json;
  }
}
