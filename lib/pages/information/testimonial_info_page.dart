import 'package:ctrim_app/models/info/testimonial_into.dart';
import 'package:ctrim_app/pages/information/edit_info_body_page.dart';
import 'package:ctrim_app/widgets/quill_editor_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class TestimonialInfoPage extends StatelessWidget {
  const TestimonialInfoPage({super.key, required String jsonPath, required String initialImageSrc})
      : _jsonPath = jsonPath,
        _initialImageSrc = initialImageSrc;
  final String _jsonPath, _initialImageSrc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(slivers: [
      const SliverAppBar(floating: true, snap: true, title: Text('Testimonial')),
      SliverToBoxAdapter(
          child: SingleChildScrollView(
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Hero(
            tag: 'initialTestimonialImage_$_initialImageSrc',
            child: Image.asset(_initialImageSrc, height: MediaQuery.of(context).size.height * 0.4, fit: BoxFit.cover),
          ),
          FutureBuilder(
              future: _loadJson(),
              builder: (_, snapshot) {
                Widget result = const Center(child: CircularProgressIndicator());
                if (snapshot.hasData) {
                  result = _buildBodyWithData(context, snapshot.data);
                } else if (snapshot.hasError) {
                  result = Center(child: Text("Something went wrong: ${snapshot.error}"));
                }
                return result;
              }),
        ],
      )))
    ]));
  }

  Widget _buildBodyWithData(final BuildContext context, final Map<String, dynamic> data) {
    final TestimonialInfo testimonialInfo = TestimonialInfo(data);

    List<Widget> children = [
      Text(testimonialInfo.name, style: const TextStyle(fontSize: 32)),
      Text(testimonialInfo.church, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 8),
      const Divider(),
      const SizedBox(height: 8),
      Flexible(child: QuillViewerWidget(jsonContent: testimonialInfo.body)),
      const SizedBox(height: 32)
    ];

    if (kDebugMode) {
      children.insert(
          0,
          ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => EditInfoBodyPage(json: testimonialInfo.body))),
              icon: const Icon(Icons.edit),
              label: const Text("Edit Body")));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Future<dynamic> _loadJson() async {
    final String response = await rootBundle.loadString(_jsonPath);
    final data = await json.decode(response);
    return data;
  }
}
