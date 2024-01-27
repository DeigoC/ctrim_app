import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../../utility/app_context.dart';

class SimpleInfoPage extends StatelessWidget {
  const SimpleInfoPage({super.key, required String jsonPath}) : _jsonPath = jsonPath;
  final String _jsonPath;

  @override
  Widget build(BuildContext context) {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 5 : 8;

    return Scaffold(
        body: CustomScrollView(slivers: [
      // const SliverAppBar(actions: [InfoAction(json: _json)], floating: true, snap: true),
      const SliverAppBar(floating: true, snap: true),
      SliverToBoxAdapter(
          child: SingleChildScrollView(
              child: FutureBuilder(
                  future: _loadJson(),
                  builder: (_, snapshot) {
                    Widget result = const Center(child: CircularProgressIndicator());
                    if (snapshot.hasData) {
                      result = _buildBodyWithData(webHorizontalPadding, context, snapshot.data);
                    } else if (snapshot.hasError) {
                      result = Center(child: Text("Something went wrong: ${snapshot.error}"));
                    }
                    return result;
                  })))
    ]));
  }

  Widget _buildBodyWithData(
      final double webHorizontalPadding, final BuildContext context, final Map<String, dynamic> json) {
    final quill.QuillController controller = quill.QuillController(
        document: quill.Document.fromJson(json['data']), selection: const TextSelection.collapsed(offset: 0));
    Provider.of<AppContext>(context, listen: false).analytics.setCurrentScreen(screenName: json['analyticTitle']);

    return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: webHorizontalPadding),
        child: quill.QuillProvider(
          configurations: quill.QuillConfigurations(controller: controller),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
                child: quill.QuillEditor.basic(configurations: const quill.QuillEditorConfigurations(readOnly: true))),
            const SizedBox(height: 32)
          ]),
        ));
  }

  Future<dynamic> _loadJson() async {
    final String response = await rootBundle.loadString(_jsonPath);
    final data = await json.decode(response);
    return data;
  }
}
