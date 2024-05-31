import 'package:ctrim_app/models/post_template.dart';
import 'package:flutter/material.dart';

class ViewTemplatesPage extends StatefulWidget {
  const ViewTemplatesPage({super.key});

  @override
  State<ViewTemplatesPage> createState() => _ViewTemplatesPageState();
}

class _ViewTemplatesPageState extends State<ViewTemplatesPage> {
  final List<PostTemplate> _templates = List.empty(growable: true);

  @override
  void initState() {
    // TODO we need to fetch the templates if it's been updated, simply perform a fetch and then rebuild
    // TODO otherwise, we read the locally saved templates
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('View Templates')), body: _buildBody());
  }

  Widget _buildBody() {
    return ListView.builder(itemBuilder: (_, index) => _buildTemplateTile(_templates[index]));
  }

  Widget _buildTemplateTile(final PostTemplate template) {
    return ListTile(title: Text(template.title));
  }

  // * LOGIC
}
