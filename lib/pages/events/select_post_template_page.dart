import 'package:flutter/material.dart';

import '../../utility/event_context.dart';
import 'add_event_page.dart';

class SelectPostTemplatePage extends StatelessWidget {
  const SelectPostTemplatePage({super.key, required this.eventContext});
  final EventContext eventContext;

  final TextStyle _cardTitleStyle = const TextStyle(fontSize: 21), _cardContentStyle = const TextStyle(fontSize: 14);

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Choose Template')), body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(8), children: [
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

  // * Logic

  Future<DateTime?> _selectDate(final BuildContext context) async {
    return await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 60)));
  }

  void _onEmptyTemplateClick(BuildContext context) {
    _resetContext();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _createAndOpenSundayServiceTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0);
    eventContext.head.setEventDate(startTime);

    eventContext.program.setFinishTime(startTime.add(const Duration(hours: 3)));

    // add the typical Sunday roles to the program
    int roleID = DateTime.now().millisecondsSinceEpoch;

    debugPrint('id is $roleID');
    eventContext.program.addRole(
        uids: [],
        title: 'Intercessory Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 50),
        id: roleID++);

    debugPrint('id is $roleID');
    eventContext.program.addRole(
        uids: [],
        title: 'Sunday School Teachers',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        id: roleID++);

    debugPrint('id is $roleID');
    eventContext.program.addRole(
        uids: [],
        title: 'Welcome and Short Orientation',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 5),
        id: roleID++);

    debugPrint('id is $roleID');
    eventContext.program.addRole(
        uids: [],
        title: 'Scripture Reading & Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 5),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 10),
        id: roleID++);

    debugPrint('id is $roleID');
    eventContext.program.addRole(
        uids: [],
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 10),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 35),
        id: roleID++);

    debugPrint('id is $roleID');
    eventContext.program.addRole(
        uids: ['8'],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 35),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 45),
        id: roleID++);

    eventContext.program.addRole(
        uids: [],
        title: 'Tithes & Offerings',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 45),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 50),
        id: roleID++);

    debugPrint('id is $roleID');
    eventContext.program.addRole(
        uids: [],
        title: 'Closing Song',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 55),
        id: roleID++);

    debugPrint('id is $roleID');
    eventContext.program.addRole(
        uids: [],
        title: 'Closing Prayer & Benediction',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 55),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        id: roleID++);

    debugPrint('id is $roleID');
    eventContext.program.addRole(
        uids: [],
        title: 'Group Picture',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 5),
        id: roleID++);

    debugPrint('id is $roleID');
    eventContext.program.addRole(
        uids: ['9'],
        title: 'Back To Discipleship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 5),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        id: roleID++);

    debugPrint('id is $roleID');
    eventContext.program.addRole(
        uids: [],
        title: 'Eating Fellowship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 14, 00),
        id: roleID++);

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _createAndOpenMidweekServiceTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 15);
    eventContext.head.setEventDate(startTime);
    eventContext.head
        .addMediaItem(type: 'img', src: 'https://drive.google.com/uc?id=19WLDp05yeZOtO10p9t26jiFd3-71ynAa');

    eventContext.program.setFinishTime(startTime.add(const Duration(hours: 1)));
    eventContext.program.setOnline(true);
    eventContext.program.setAddress('https://us02web.zoom.us/j/85038786530?pwd=bmRPaTg4WHhlSVVwek9QcjVPT1RPUT09');

    int roleID = DateTime.now().millisecondsSinceEpoch;

    eventContext.program.addRole(
        uids: [],
        title: 'Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 15),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 20),
        id: roleID++);
    eventContext.program.addRole(
        uids: [],
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 20),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 30),
        id: roleID++);
    eventContext.program.addRole(
        uids: ['8', '9'],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 0),
        id: roleID++);
    eventContext.program.addRole(
        uids: [],
        title: 'Closing Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 5),
        id: roleID++);

    eventContext.setFetchedBody(
        r'[{"insert":"See the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab for the join link. If that doesn’t work please join via the zoom details:\nMeeting ID: 850 3878 6530"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Passcode: 985767"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\nSee you there!\n"}]');
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _createAndOpenDawnWatchTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 30);
    eventContext.head.setEventDate(startTime);
    eventContext.head
        .addMediaItem(type: 'img', src: 'https://drive.google.com/uc?id=14p-EMBeAjg9L_ekkHGpENaMMyPWH_ne8');

    eventContext.program.setFinishTime(startTime.add(const Duration(minutes: 45)));
    eventContext.program.setOnline(true);
    eventContext.program.setAddress('https://us02web.zoom.us/j/89372805213?pwd=WlA4bzhPWlRWcE9CVHZWMXNpTFl6QT09');

    int roleID = DateTime.now().millisecondsSinceEpoch;

    eventContext.program.addRole(
        uids: [],
        title: 'Opening Prayer & Worship Song',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 35),
        id: roleID++);
    eventContext.program.addRole(
        uids: [],
        title: 'Prayer Exhortation',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 35),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 50),
        id: roleID++);
    eventContext.program.addRole(
        uids: [],
        title: 'Conclusion',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 55),
        id: roleID++);
    eventContext.program.addRole(
        uids: [],
        title: 'Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 55),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6, 20),
        id: roleID++);
    eventContext.setFetchedBody(
        r'[{"insert":"See the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab for the join link. If that doesn’t work please join via the zoom details:\nMeeting ID: 893 7280 5213"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Passcode: 261513"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\nSee you there!\n"}]');

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _createAndOpenIntentionalDiscipleshipTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 15);
    eventContext.head.setEventDate(startTime);
    eventContext.head
        .addMediaItem(type: 'img', src: 'https://drive.google.com/uc?id=1O3lXV494dVLmpreRiasLN0oOW6kngAy5');

    eventContext.program.setFinishTime(startTime.add(const Duration(hours: 2, minutes: 15)));
    eventContext.program.setOnline(true);
    eventContext.program.setAddress('https://us02web.zoom.us/j/84796425540?pwd=andVVW5FR0t1dkFjRjZUUnpDRWVKdz09');

    int roleID = DateTime.now().millisecondsSinceEpoch;

    eventContext.program.addRole(
        uids: [],
        title: 'Host will accept guests',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 15),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 30),
        id: roleID++);
    eventContext.program.addRole(
        uids: ['8'],
        title: 'Welcome and Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 35),
        id: roleID++);
    eventContext.program.addRole(
        uids: [],
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 35),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 50),
        id: roleID++);
    eventContext.program.addRole(
        uids: ['8', '9'],
        title: 'Word of God',
        detail: 'With ministry & prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        id: roleID++);

    eventContext.setFetchedBody(
        r'[{"insert":"See the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab for the join link. If that doesn’t work please join via the zoom details:\nMeeting ID: 847 9642 5540"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Passcode: 786441"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\nSee you there!\n"}]');

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _resetContext() {
    eventContext.head.setEventDate(null);
    eventContext.head.setTitle('');
    eventContext.head.setSubtitle('');
    eventContext.head.setLocation('Belfast');
    eventContext.head.clearMedia();

    eventContext.program.clearRoles();
    eventContext.program.setAddress('8A Princes Dr, Newtownabbey, BT37 0AZ, Northern Ireland');
    eventContext.program.setOnline(false);
    eventContext.program.setFinishTime(null);
    eventContext.program.setMapLink('https://goo.gl/maps/ns21zf5F9KPxeKxn6');
    eventContext.program.setAllDay(false);

    eventContext.media.clearAllMedia();
    eventContext.setFetchedBody(r'[{"insert":"Hello, time to start writing!\n"}]');

    eventContext.metadata.contributorUIDs.clear();
  }
}
