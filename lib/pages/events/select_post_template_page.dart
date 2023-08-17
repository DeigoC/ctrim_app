import 'package:ctrim_app/pages/events/add_event_page.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class SelectPostTemplatePage extends StatelessWidget {
  const SelectPostTemplatePage({super.key, required this.eventContext});
  final EventContext eventContext;

  final TextStyle _cardTitleStyle = const TextStyle(fontSize: 21), _cardContentStyle = const TextStyle(fontSize: 14);

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Post Template')), body: _buildBody(context));
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
          onTap: () => _onBelfastSundayServiceClick(context),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                    Text('Belfast Sunday Service', style: _cardTitleStyle),
                    const Divider(),
                    Text('Fitted with the usual schedule of a weekly Sunday Service in Belfast',
                        style: _cardContentStyle)
                  ]))))
    ]);
  }

  // * Logic

  void _onEmptyTemplateClick(BuildContext context) {
    // nothing to be done to the context
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }

  void _onBelfastSundayServiceClick(BuildContext context) {
    // add the typical Sunday roles to the program
    final DateTime now = DateTime.now();
    eventContext.program.addRole(
        uids: [],
        title: 'Opening Prayer',
        start: DateTime(now.year, now.month, now.day, 10, 5),
        end: DateTime(now.year, now.month, now.day, 10, 10));

    eventContext.program.addRole(
        uids: [],
        title: 'Praise and Worship',
        start: DateTime(now.year, now.month, now.day, 10, 10),
        end: DateTime(now.year, now.month, now.day, 10, 35));
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEventPage(eventContext: eventContext)));
  }
}
