import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/info/church_info.dart';
import '../../utility/app_context.dart';
import '../../widgets/media/cached_image_widget.dart';

import '../../widgets/quill_editor_wrapper.dart';
import 'edit_info_body_page.dart';

class ChurchInfoPage extends StatelessWidget {
  const ChurchInfoPage({super.key, required String jsonPath, required String imageSrc})
      : _jsonPath = jsonPath,
        _initialImageSrc = imageSrc;
  final String _jsonPath, _initialImageSrc;

  @override
  Widget build(BuildContext context) {
    Provider.of<AppContext>(context, listen: false).analytics.logScreenView(screenName: 'Church Info: Belfast');

    return Scaffold(
        appBar: AppBar(title: const Text('Belfast')),
        body: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CachedImageWidget(
              imageUrl: _initialImageSrc,
              height: MediaQuery.of(context).size.height * 0.4,
              fit: BoxFit.cover,
              heroTag: 'initialChurchImage_$_initialImageSrc',
            ),
            FutureBuilder(
              future: _loadJson(),
              builder: (context, snapshot) {
                Widget result = const Center(child: CircularProgressIndicator());
                if (snapshot.hasData) {
                  result = _buildBodyWithData(context, snapshot.data);
                } else if (snapshot.hasError) {
                  result = Center(child: Text('Something went wrong: ${snapshot.error}'));
                }

                return result;
              },
            ),
          ],
        )));
  }

  Widget _buildBodyWithData(final BuildContext context, final Map<String, dynamic> data) {
    final ChurchInfo ctrimInfo = ChurchInfo(data);

    List<Widget> children = [
      const SizedBox(height: 8),
      Flexible(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: QuillViewerWidget(jsonContent: ctrimInfo.body))),
      const SizedBox(height: 16),
      // TODO: Replace with actual image URL from backend
      // Original asset reference: ctrimInfo.imgSrc
      CachedImageWidget(
        imageUrl: ctrimInfo.imgSrc, // TODO: Replace with actual download URL
        width: double.infinity,
        fit: BoxFit.cover,
      ),
      const SizedBox(height: 32),
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
