import 'package:flutter/material.dart';

import 'information/belfast_church_page.dart';
import 'information/north_coast_church_page.dart';
import 'information/portadown_church_page.dart';

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
                  title: const Text('CTRIM'),
                  centerTitle: false,
                  snap: true,
                  floating: true,
                  leading: Image.asset(_ctrimLogo, fit: BoxFit.contain, height: kToolbarHeight),
                  bottom: TabBar(
                      controller: widget.tabController,
                      tabs: const [Tab(text: 'About'), Tab(text: 'Churches'), Tab(text: 'Teachings')]))
            ],
        body: TabBarView(
            controller: widget.tabController, children: [_buildAbout(), _buildChurchesTab(), _buildTeachingsTab()]));
  }

  Widget _buildAbout() {
    const String matthewVerse = '“Therefore go and make disciples of all nations, baptizing them in the '
        'name of the Father and of the Son and of the Holy Spirit, and '
        'teaching them to obey everything I have commanded you. And '
        'surely I am with you always, to the very end of the age."';
    const String visionParagraph = 'Our vision is to become like the early Church in the Book of Acts, effective '
        'and strategic in disciple making. Effective and strategic in harnessing the power of The Holy Spirit, causing '
        'them to multiply rapidly and having the power to turn the world upside down for the Glory of God.';

    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView(children: const [
          // Image.network('https://upload.wikimedia.org/wikipedia/commons/1/15/Cat_August_2010-4.jpg'),
          SizedBox(height: 32),
          Text(
              'Christ the Redeemer International Ministries is dedicated and committed to making true disciples who will passionately advance the Kingdom of God.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18)),
          SizedBox(height: 32),
          Divider(thickness: 1),
          SizedBox(height: 32),
          Text('OUR MISSION', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 18),
          Text('To Win Souls and Make Disciples.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          SizedBox(height: 18),
          Text('Matthew 28:19-20',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, decoration: TextDecoration.underline)),
          Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(matthewVerse, textAlign: TextAlign.center, style: TextStyle(fontSize: 18))),
          SizedBox(height: 32),
          Divider(thickness: 1),
          SizedBox(height: 32),
          Text('OUR VISION', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 18),
          Text('To become an effective and strategic disciple-making church.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          SizedBox(height: 18),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(visionParagraph, textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          ),
          SizedBox(height: 32)
        ]));
  }

  Widget _buildChurchesTab() {
    return MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ListView(key: const PageStorageKey<String>('information_churches_tab'), children: [
          _buildChurchSlot('Belfast', 'bel1.png'),
          _buildChurchSlot('Portadown', 'port1.png'),
          _buildChurchSlot('North Coast', 'northC1.png')
        ]));
  }

  Widget _buildChurchSlot(final String church, final String img) {
    return InkWell(
        onTap: () => _onChurchTap(church),
        child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            child: Stack(children: [
              Positioned.fill(child: Image.asset('assets/images/$img', fit: BoxFit.cover)),
              Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(church, style: const TextStyle(fontSize: 32, color: Colors.white))))
            ])));
  }

  Widget _buildTeachingsTab() {
    return MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ListView(children: [
          _buildTeachingSlot('Prayer', 'prayer.jpg'),
          _buildTeachingSlot('Reading the Bible', 'bible_reading.jpg'),
          _buildTeachingSlot('Love', 'love.jpg'),
          _buildTeachingSlot('Family', 'family.jpg'),
          _buildTeachingSlot('Money', 'money.avif')
        ]));
  }

  Widget _buildTeachingSlot(final String teaching, final String img) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            child: Stack(children: [
              Positioned.fill(
                  child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(32)),
                      child: Image.asset('assets/images/$img', fit: BoxFit.cover))),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(32)),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onTeachingTap(teaching),
                    ),
                  ),
                ),
              ),
              Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(teaching, style: const TextStyle(fontSize: 32, color: Colors.white))))
            ])),
      ),
    );
  }

  // * Logic

  void _onChurchTap(final String church) {
    if (church == 'Belfast') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BelfastChurchPage()));
    } else if (church == 'Portadown') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PortadownChurchPage()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NorthCoastChurchPage()));
    }
  }

  void _onTeachingTap(final String teaching) {}
}
