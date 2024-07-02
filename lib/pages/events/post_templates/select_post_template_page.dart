import 'package:ctrim_app/firebase/db_managers/post_template_db_manager.dart';
import 'package:ctrim_app/models/post_template.dart';
import 'package:ctrim_app/pages/events/post_templates/edit_template_page.dart';
import 'package:ctrim_app/utility/local_data_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../utility/app_context.dart';
import '../../../utility/event_context.dart';
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
      // body: _buildBody(context),
      floatingActionButton: _buildTestButton(),
    );
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
    return ListTile(
      title: Text(template.title),
      subtitle: Text(template.description),
      onTap: () => _onTemplateTap(template),
    );
  }

  Widget _buildBody(BuildContext context) {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 8;

    return ListView(padding: EdgeInsets.symmetric(vertical: 8, horizontal: webHorizontalPadding), children: [
      InkWell(
          onTap: () => _selectDate(context).then((selectedDate) {
                if (selectedDate != null) {
                  _createAndOpenSundayServiceTemplate(context, selectedDate);
                }
              }),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                    Text('Belfast Sunday Service', style: _cardTitleStyle),
                    const Divider(),
                    Text('Fitted with the usual schedule of a weekly Sunday Service in Belfast',
                        style: _cardContentStyle)
                  ])))),
      const SizedBox(height: 8),
      InkWell(
          onTap: () => _selectDate(context).then((selectedDate) {
                if (selectedDate != null) {
                  _createAndOpenMidweekServiceTemplate(context, selectedDate);
                }
              }),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                    Text('Midweek Service', style: _cardTitleStyle),
                    const Divider(),
                    Text('Online service with the typical schedule', style: _cardContentStyle)
                  ])))),
      const SizedBox(height: 8),
      InkWell(
          onTap: () => _selectDate(context).then((selectedDate) {
                if (selectedDate != null) {
                  _createAndOpenIntentionalDiscipleshipTemplate(context, selectedDate);
                }
              }),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                    Text('Intentional Discipleship Training', style: _cardTitleStyle),
                    const Divider(),
                    Text('Online training session with a schedule already applied', style: _cardContentStyle)
                  ])))),
      const SizedBox(height: 8),
      InkWell(
          onTap: () => _selectDate(context).then((selectedDate) {
                if (selectedDate != null) {
                  _createAndOpenYouthCGTemplate(context, selectedDate);
                }
              }),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                    Text('Youth Service', style: _cardTitleStyle),
                    const Divider(),
                    Text("Online Friday Youth service. Quick and dirty, it's a fun time!", style: _cardContentStyle)
                  ])))),
      const SizedBox(height: 8),
      InkWell(
          onTap: () => _selectDate(context).then((selectedDate) {
                if (selectedDate != null) {
                  _createAndOpenOverNightPrayerTemplate(context, selectedDate);
                }
              }),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                    Text('Overnight Prayer & Worship', style: _cardTitleStyle),
                    const Divider(),
                    Text(
                        "Monthly onsite prayer event not for the faint of heart. Back to back prayer sessions with multiple praise sections as well",
                        style: _cardContentStyle)
                  ])))),
      const SizedBox(height: 8),
      InkWell(
          onTap: () => _selectDate(context).then((selectedDate) {
                if (selectedDate != null) {
                  _createAndOpenDawnWatchTemplate(context, selectedDate);
                }
              }),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                    Text('Dawn Watch', style: _cardTitleStyle),
                    const Divider(),
                    Text('Early online meeting, includes schedule', style: _cardContentStyle)
                  ])))),
      const SizedBox(height: 8),
      InkWell(
          onTap: () => _onEmptyTemplateClick(context),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Blank', style: _cardTitleStyle),
                        const Divider(),
                        Text('A clean slate', style: _cardContentStyle)
                      ])))),
    ]);
  }

  Widget _buildTestButton() {
    return FloatingActionButton.extended(
        label: const Text('Test here'),
        onPressed: () {
          // _createPostTemplate();
          _clearDir();
        });
  }

  Future<void> _createPostTemplate() async {
    // create a simple Template for now
    final Map<String, dynamic> templateData = {
      'Title': 'here is a title',
      'Description': 'here is a description',
      'HeadTitle': 'here is the head title',
      'Body': r'[{"insert":"Hello, time to start writing!\n"}]',
      'Location': 'Belfast',
      'Topics': ['topic1'],
      'Contributors': ['3'],
      'AllDay': false,
      'Online': false,
      'Address': 'Some address here',
      'MapLink': 'some link here',
      'StartTime': DateTime.now().millisecondsSinceEpoch,
      'FinishTime': DateTime.now().add(const Duration(hours: 2)).millisecondsSinceEpoch,
      'Media': [
        {
          'src':
              'https://static.wikia.nocookie.net/garfield/images/7/70/Garfield2000.png/revision/latest/scale-to-width/360?cb=20231128184459',
          'title': 'title here for image',
          'type': 'img'
        }
      ],
      'HeadMedia': List<Map<String, dynamic>>.empty(),
      'Roles': List<Map<String, dynamic>>.from([
        {
          'uids': ['2'],
          'detail': '',
          'title': 'An example Title',
          'start': DateTime.now().millisecondsSinceEpoch,
          'end': DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch,
          'for_guests': true,
          'id': 123213
        }
      ]),
    };
    final PostTemplate thisTemplate = PostTemplate.fromMap(true, 'RnGMzbiXUUDOVTiFh76F', templateData);

    // try writing to local storage as a Json
    debugPrint('---- Creating PostTemplate complete, time to write to local storage');
    await _localDataManager.writePostTemplateData(thisTemplate);

    // then try to read it again
    debugPrint('---- Time to read in the data');
    final allTemplates = await _localDataManager.readAllPostTemplates();

    debugPrint('---- Time to save the data over to the DB');
    PostTemplateDBManager postTemplateDBManager = PostTemplateDBManager();
    await postTemplateDBManager.addPostTemplate(allTemplates.first);

    debugPrint('---- Time to save the data over to the DB');
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

  void _onEmptyTemplateClick(final BuildContext context) {
    _resetContext();
    final String locationTopic = Provider.of<AppContext>(context, listen: false).currentUser.location;
    widget.eventContext.metadata.addAllTopics([locationTopic]);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: widget.eventContext)));
  }

  void _createAndOpenSundayServiceTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0);
    widget.eventContext.head.setEventDate(startTime);
    widget.eventContext.program.setFinishTime(startTime.add(const Duration(hours: 2, minutes: 45)));

    // TODO remember to change all of these in the future
    widget.eventContext.metadata.addAllTopics(['belfast-sunday-service']);

    // add the typical Sunday roles to the program
    int roleID = DateTime.now().millisecondsSinceEpoch;

    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Intercessory Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 50),
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Sunday School Teachers',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: ['10', '19'],
        title: 'Technical Sound',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        forGuests: false,
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: ['3', '26'],
        title: 'Technical Media',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        forGuests: false,
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Orientation and Countdown Video',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0),
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: ['9'],
        title: 'Scripture Reading & Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 10),
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 10),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 35),
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: ['8'],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 35),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 45),
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Tithes & Offerings',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 45),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 50),
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Closing Song',
        detail: 'Lead by the Worship Team',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 55),
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: ['8'],
        title: 'Closing Prayer & Benediction',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 55),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: ['34'],
        title: 'Group Picture',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 5),
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Eating Fellowship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 5),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 45),
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: ['9'],
        title: 'Back To Discipleship',
        detail:
            "Further mentoring on personal & church growth through our 'cell group' lives - optional attendance for guests! 🙂",
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 45),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13, 30),
        id: roleID++);

    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Clean up!',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 14, 00),
        detail: "Remember your teams and assignment 🧽 🧻 🧹",
        forGuests: false,
        id: roleID++);

    widget.eventContext.setFetchedBody(
        r'[{"insert":"Remember to share this CTRIM App! There’a a page in the "},{"insert":"Personal","attributes":{"bold":true}},{"insert":" tab section - "},{"insert":"Share CTRIM App","attributes":{"bold":true}},{"insert":" where you can find the download links \n\nAnd do not forget to do good and to share with others, for with such sacrifices God is pleased."},{"insert":"\n","attributes":{"blockquote":true}},{"insert":"Hebrews 13:16 (NIV)","attributes":{"bold":true}},{"insert":"\n","attributes":{"blockquote":true}},{"insert":"\n"}]');

    widget.eventContext.head
        .setTitle('Sunday Worship Service (${SelectPostTemplatePage._eventDateFormat.format(startTime)})');

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: widget.eventContext)));
  }

  void _createAndOpenMidweekServiceTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 15);
    widget.eventContext.head.setEventDate(startTime);
    widget.eventContext.program.setFinishTime(startTime.add(const Duration(hours: 1, minutes: 45)));

    widget.eventContext.metadata.addAllTopics(['belfast-midweek-service']);
    widget.eventContext.program.setOnline(true);
    widget.eventContext.program
        .setAddress('https://us02web.zoom.us/j/85038786530?pwd=bmRPaTg4WHhlSVVwek9QcjVPT1RPUT09');
    widget.eventContext.head
        .addMediaItem(type: 'img', src: 'https://drive.google.com/uc?id=1TJtX5Pl0gmXlYJpioDNdFXtYIg2DrGAu');

    int roleID = DateTime.now().millisecondsSinceEpoch;

    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Hosting',
        detail: 'By zone (will be accepting guests). Will take group picture',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 15),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22, 0),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 35),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise and Worship',
        detail: '(Videos)',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 35),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 50),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: ['8', '9'],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 30),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Tithes and Offering',
        detail: 'Usually via Video. Assignee will lead prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 40),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: ['8'],
        title: 'Distribution of Prayer Items + Corporate Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 5),
        id: roleID++);

    widget.eventContext.setFetchedBody(
        r'[{"insert":"See the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab for the join link. If that doesn’t work please join via the zoom details:\nMeeting ID: 850 3878 6530"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Passcode: 985767"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\nSee you there!\n"}]');

    widget.eventContext.head.setTitle('Midweek Service (${SelectPostTemplatePage._eventDateFormat.format(startTime)})');
    widget.eventContext.head.setLocation('Belfast (Online)');

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: widget.eventContext)));
  }

  void _createAndOpenDawnWatchTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 30);
    widget.eventContext.head.setEventDate(startTime);
    widget.eventContext.head
        .addMediaItem(type: 'img', src: 'https://drive.google.com/uc?id=13-1cDYsCtpgJZ1E0sM02Jrj3ZYWVnziL');

    widget.eventContext.program.setFinishTime(startTime.add(const Duration(minutes: 45)));
    widget.eventContext.program.setOnline(true);
    widget.eventContext.program
        .setAddress('https://us02web.zoom.us/j/89372805213?pwd=WlA4bzhPWlRWcE9CVHZWMXNpTFl6QT09');
    widget.eventContext.metadata.addAllTopics(['belfast-dawn-watch']);

    int roleID = DateTime.now().millisecondsSinceEpoch;

    widget.eventContext.program.addRole(
        uids: ['21'],
        title: 'Hosting',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6, 20),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Opening Prayer & Worship Song',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 35),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Prayer Exhortation',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 35),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 50),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: ['21'],
        title: 'Conclusion',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 55),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        detail: 'Everyone',
        title: 'Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 55),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6, 20),
        id: roleID++);
    widget.eventContext.setFetchedBody(
        r'[{"insert":"See the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab for the join link. If that doesn’t work please join via the zoom details:\nMeeting ID: 893 7280 5213"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Passcode: 261513"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\nSee you there!\n"}]');

    widget.eventContext.head
        .setTitle('Dawn Watch Prayer Meeting (${SelectPostTemplatePage._eventDateFormat.format(startTime)})');
    widget.eventContext.head.setLocation('Belfast (Online)');

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: widget.eventContext)));
  }

  void _createAndOpenIntentionalDiscipleshipTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 18, 15);
    widget.eventContext.head.setEventDate(startTime);
    widget.eventContext.head
        .addMediaItem(type: 'img', src: 'https://drive.google.com/uc?id=1_Uw0FIXJkQXOdMydsS0Wu4lB_iqBDmZZ');

    widget.eventContext.program.setFinishTime(startTime.add(const Duration(hours: 2, minutes: 30)));
    widget.eventContext.program.setOnline(true);
    widget.eventContext.program
        .setAddress('https://us02web.zoom.us/j/84796425540?pwd=andVVW5FR0t1dkFjRjZUUnpDRWVKdz09');
    widget.eventContext.metadata.addAllTopics(['belfast-growth-mentoring']);

    int roleID = DateTime.now().millisecondsSinceEpoch;

    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Hosting',
        detail: 'By zone (will be accepting guests)',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 18, 15),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 45),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: ['8'],
        title: 'Welcome and Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 18, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 18, 35),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise and Worship',
        detail: '(Video)',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 18, 35),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 19, 05),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: ['8', '9'],
        title: 'Word of God',
        detail: 'With ministry & prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 19, 05),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 45),
        id: roleID++);

    widget.eventContext.setFetchedBody(
        r'[{"insert":"See the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab for the join link. If that doesn’t work please join via the zoom details:\nMeeting ID: 847 9642 5540"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Passcode: 786441"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\nSee you there!\n"}]');

    widget.eventContext.head
        .setTitle('Intentional Discipleship Training (${SelectPostTemplatePage._eventDateFormat.format(startTime)})');
    widget.eventContext.head.setLocation('Belfast (Online)');

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: widget.eventContext)));
  }

  void _createAndOpenYouthCGTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 0);
    widget.eventContext.head.setEventDate(startTime);
    widget.eventContext.head
        .addMediaItem(type: 'img', src: 'https://drive.google.com/uc?id=1IMiwkg-6bLxhnMyWNdWVkY0KpdO15NRI');

    widget.eventContext.program.setFinishTime(startTime.add(const Duration(minutes: 45)));
    widget.eventContext.program.setOnline(true);
    widget.eventContext.program
        .setAddress('https://us02web.zoom.us/j/89154407463?pwd=bDR3Y3lsL1I3NUl0MHV2SDFrR1pQdz09');
    widget.eventContext.metadata.addAllTopics(['belfast-youth-cg']);

    int roleID = DateTime.now().millisecondsSinceEpoch;

    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Hosting',
        detail:
            'Remind Youth GC of the event, lead the session with the follwing schedule including welcoming and picture taking',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 0),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 5),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Icebreaker',
        detail: 'Something quick to loosen up!',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 5),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 15),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise or Worship Song',
        detail: 'Video',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 15),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 20),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Word of God',
        detail: "Sharing of their devotional/journal, testimony or whatever they really want to share! ❤️",
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 20),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 40),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Group Discussions (Application)',
        detail: 'Breakout rooms to discuss the Word or other things. Sorted by Host',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 40),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 50),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Closing Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 55),
        id: roleID++);

    widget.eventContext.setFetchedBody(
        r'[{"insert":"See the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab for the join link. If that doesn’t work please join via the zoom details:\nMeeting ID: 891 5440 7463"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Passcode: 587922"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\nSee you there!\n"}]');

    widget.eventContext.head
        .setTitle('Online Youth Caregroup (${SelectPostTemplatePage._eventDateFormat.format(startTime)})');
    widget.eventContext.head.setLocation('Belfast (Online)');

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: widget.eventContext)));
  }

  void _createAndOpenOverNightPrayerTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 0);
    widget.eventContext.head.setEventDate(startTime);

    widget.eventContext.program.setFinishTime(startTime.add(const Duration(hours: 6, minutes: 0)));
    widget.eventContext.metadata.addAllTopics(['belfast-overnight-prayer']);

    // add the typical Sunday roles to the program
    int roleID = DateTime.now().millisecondsSinceEpoch;

    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Short Orientation and Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 05),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 5),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 25),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: ['9'],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 25),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 0),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Corporate Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 30),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 50),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: ['8'],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22, 20),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Corporate Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22, 20),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22, 50),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Break',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 20),
        id: roleID++);
    widget.eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 20),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 40),
        id: roleID++);

    widget.eventContext.setFetchedBody(
        r'[{"insert":"The onsite, overnight prayer event for all who wants to develop their prayer life! Typically set at the end of the week, this is a test of mental, physical and spiritual strength 😤💪\n\nUsually from "},{"insert":"8pm Friday -> 2am Saturday","attributes":{"underline":true}},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"For more details see the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab just a swipe away! ➡️➡️➡️"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\n(Note: because of some restrictions with the schedule feature, it only covers events up to 23:59 and cannot go to the next day)\n\nHere is the rest of the typical schedule:\n"},{"insert":"23:40 to 00:20","attributes":{"bold":true}},{"insert":" - Word of God (Ptra. Ingrid Valdez)"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"00:20 to 00:50","attributes":{"bold":true}},{"insert":" - Corporate Prayer"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"00:50 to 01:05","attributes":{"bold":true}},{"insert":" - Praise and Worship"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"01:05 to 01:30","attributes":{"bold":true}},{"insert":" - Word of God (Ptr. Deo Valdez)"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"01:30 to 01:50","attributes":{"bold":true}},{"insert":" - Corporate Prayer"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"01:50 to 01:55","attributes":{"bold":true}},{"insert":" - Closing Prayer and Benediction (Ptr. Deo Valdez)"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"01:55 to 02:00","attributes":{"bold":true}},{"insert":" - Tidying Up (Everyone)"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\n"}]');

    widget.eventContext.head
        .setTitle('Overnight Prayer and Worship (${SelectPostTemplatePage._eventDateFormat.format(startTime)})');

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: widget.eventContext)));
  }

  void _resetContext() {
    widget.eventContext.head.setEventDate(null);
    widget.eventContext.head.setTitle('');
    widget.eventContext.head.setSubtitle('');
    widget.eventContext.head.setLocation('Belfast');
    widget.eventContext.head.clearMedia();

    widget.eventContext.program.clearRoles();
    widget.eventContext.program.setAddress('8A Princes Dr, Newtownabbey, BT37 0AZ, Northern Ireland');
    widget.eventContext.program.setOnline(false);
    widget.eventContext.program.setFinishTime(null);
    widget.eventContext.program.setMapLink('https://goo.gl/maps/ns21zf5F9KPxeKxn6');
    widget.eventContext.program.setAllDay(false);

    widget.eventContext.media.clearAllMedia();
    widget.eventContext.setFetchedBody(r'[{"insert":"Hello, time to start writing!\n"}]');

    widget.eventContext.setNotifyBroadcast(true);
    widget.eventContext.setNotifyScheduledMembers(true);
    widget.eventContext.metadata.contributorUIDs.clear();
    widget.eventContext.metadata.clearTopics();
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

  void _onTemplateTap(final PostTemplate postTemplate) {
    // ! For now we will edit posts here
    // We will utilise existing framework to edit a 'post'. Meaning to covert it to a EventContext
    // Then at the end covert that back to a PostTemplate and save it
    final EventContext eventContext = EventContext.adding(currentUserID: '1', id: postTemplate.id);

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
}
