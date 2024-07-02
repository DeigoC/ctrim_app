import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../firebase/db_managers/post_template_db_manager.dart';
import '../../../models/post_template.dart';
import '../../../utility/event_context.dart';
import '../../../utility/local_data_manager.dart';
import '../add_event_page.dart';

class SelectPostTemplatePage extends StatefulWidget {
  const SelectPostTemplatePage({super.key, required this.eventContext});
  static final DateFormat _eventDateFormat = DateFormat('d MMM');
  final EventContext eventContext;

  @override
  State<SelectPostTemplatePage> createState() => _SelectPostTemplatePageState();
}

class _SelectPostTemplatePageState extends State<SelectPostTemplatePage> {
  final LocalDataManager _localDataManager = LocalDataManager();

  @override
  void initState() {
    _localDataManager.readLastPostTemplateUpdate();
    super.initState();
  }

  final TextStyle _cardTitleStyle = const TextStyle(fontSize: 21), _cardContentStyle = const TextStyle(fontSize: 14);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Template')),
      body: _buildFBBody(),
      floatingActionButton: _buildTestButton(),
    );
  }

  Widget _buildFBBody() {
    return FutureBuilder(
        future: _getTemplates(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            final List<PostTemplate> data = snap.data!;
            data.sort((a, b) => a.headTitle.compareTo(b.headTitle));
            data.add(_createBlankSlate());
            result = _buildBodyWithData(data);
          } else if (snap.hasError) {
            result = Center(child: Text('Something went wrong:\n${snap.error}'));
          }
          return result;
        });
  }

  PostTemplate _createBlankSlate() {
    final Map<String, dynamic> templateData = {
      'Title': 'Blank Template',
      'Description': "A clean slate. Edit to your heart's content!",
      'HeadTitle': 'TODO: what do i do with this?',
      'Body': r'[{"insert":"Hello, time to start writing!\n"}]',
      'Location': 'Belfast',
      'Topics': ['Belfast'],
      'Contributors': [],
      'AllDay': false,
      'Online': false,
      'Address': '',
      'MapLink': '',
      'StartTime': null,
      'FinishTime': null,
      'Media': [],
      'HeadMedia': List<Map<String, dynamic>>.empty(),
      'Roles': List<Map<String, dynamic>>.empty(),
    };

    return PostTemplate.fromMap(true, 'blank', templateData);
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
        onTap: () => _onAddPostTap(template),
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
        label: const Text('Test here'),
        onPressed: () {
          // _createPostTemplate();
          _clearDir();
        });
  }

  Future<void> _clearDir() async {
    final LocalDataManager localDataManager = LocalDataManager();
    localDataManager.clearPostTemplateDir();
    debugPrint('--------- Post Template Dir is cleared');
  }

  // * Logic
  Future<DateTime?> _selectDate(final BuildContext context) async {
    return await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 60)));
  }

  Future<List<PostTemplate>> _getTemplates() async {
    final LocalDataManager dataManager = LocalDataManager();
    final bool checkedToday = await dataManager.haveCheckedTemplateUpdates();

    if (checkedToday) {
      // read locally
      return await dataManager.readAllPostTemplates();
    }

    final PostTemplateDBManager postTemplateDBManager = PostTemplateDBManager();
    final int localUpdateValue = await dataManager.readLastPostTemplateUpdate();
    final int dbUpdateValue = await postTemplateDBManager.fetchLastUpdateTime();

    if (localUpdateValue != dbUpdateValue) {
      debugPrint('values dont match, time to update!');
      // perfrom the update
      final List<PostTemplate> templates = await postTemplateDBManager.fetchAllTemplates();
      for (final PostTemplate template in templates) {
        debugPrint('writing PostTemplate ID ${template.id}');
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

  // void _tmpAddEventContextToTemplate(final EventContext eventContext) {
  //   dynamic startTime = widget.eventContext.head.eventDate;
  //   dynamic finishTime = widget.eventContext.program.finishTime;
  //   if (startTime != null) {
  //     startTime = Timestamp.fromDate(startTime);
  //   }
  //   if (finishTime != null) {
  //     finishTime = Timestamp.fromDate(finishTime);
  //   }
  //   final Map<String, dynamic> templateData = {
  //     'Title': eventContext.head.title,
  //     'Description': 'TODO: change this description',
  //     'HeadTitle': 'TODO change this head title',
  //     'Body': eventContext.encodedBody,
  //     'Location': eventContext.head.location,
  //     'Topics': eventContext.metadata.topics,
  //     'Contributors': eventContext.metadata.contributorUIDs,
  //     'AllDay': eventContext.program.allDay,
  //     'Online': eventContext.program.online,
  //     'Address': eventContext.program.address,
  //     'MapLink': eventContext.program.mapLink,
  //     'StartTime': startTime,
  //     'FinishTime': finishTime,
  //     'Media': eventContext.media.allMedia,
  //     'HeadMedia': eventContext.head.media,
  //     'Roles': _rolesToJson(),
  //   };
  //   final PostTemplate template = PostTemplate.fromMap(false, widget.eventContext.id, templateData);
  //   final PostTemplateDBManager postTemplateDBManager = PostTemplateDBManager();
  //   postTemplateDBManager.addPostTemplate(template);
  // }

  // List<Map<String, dynamic>> _rolesToJson() {
  //   final List<Map<String, dynamic>> result = List<Map<String, dynamic>>.empty(growable: true);
  //   for (final entry in widget.eventContext.program.roles) {
  //     var start = entry['start'];
  //     var end = entry['end'];
  //     if (start != null) {
  //       start = Timestamp.fromDate(entry['start']);
  //     }
  //     if (end != null) {
  //       end = Timestamp.fromDate(entry['end']);
  //     }

  //     result.add({
  //       'uids': entry['uids'],
  //       'detail': entry['detail'],
  //       'title': entry['title'],
  //       'start': start,
  //       'end': end,
  //       'for_guests': entry['for_guests'],
  //       'id': entry['id'],
  //     });
  //   }

  //   return result;
  // }

  void _onAddPostTap(final PostTemplate postTemplate) {
    // convert the template to EventContext
    final EventContext eventContext = _mapTemplateToEventContext(postTemplate);

    if (eventContext.head.eventDate != null) {
      _selectDate(context).then((selectedDate) {
        if (selectedDate != null) {
          _adjustEventProgramToDate(eventContext, selectedDate);
          eventContext.head
              .setTitle('${postTemplate.title} (${SelectPostTemplatePage._eventDateFormat.format(selectedDate)})');
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
        }
      });
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
    }
  }

  _adjustEventProgramToDate(final EventContext eventContext, final DateTime selectedDate) {
    final DateTime newEventDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
        eventContext.head.eventDate!.hour, eventContext.head.eventDate!.minute);

    eventContext.head.setEventDate(newEventDate);

    if (eventContext.program.finishTime != null) {
      final DateTime oldFinishTime = eventContext.program.finishTime!;
      final DateTime finishTime =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day, oldFinishTime.hour, oldFinishTime.minute);
      eventContext.program.setFinishTime(finishTime);
    }

    for (final scheduleItem in eventContext.program.roles) {
      final DateTime oldDateStart = scheduleItem['start'];
      final DateTime oldDateEnd = scheduleItem['end'];
      final DateTime newDateStart =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day, oldDateStart.hour, oldDateStart.minute);
      final DateTime newDateEnd =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day, oldDateEnd.hour, oldDateEnd.minute);

      scheduleItem['start'] = newDateStart;
      scheduleItem['end'] = newDateEnd;
    }
  }

  EventContext _mapTemplateToEventContext(final PostTemplate postTemplate) {
    final EventContext eventContext = EventContext.adding(currentUserID: '1');

    // head
    eventContext.head.setEventDate(postTemplate.startTime);
    eventContext.head.setLocation(postTemplate.location);
    eventContext.head.setTitle(postTemplate.title);
    for (final headMediaItem in postTemplate.headMedia) {
      eventContext.head
          .addMediaItem(type: headMediaItem['type']!, src: headMediaItem['src']!, title: headMediaItem['title'] ?? '');
    }

    // body and media
    eventContext.setFetchedBody(postTemplate.body);
    eventContext.media.addAllMediaFiles(postTemplate.media);

    // meta related
    eventContext.metadata.contributorUIDs.addAll(postTemplate.contributors);
    eventContext.metadata.addAllTopics(postTemplate.topics);

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

    return eventContext;
  }
}
