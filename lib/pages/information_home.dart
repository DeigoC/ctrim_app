import 'package:flutter/material.dart';

class InformationHome extends StatefulWidget {
  const InformationHome({super.key, required this.tabController});
  final TabController tabController;
  @override
  State<InformationHome> createState() => _InformationHomeState();
}

class _InformationHomeState extends State<InformationHome> {
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (_, __) => [
        SliverAppBar(
          title: Image.asset(_ctrimLogo),
          bottom: TabBar(
            controller: widget.tabController,
            tabs: const [
              Tab(
                text: 'About',
              ),
              Tab(
                text: 'Churches',
              ),
              Tab(
                text: 'Teachings',
              ),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: widget.tabController,
        children: [
          const Icon(Icons.directions_car),
          _buildChurchesTab(),
          const Icon(Icons.directions_bike),
        ],
      ),
    );
  }

  Widget _buildChurchesTab() {
    return ListView(
      key: const PageStorageKey<String>('information_churches_tab'),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          width: double.infinity,
          child: Container(
            color: Colors.red,
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          width: double.infinity,
          child: Container(
            color: Colors.blue,
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          width: double.infinity,
          child: Container(
            color: Colors.green,
          ),
        )
      ],
    );
  }
}
