import 'package:flutter/material.dart';

class ViewEventsHomePage extends StatefulWidget {
  const ViewEventsHomePage({super.key});

  @override
  State<ViewEventsHomePage> createState() => _ViewEventsHomePageState();
}

class _ViewEventsHomePageState extends State<ViewEventsHomePage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [Text('View Events')],
    );
  }
}
