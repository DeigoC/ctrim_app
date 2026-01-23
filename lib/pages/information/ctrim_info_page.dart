import 'package:ctrim_app/models/info/ctrim_info.dart';
import 'package:ctrim_app/pages/information/edit_info_body_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../widgets/quill_editor_wrapper.dart';

class CTRIMInfoPage extends StatelessWidget {
  const CTRIMInfoPage({super.key, required String jsonPath}) : _jsonPath = jsonPath;
  final String _jsonPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(slivers: [
      const SliverAppBar(floating: true, snap: true),
      SliverToBoxAdapter(
          child: SingleChildScrollView(
              child: FutureBuilder(
                  future: _loadJson(),
                  builder: (_, snapshot) {
                    Widget result = const Center(child: CircularProgressIndicator());
                    if (snapshot.hasData) {
                      result = _buildBodyWithData(context, snapshot.data);
                    } else if (snapshot.hasError) {
                      result = Center(child: Text("Something went wrong: ${snapshot.error}"));
                    }
                    return result;
                  })))
    ]));
  }

  Widget _buildBodyWithData(final BuildContext context, final Map<String, dynamic> data) {
    final CtrimInfo ctrimInfo = CtrimInfo(data);

    List<Widget> children = [
      const Divider(),
      const SizedBox(height: 8),
      Flexible(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: QuillEditorWidget(
                jsonContent: ctrimInfo.body,
                showAlignmentButtons: true,
                showSubscript: false,
                showSuperscript: true,
                showCodeBlock: true,
                multiRowsDisplay: false,
                editorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              ))),
      const SizedBox(height: 32)
    ];

    if (kDebugMode) {
      children.insert(
          0,
          ElevatedButton.icon(
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EditInfoBodyPage(json: ctrimInfo.body))),
              icon: const Icon(Icons.edit),
              label: const Text("Edit Body")));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Future<dynamic> _loadJson() async {
    final String response = await rootBundle.loadString(_jsonPath);
    final data = await json.decode(response);
    return data;
  }
}
