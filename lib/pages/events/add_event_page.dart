import 'package:flutter/material.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(headerSliverBuilder: (_, __) => _buildHeaderSliver(), body: _buildTabBody()),
    );
  }

  List<Widget> _buildHeaderSliver() {
    return [
      SliverAppBar(
        expandedHeight: MediaQuery.of(context).size.height * 0.33,
        flexibleSpace: FlexibleSpaceBar(
          background: _buildAppBarBackground(),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(8.0),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            TabBar(
              labelColor: Colors.black,
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.info_outline),
                  text: 'Header',
                ),
                Tab(
                  icon: Icon(Icons.note),
                  text: 'Body',
                ),
                Tab(
                  icon: Icon(Icons.calendar_today),
                  text: 'Program',
                ),
                Tab(
                  icon: Icon(Icons.photo_album),
                  text: 'Media',
                ),
              ],
            ),
          ]),
        ),
      )
    ];
  }

  Widget? _buildAppBarBackground() {
    // * If there are no images, we should just remove the expanded height

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // we need to transform the below to a slideshow thingy maflob. Clickable as well
        Positioned.fill(
          child: Image.network(
            'https://assets.gocomics.com/uploads/collection_images/collection_image_large_1721649_Garfield_Sandwich_V2_201805291007.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBody() {
    return TabBarView(controller: _tabController, children: const [
      Center(
        child: Text('Header Details + Meta data'),
      ),
      Center(
        child: Text('Body'),
      ),
      Center(
        child: Text('Program'),
      ),
      Center(
        child: Text('Gallery'),
      ),
    ]);
  }
}
