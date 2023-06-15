import 'dart:convert';

import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class EventBodyView extends StatefulWidget {
  const EventBodyView({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EventBodyView> createState() => _EventBodyViewState();
}

class _EventBodyViewState extends State<EventBodyView> {
  late final quill.QuillController _controller;

  @override
  void initState() {
    if (widget.eventContext.haveFetchedBody) {
      _controller = quill.QuillController(
          document: quill.Document.fromJson(jsonDecode(widget.eventContext.eventBody.json.replaceAll('\n', '\\n'))),
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
            widget.eventContext.setJson(snap.data!);
            widget.eventContext.flagFetchedBody();

            _controller = quill.QuillController(
                document:
                    quill.Document.fromJson(jsonDecode(widget.eventContext.eventBody.json.replaceAll('\n', '\\n'))),
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
    return quill.QuillEditor.basic(controller: _controller, readOnly: true);
  }

  // * LOGIC
  Future<String> _fetchTestBody() async {
    const String json = '[{"insert":"Hello, time to start writing!\n"}]';
    await Future.delayed(const Duration(seconds: 1));
    return json;
  }
}
