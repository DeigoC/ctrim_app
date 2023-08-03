import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../pages/information/edit_info_body_page.dart';

class InfoAction extends StatelessWidget {
  const InfoAction({super.key, required this.json});
  final String json;

  @override
  Widget build(BuildContext context) {
    return kDebugMode
        ? IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditInfoBodyPage(json: json)));
            },
            icon: const Icon(Icons.edit))
        : Container();
  }
}
