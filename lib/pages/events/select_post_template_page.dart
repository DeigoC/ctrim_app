import 'package:ctrim_app/pages/events/add_event_page.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

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
          onTap: () => _onEmptyTemplateClick(context),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Empty', style: _cardTitleStyle),
                        const Divider(),
                        Text('A clean slate', style: _cardContentStyle)
                      ])))),
      const SizedBox(height: 8),
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
    // nothing to be done to the context
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _createAndOpenSundayServiceTemplate(final BuildContext context, final DateTime selectedDate) {
    // add the typical Sunday roles to the program
    final int intercessoryPrayerID = DateTime.now().millisecondsSinceEpoch;

    debugPrint('id is $intercessoryPrayerID');
    eventContext.program.addRole(
        uids: [],
        title: 'Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 50),
        id: intercessoryPrayerID);

    final int sundaySchoolID = DateTime.now().millisecondsSinceEpoch;
    debugPrint('id is $sundaySchoolID');
    eventContext.program.addRole(
        uids: [],
        title: 'Sunday School Teachers',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        id: sundaySchoolID);

    final int welcomeAndOrientationID = DateTime.now().millisecondsSinceEpoch;
    debugPrint('id is $welcomeAndOrientationID');
    eventContext.program.addRole(
        uids: [],
        title: 'Welcome and Short Orientation',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 5),
        id: welcomeAndOrientationID);

    final int openingPrayerID = DateTime.now().millisecondsSinceEpoch;
    debugPrint('id is $openingPrayerID');
    eventContext.program.addRole(
        uids: [],
        title: 'Scripture Reading & Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 5),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 10),
        id: openingPrayerID);

    final int praiseAndWorshipID = DateTime.now().millisecondsSinceEpoch;
    debugPrint('id is $praiseAndWorshipID');
    eventContext.program.addRole(
        uids: [],
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 10),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 35),
        id: praiseAndWorshipID);

    final int wordOfGodID = DateTime.now().millisecondsSinceEpoch;
    debugPrint('id is $wordOfGodID');
    eventContext.program.addRole(
        uids: [],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 35),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 45),
        id: wordOfGodID);

    final int tithesAndOfferingsID = DateTime.now().millisecondsSinceEpoch;
    debugPrint('id is $tithesAndOfferingsID');
    eventContext.program.addRole(
        uids: [],
        title: 'Tithes & Offerings',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 45),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 50),
        id: tithesAndOfferingsID);

    final int closingSongID = DateTime.now().millisecondsSinceEpoch;
    debugPrint('id is $closingSongID');
    eventContext.program.addRole(
        uids: [],
        title: 'Closing Song',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 50),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 55),
        id: closingSongID);

    final int prayerAndBenedictionID = DateTime.now().millisecondsSinceEpoch;
    debugPrint('id is $prayerAndBenedictionID');
    eventContext.program.addRole(
        uids: [],
        title: 'Closing Prayer & Benediction',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 55),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        id: prayerAndBenedictionID);

    final int groupPictureID = DateTime.now().millisecondsSinceEpoch;
    debugPrint('id is $groupPictureID');
    eventContext.program.addRole(
        uids: [],
        title: 'Group Picture',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 5),
        id: groupPictureID);

    final int backToDiscipleshipID = DateTime.now().millisecondsSinceEpoch;
    debugPrint('id is $backToDiscipleshipID');
    eventContext.program.addRole(
        uids: [],
        title: 'Back To Discipleship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 5),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        id: backToDiscipleshipID);

    final int eatingFellowshipID = DateTime.now().millisecondsSinceEpoch;
    debugPrint('id is $eatingFellowshipID');
    eventContext.program.addRole(
        uids: [],
        title: 'Eating Fellowship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 14, 00),
        id: eatingFellowshipID);

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _createAndOpenMidweekServiceTemplate(final BuildContext context, final DateTime selectedDate) {
    eventContext.program.setOnline(true);
    eventContext.program.setAddress(''); // TODO add join link

    eventContext.program.addRole(
        uids: [],
        title: 'Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        id: DateTime.now().millisecondsSinceEpoch);
    eventContext.program.addRole(
        uids: [],
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        id: DateTime.now().millisecondsSinceEpoch);
    eventContext.program.addRole(
        uids: [],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        id: DateTime.now().millisecondsSinceEpoch);
    eventContext.program.addRole(
        uids: [],
        title: 'Closing Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        id: DateTime.now().millisecondsSinceEpoch);

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _createAndOpenDawnWatchTemplate(final BuildContext context, final DateTime selectedDate) {
    eventContext.program.setOnline(true);
    eventContext.program.setAddress(''); // TODO add join link

    eventContext.program.addRole(
        uids: [],
        title: 'Opening Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        id: DateTime.now().millisecondsSinceEpoch);
    eventContext.program.addRole(
        uids: [],
        title: 'Praise and Worship',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        id: DateTime.now().millisecondsSinceEpoch);
    eventContext.program.addRole(
        uids: [],
        title: 'Word of God',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        id: DateTime.now().millisecondsSinceEpoch);
    eventContext.program.addRole(
        uids: [],
        title: 'Closing Prayer',
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 30),
        id: DateTime.now().millisecondsSinceEpoch);

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }
}
