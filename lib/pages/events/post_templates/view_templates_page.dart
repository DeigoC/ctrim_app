import 'package:flutter/material.dart';

import '../../../firebase/db_managers/post_template_db_manager.dart';
import '../../../models/post_template.dart';
import '../../../utility/event_context.dart';
import '../../../utility/local_data_manager.dart';
import 'edit_template_page.dart';

class ViewTemplatesPage extends StatefulWidget {
  const ViewTemplatesPage({super.key});

  @override
  State<ViewTemplatesPage> createState() => _ViewTemplatesPageState();
}

class _ViewTemplatesPageState extends State<ViewTemplatesPage> {
  final TextStyle _cardTitleStyle = const TextStyle(fontSize: 21), _cardContentStyle = const TextStyle(fontSize: 14);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Edit Templates')),
        body: _buildFBBody(),
        floatingActionButton: _buildTestButton());
  }

  Widget _buildFBBody() {
    return FutureBuilder(
        future: _getTemplates(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            final List<PostTemplate> data = snap.data!;
            data.sort((a, b) => a.headTitle.compareTo(b.headTitle));
            result = _buildBodyWithData(snap.data!);
          } else if (snap.hasError) {
            result = Center(child: Text('Something went wrong:\n${snap.error}'));
          }
          return result;
        });
  }

  Widget _buildBodyWithData(final List<PostTemplate> templates) {
    return ListView.separated(
        padding: const EdgeInsets.all(8),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: templates.length,
        itemBuilder: (_, index) => _buildTemplateTile(templates[index]));
  }

  Widget _buildTemplateTile(final PostTemplate template) {
    return InkWell(
        onTap: () => _onTemplateEditTap(template),
        child: Card(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(template.title, style: _cardTitleStyle),
                      const Divider(),
                      Text(template.description, style: _cardContentStyle)
                    ]))));
  }

  Widget _buildTestButton() {
    return FloatingActionButton.extended(
        label: const Text('Clear Dir - Test'),
        onPressed: () {
          // _createPostTemplate();
          _clearDir();
        });
  }

  // * LOGIC

  Future<void> _clearDir() async {
    final LocalDataManager localDataManager = LocalDataManager();
    localDataManager.clearPostTemplateDir();
    debugPrint('--------- Post Template Dir is cleared');
  }

  void _onTemplateEditTap(final PostTemplate postTemplate) {
    // ! For now we will edit posts here
    // We will utilise existing framework to edit a 'post'. Meaning to covert it to a EventContext
    // Then at the end covert that back to a PostTemplate and save it
    final EventContext eventContext = EventContext.adding(currentUserID: '1', id: postTemplate.id);

    // head
    eventContext.head.setEventDate(postTemplate.startTime);
    eventContext.head.setLocation(postTemplate.location);
    eventContext.head.setTitle(postTemplate.title);
    for (final headMediaItem in postTemplate.headMedia) {
      eventContext.head.addMediaItem(
          type: headMediaItem['type']!,
          src: headMediaItem['src']!,
          title: headMediaItem['title'] ?? '',
          thumbnail: headMediaItem['thumbnailSrc'] ?? '');
    }

    // body and media
    eventContext.setFetchedBody(postTemplate.body);
    eventContext.media.addAllMediaFiles(postTemplate.media);

    // meta related
    eventContext.metadata.contributorUIDs.addAll(postTemplate.contributors);

    // program related
    for (final role in postTemplate.roles) {
      eventContext.program
          .addRole(uids: role['uids'], title: role['title'], start: role['start'], end: role['end'], id: role['id']);
    }
    eventContext.program.setAddress(postTemplate.address);
    eventContext.program.setAllDay(postTemplate.allDay);
    eventContext.program.setMapLink(postTemplate.mapLink);
    eventContext.program.setOnline(postTemplate.online);
    eventContext.program.setFinishTime(postTemplate.finishTime);

    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => EditTemplatePage(
                  eventContext: eventContext,
                  oldTemplate: postTemplate,
                )))
        .then((_) {
      setState(() {
        // update the page in case of changes made
      });
    });
  }

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
