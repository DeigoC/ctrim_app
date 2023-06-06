import 'package:flutter/material.dart';

class InformationHomePage extends StatefulWidget {
  const InformationHomePage({super.key});

  @override
  State<InformationHomePage> createState() => _InformationHomePageState();
}

class _InformationHomePageState extends State<InformationHomePage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [Text('Settings')],
    );
  }
}
