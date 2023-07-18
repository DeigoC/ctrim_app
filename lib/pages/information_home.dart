import 'package:flutter/material.dart';

class InformationHome extends StatefulWidget {
  const InformationHome({super.key});

  @override
  State<InformationHome> createState() => _InformationHomeState();
}

class _InformationHomeState extends State<InformationHome> {
  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text('Information'),
        )
      ],
    );
  }
}
