import 'package:flutter/material.dart';

import '../../../firebase/db_managers/post_template_db_manager.dart';
import '../../../models/post_template.dart';
import '../../../utility/local_data_manager.dart';

class ViewTemplatesPage extends StatefulWidget {
  const ViewTemplatesPage({super.key});

  @override
  State<ViewTemplatesPage> createState() => _ViewTemplatesPageState();
}

class _ViewTemplatesPageState extends State<ViewTemplatesPage> {
  @override
  void initState() {
    // TODO we need to fetch the templates if it's been updated, simply perform a fetch and then rebuild
    // TODO otherwise, we read the locally saved templates
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('View Templates')), body: _buildFBBody());
  }

  Widget _buildFBBody() {
    return FutureBuilder(
        future: _getTemplates(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            result = _buildBodyWithData(snap.data!);
          } else if (snap.hasError) {
            result = Center(child: Text('Something went wrong:\n${snap.error}'));
          }
          return result;
        });
  }

  Widget _buildBodyWithData(final List<PostTemplate> templates) {
    return ListView.builder(
        itemCount: templates.length, itemBuilder: (_, index) => _buildTemplateTile(templates[index]));
  }

  Widget _buildTemplateTile(final PostTemplate template) {
    return ListTile(title: Text(template.title), subtitle: Text(template.description));
  }

  // * LOGIC

  Future<List<PostTemplate>> _getTemplates() async {
    final LocalDataManager dataManager = LocalDataManager();
    final bool checkedToday = await dataManager.haveCheckedTemplateUpdates();

    if (checkedToday) {
      // read locally
      return await dataManager.readAllPostTemplates();
    }

    // check online first...
    //  if it's been updated: read all and update locally
    //  otherwise, read locally
    final PostTemplateDBManager postTemplateDBManager = PostTemplateDBManager();
    final int localUpdateValue = await dataManager.readLastPostTemplateUpdate();
    final int dbUpdateValue = await postTemplateDBManager.fetchLastUpdateTime();

    if (localUpdateValue != dbUpdateValue) {
      debugPrint('values dont match, time to update!');
      // perfrom the update
      final List<PostTemplate> templates = await postTemplateDBManager.fetchAllTemplates();
      for (final PostTemplate template in templates) {
        dataManager.writePostTemplateData(template);
      }

      final int newUpdateTime = DateTime.now().millisecondsSinceEpoch;
      postTemplateDBManager.updateLastUpdateTime(newUpdateTime);
      dataManager.writeLastPostTemplateUpdate(newUpdateTime);
      return templates;
    } else {
      return await dataManager.readAllPostTemplates();
    }
  }
}
