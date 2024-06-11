import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utility/app_context.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

// TODO make this class more generic to accomodate different churches via json files
class BelfastChurchPage extends StatelessWidget {
  const BelfastChurchPage({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<AppContext>(context, listen: false).analytics.logScreenView(screenName: 'Church Info: Belfast');
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 5 : 0;

    return Scaffold(
        appBar: AppBar(title: const Text('Belfast')),
        body: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
                child: FutureBuilder(
                  future: _loadJson(),
                  builder: (context, snapshot) {
                    Widget result = const Center(child: CircularProgressIndicator());
                    if (snapshot.hasData) {
                      result = _buildBodyWithData(webHorizontalPadding, context, snapshot.data);
                    } else if (snapshot.hasError) {
                      result = Center(child: Text("Something went wrong: ${snapshot.error}"));
                    }

                    return result;
                  },
                ))));
  }

  Widget _buildBodyWithData(final double webHorizontalPadding, final BuildContext context, final List<dynamic> data) {
    final quill.QuillController controller = quill.QuillController(
        document: quill.Document.fromJson(data), selection: const TextSelection.collapsed(offset: 0));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/bel2.jpg',
          height: webHorizontalPadding != 0 ? MediaQuery.of(context).size.height * 0.45 : null,
        ),
        const SizedBox(height: 8),
        Flexible(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: quill.QuillEditor.basic(
                    configurations: quill.QuillEditorConfigurations(controller: controller, readOnly: true)))),
        const SizedBox(height: 32)
      ],
    );
  }

  Future<dynamic> _loadJson() async {
    final String response = await rootBundle.loadString('assets/info/belfast_church.json');
    final data = await json.decode(response);
    return data;
  }
}
