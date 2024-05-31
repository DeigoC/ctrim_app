import 'package:ctrim_app/models/post_template.dart';
import 'package:flutter/material.dart';

class EditTemplatePage extends StatefulWidget {
  const EditTemplatePage({super.key, required this.selectedTemplate});
  final PostTemplate selectedTemplate;

  @override
  State<EditTemplatePage> createState() => _EditTemplatePageState();
}

class _EditTemplatePageState extends State<EditTemplatePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Edit Template')), body: _buildBody());
  }

  Widget _buildBody() {
    // TODO build this similarly to viewing a regular post... well just create a tab view
    return Container();
  }
}
