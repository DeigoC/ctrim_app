import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utility/event_context.dart';
import 'add_event_page.dart';

class SelectPostTemplatePage extends StatelessWidget {
  const SelectPostTemplatePage({super.key, required this.eventContext});
  static final DateFormat _eventDateFormat = DateFormat('d MMM');
  final EventContext eventContext;

  final TextStyle _cardTitleStyle = const TextStyle(fontSize: 21), _cardContentStyle = const TextStyle(fontSize: 14);

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Choose Template')), body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 16;

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
                  _createAndOpenYouthServiceTemplate(context, selectedDate);
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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _createAndOpenSundayServiceTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0);
    eventContext.head.setEventDate(startTime);

    eventContext.program.setFinishTime(startTime.add(const Duration(hours: 2, minutes: 45)));

    // add the typical Sunday roles to the program
    int roleID = DateTime.now().millisecondsSinceEpoch;

    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Intercessory Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 50),
        id: roleID++);

    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Sunday School Teachers',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        id: roleID++);

    eventContext.program.addRole(
        uids: ['10', '19'],
        title: 'Technical Sound',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        forGuests: false,
        id: roleID++);

    eventContext.program.addRole(
        uids: ['3', '26'],
        title: 'Technical Media',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        forGuests: false,
        id: roleID++);

    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Orientation and Countdown Video',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0),
        id: roleID++);

    eventContext.program.addRole(
        uids: ['9'],
        title: 'Scripture Reading & Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 10),
        id: roleID++);

    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 10),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 35),
        id: roleID++);

    eventContext.program.addRole(
        uids: ['8'],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 35),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 45),
        id: roleID++);

    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Tithes & Offerings',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 45),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 50),
        id: roleID++);

    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Closing Song',
        detail: 'Lead by the Worship Team',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 55),
        id: roleID++);

    eventContext.program.addRole(
        uids: ['8'],
        title: 'Closing Prayer & Benediction',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 55),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        id: roleID++);

    eventContext.program.addRole(
        uids: ['34'],
        title: 'Group Picture',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 5),
        id: roleID++);

    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Eating Fellowship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 5),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 45),
        id: roleID++);

    eventContext.program.addRole(
        uids: ['9'],
        title: 'Back To Discipleship',
        detail:
            "Further mentoring on personal & church growth through our 'cell group' lives - optional attendance for guests! 🙂",
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 45),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13, 30),
        id: roleID++);

    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Clean up!',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 14, 00),
        detail: "Remember your teams and assignment 🧽 🧻 🧹",
        forGuests: false,
        id: roleID++);

    eventContext.setFetchedBody(
        r'[{"insert":"Weekly reminder of the CTRIM WebApp: "},{"insert":"www.ctrim.app","attributes":{"link":"https://ctrim.app"}},{"insert":"\n\nLet’s get everyone on the same level and grow together in the Word of God through learning and discipleship! ❤️\n"}]');

    eventContext.head.setTitle('Sunday Worship Service (${_eventDateFormat.format(startTime)})');

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _createAndOpenMidweekServiceTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 15);
    eventContext.head.setEventDate(startTime);
    eventContext.head.addMediaItem(
        type: 'img',
        src:
            'https://lh3.googleusercontent.com/drive-viewer/AEYmBYSPROxf8rMTNeo-Nz0_nCxu8shmYXU4pJ_tc7eoJqh7VJlTuteZW-JOtUmH3MOdO2oc37qSFxw-XCt1OQIKxykmIyKFVQ=s1600');

    eventContext.program.setFinishTime(startTime.add(const Duration(hours: 1, minutes: 45)));
    eventContext.program.setOnline(true);
    eventContext.program.setAddress('https://us02web.zoom.us/j/85038786530?pwd=bmRPaTg4WHhlSVVwek9QcjVPT1RPUT09');

    int roleID = DateTime.now().millisecondsSinceEpoch;

    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Hosting',
        detail: 'By zone (will be accepting guests). Will take group picture',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 15),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22, 0),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 35),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise and Worship',
        detail: '(Videos)',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 35),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 50),
        id: roleID++);
    eventContext.program.addRole(
        uids: ['8', '9'],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 30),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Tithes and Offering',
        detail: 'Usually via Video. Assignee will lead prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 40),
        id: roleID++);
    eventContext.program.addRole(
        uids: ['8'],
        title: 'Distribution of Prayer Items + Corporate Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 5),
        id: roleID++);

    eventContext.setFetchedBody(
        r'[{"insert":"See the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab for the join link. If that doesn’t work please join via the zoom details:\nMeeting ID: 850 3878 6530"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Passcode: 985767"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\nSee you there!\n"}]');

    eventContext.head.setTitle('Midweek Service (${_eventDateFormat.format(startTime)})');
    eventContext.head.setLocation('Belfast (Online)');

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
        uids: ['21'],
        title: 'Hosting',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6, 20),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Opening Prayer & Worship Song',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 35),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Prayer Exhortation',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 35),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 50),
        id: roleID++);
    eventContext.program.addRole(
        uids: ['21'],
        title: 'Conclusion',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 55),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        detail: 'Everyone',
        title: 'Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 5, 55),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6, 20),
        id: roleID++);
    eventContext.setFetchedBody(
        r'[{"insert":"See the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab for the join link. If that doesn’t work please join via the zoom details:\nMeeting ID: 893 7280 5213"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Passcode: 261513"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\nSee you there!\n"}]');

    eventContext.head.setTitle('Dawn Watch Prayer Meeting (${_eventDateFormat.format(startTime)})');
    eventContext.head.setLocation('Belfast (Online)');

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _createAndOpenIntentionalDiscipleshipTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 18, 15);
    eventContext.head.setEventDate(startTime);
    eventContext.head.addMediaItem(
        type: 'img',
        src:
            'https://lh3.googleusercontent.com/drive-viewer/AEYmBYRwpVZ2-6jIT1VcaNhw-NRZCcz-DkcOSqPtnoHEjaMtO8mIEri4-q8V4dvH90tiVlA0RZdwe-UdxmCfBqIIhVbUdHIZig=s1600');

    eventContext.program.setFinishTime(startTime.add(const Duration(hours: 2, minutes: 30)));
    eventContext.program.setOnline(true);
    eventContext.program.setAddress('https://us02web.zoom.us/j/84796425540?pwd=andVVW5FR0t1dkFjRjZUUnpDRWVKdz09');

    int roleID = DateTime.now().millisecondsSinceEpoch;

    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Hosting',
        detail: 'By zone (will be accepting guests)',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 18, 15),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 45),
        id: roleID++);
    eventContext.program.addRole(
        uids: ['8'],
        title: 'Welcome and Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 18, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 18, 35),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise and Worship',
        detail: '(Video)',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 18, 35),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 19, 05),
        id: roleID++);
    eventContext.program.addRole(
        uids: ['8', '9'],
        title: 'Word of God',
        detail: 'With ministry & prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 19, 05),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 45),
        id: roleID++);

    eventContext.setFetchedBody(
        r'[{"insert":"See the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab for the join link. If that doesn’t work please join via the zoom details:\nMeeting ID: 847 9642 5540"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Passcode: 786441"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\nSee you there!\n"}]');

    eventContext.head.setTitle('Intentional Discipleship Training (${_eventDateFormat.format(startTime)})');
    eventContext.head.setLocation('Belfast (Online)');

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _createAndOpenYouthServiceTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 8, 0);
    eventContext.head.setEventDate(startTime);
    eventContext.head.addMediaItem(
        type: 'img',
        src:
            'https://lh3.googleusercontent.com/drive-viewer/AEYmBYShJmUDR9meJ1HM3xPUFR3TBD9uQydWk8z-E2MY0FKRoXFeFBUaNfHZFe7FIR0I5ObCq8G-VQfkoK3BcS2KuvTn4e2gFA=s1600');

    eventContext.program.setFinishTime(startTime.add(const Duration(minutes: 45)));
    eventContext.program.setOnline(true);
    eventContext.program.setAddress('https://us02web.zoom.us/j/89154407463?pwd=bDR3Y3lsL1I3NUl0MHV2SDFrR1pQdz09');

    int roleID = DateTime.now().millisecondsSinceEpoch;

    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Hosting',
        detail:
            'Remind Youth GC of the event, lead the session with the follwing schedule including welcoming and picture taking',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 0),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 5),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Icebreaker',
        detail: 'Something quick to loosen up!',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 5),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 15),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise or Worship Song',
        detail: 'Video',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 15),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 20),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Word of God',
        detail: "Sharing of their devotional/journal, testimony or whatever they really want to share! ❤️",
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 20),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 40),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Group Discussions (Application)',
        detail: 'Breakout rooms to discuss the Word or other things. Sorted by Host',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 40),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 50),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Closing Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 55),
        id: roleID++);

    eventContext.setFetchedBody(
        r'[{"insert":"See the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab for the join link. If that doesn’t work please join via the zoom details:\nMeeting ID: 891 5440 7463"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Passcode: 587922"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\nSee you there!\n"}]');

    eventContext.head.setTitle('Online Youth Service (${_eventDateFormat.format(startTime)})');
    eventContext.head.setLocation('Belfast (Online)');

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _createAndOpenOverNightPrayerTemplate(final BuildContext context, final DateTime selectedDate) {
    _resetContext();

    final DateTime startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 0);
    eventContext.head.setEventDate(startTime);

    eventContext.program.setFinishTime(startTime.add(const Duration(hours: 6, minutes: 0)));

    // add the typical Sunday roles to the program
    int roleID = DateTime.now().millisecondsSinceEpoch;

    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Short Orientation and Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 05),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 5),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 25),
        id: roleID++);
    eventContext.program.addRole(
        uids: ['9'],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20, 25),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 0),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Corporate Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 30),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 50),
        id: roleID++);
    eventContext.program.addRole(
        uids: ['8'],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 21, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22, 20),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Corporate Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22, 20),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22, 50),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Break',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 20),
        id: roleID++);
    eventContext.program.addRole(
        uids: List.empty(),
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 20),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 40),
        id: roleID++);

    eventContext.setFetchedBody(
        r'[{"insert":"The onsite, overnight prayer event for all who wants to develop their prayer life! Typically set at the end of the week, this is a test of mental, physical and spiritual strength 😤💪\n\nUsually from "},{"insert":"8pm Friday -> 2am Saturday","attributes":{"underline":true}},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"For more details see the "},{"insert":"Schedule","attributes":{"bold":true}},{"insert":" tab just a swipe away! ➡️➡️➡️"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\n(Note: because of some restrictions with the schedule feature, it only covers events up to 23:59 and cannot go to the next day)\n\nHere is the rest of the typical schedule:\n"},{"insert":"23:40 to 00:20","attributes":{"bold":true}},{"insert":" - Word of God (Ptra. Ingrid Valdez)"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"00:20 to 00:50","attributes":{"bold":true}},{"insert":" - Corporate Prayer"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"00:50 to 01:05","attributes":{"bold":true}},{"insert":" - Praise and Worship"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"01:05 to 01:30","attributes":{"bold":true}},{"insert":" - Word of God (Ptr. Deo Valdez)"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"01:30 to 01:50","attributes":{"bold":true}},{"insert":" - Corporate Prayer"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"01:50 to 01:55","attributes":{"bold":true}},{"insert":" - Closing Prayer and Benediction (Ptr. Deo Valdez)"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"01:55 to 02:00","attributes":{"bold":true}},{"insert":" - Tidying Up (Everyone)"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"\n"}]');

    eventContext.head.setTitle('Overnight Prayer and Worship (${_eventDateFormat.format(startTime)})');

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
