import 'package:ctrim_app/pages/information/edit_info_body_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InfoAction extends StatelessWidget {
  const InfoAction({super.key, required this.json});
  final String json;

  @override
  Widget build(BuildContext context) {
    return Provider.of<AppContext>(context, listen: false).currentUser.id == '1'
        ? IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditInfoBodyPage(json: json)));
            },
            icon: const Icon(Icons.edit))
        : Container();
  }
}
