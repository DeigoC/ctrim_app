import 'package:ctrim_app/pages/information/testimonial_info_page.dart';
import 'package:flutter/material.dart';

import 'information/church_info_page.dart';
import 'information/ctrim_info_page.dart';

class InformationHome extends StatefulWidget {
  const InformationHome({super.key, required this.tabController, required this.scrollController});
  final TabController tabController;
  final ScrollController scrollController;
  @override
  State<InformationHome> createState() => _InformationHomeState();
}

class _InformationHomeState extends State<InformationHome> {
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';
  static const Map<String, String> _ctrimInfoTopics = {
    'Core Values': 'What do we live and work for?',
    '4XD Acts DNA': 'What is the framework we follow?',
    'Cell Groups': 'Our core strategy in winning souls and strengthing in each other',
    'Devotionals': 'How do we take care of our relationship with God?',
  };

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
        controller: widget.scrollController,
        headerSliverBuilder: (_, __) => [
              SliverAppBar(
                  title: const Text('CTRIM'),
                  centerTitle: false,
                  floating: true,
                  snap: true,
                  leading: Image.asset(_ctrimLogo, fit: BoxFit.contain, height: kToolbarHeight),
                  bottom: TabBar(controller: widget.tabController, isScrollable: true, tabs: const [
                    Tab(text: 'About'),
                    Tab(text: 'Churches'),
                    Tab(text: 'Testimonials'),
                    Tab(text: 'Information')
                  ]))
            ],
        body: TabBarView(
            controller: widget.tabController,
            children: [_buildAbout(), _buildChurchesTab(), _buildTestimonials(), _buildCtrimInformationSection()]));
  }

  Widget _buildAbout() {
    const String matthewVerse = '“Therefore go and make disciples of all nations, baptizing them in the '
        'name of the Father and of the Son and of the Holy Spirit, and '
        'teaching them to obey everything I have commanded you. And '
        'surely I am with you always, to the very end of the age."';
    const String visionParagraph = 'Our vision is to become like the early Church in the Book of Acts, effective '
        'and strategic in disciple making. Effective and strategic in harnessing the power of The Holy Spirit, causing '
        'them to multiply rapidly and having the power to turn the world upside down for the Glory of God.';

    const String coreValuesParagraph = """
1. I Am a True Disciple. Christ-likeness and Multiplying Ministry

2. Caught by the Vision. Understand, Live and Transmit the Vision

3. Committed to Cell Life. Evangelism, Leadership Development and Multiplication

4. Passionate Spirituality Devotional Life, Prayer, Fasting and Holiness

5. Submission to Authority Love, Honour and Respect My Leaders

6. Commitment to Time Management and Invest My Time for the Kingdom of God

7. Lifelong Relationship. Accountable and Responsible

8. I Love Equipping and Training. Training is My Happy Hour

9. I Am a Leader of 7 Disciples. I Am Born to Multiply

10. Accomplishing Church Goal Setting. Support, Help and Fulfil the Goals

11. I Want to See My Church Grow. I Pray, Work and Pay

12. The Importance of Young People. I Will Prepare the Next Generation
""";

    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView(padding: const EdgeInsets.symmetric(horizontal: 8), children: const [
          // Image.network('https://upload.wikimedia.org/wikipedia/commons/1/15/Cat_August_2010-4.jpg'),
          SizedBox(height: 32),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                  'Christ the Redeemer International Ministries is dedicated and committed to making true disciples who will passionately advance the Kingdom of God.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18))),
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
          SizedBox(height: 32),
          Divider(thickness: 1),
          SizedBox(height: 32),
          Text('OUR CORE VALUES',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 18),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
                'Core values are the foundation of what is really important to us. It gives us CLARITY about who we are and what we stand for. It gives us the ability to STAY FOCUS on what matters most. It gives us UNITY, MATURITY and HEALTH to grow and multiply. ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18)),
          ),
          SizedBox(height: 18),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(coreValuesParagraph, textAlign: TextAlign.left, style: TextStyle(fontSize: 18)),
          ),
        ]));
  }

  Widget _buildChurchesTab() {
    return MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ListView(key: const PageStorageKey<String>('information_churches_tab'), children: [
          _buildChurchSlot('Belfast', 'assets/images/bel1.png'),
          _buildChurchSlot('Portadown', 'assets/images/port1.png'),
          _buildChurchSlot('North Coast', 'assets/images/northC1.png'),
          _buildChurchSlot('Larne/Carrickfergus', 'assets/images/northC1.png'),
        ]));
  }

  Widget _buildChurchSlot(final String church, final String img) {
    return InkWell(
        onTap: () => _onChurchTap(church),
        child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            child: Stack(children: [
              Positioned.fill(child: Hero(tag: 'initialChurchImage_$img', child: Image.asset(img, fit: BoxFit.cover))),
              Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(church, style: const TextStyle(fontSize: 32, color: Colors.white))))
            ])));
  }

  Widget _buildTestimonials() {
    return MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ListView(
            children: [_buildTestimonialSlot('Maije', 'assets/images/maije.jpg'), _buildMoreTestimonialSlot()]));
  }

  Widget _buildTestimonialSlot(final String personName, final String img) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.32,
                width: double.infinity,
                child: Stack(children: [
                  Positioned.fill(
                      child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(32)),
                          child:
                              Hero(tag: 'initialTestimonialImage_$img', child: Image.asset(img, fit: BoxFit.cover)))),
                  Positioned.fill(
                      child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(32)),
                          child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _onTestimonialTap(personName),
                              )))),
                  Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(personName, style: const TextStyle(fontSize: 32, color: Colors.white)),
                              const Text(
                                'Going to add a bit more text just as a tease or something. Might be this long',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              )
                            ],
                          )))
                ]))));
  }

  Widget _buildMoreTestimonialSlot() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.10,
                width: double.infinity,
                child: const Stack(children: [
                  Align(
                      alignment: Alignment.center,
                      child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("More on the way...!", style: TextStyle(fontSize: 24))))
                ]))));
  }

  Widget _buildCtrimInformationSection() {
    return MediaQuery.removePadding(
      removeTop: true,
      context: context,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemCount: _ctrimInfoTopics.length,
            itemBuilder: (_, index) => _buildCtrimInfoCard(
                _ctrimInfoTopics[_ctrimInfoTopics.keys.elementAt(index)]!, _ctrimInfoTopics.keys.elementAt(index))),
      ),
    );
  }

  Widget _buildCtrimInfoCard(final String description, final String topic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () => _openCtrimInfoPage(topic),
        child: Card(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(
                    topic,
                    style: const TextStyle(fontSize: 21),
                  ),
                  Text(description, style: const TextStyle(fontSize: 16))
                ]))),
      ),
    );
  }

  // * Logic

  void _onChurchTap(final String church) {
    if (church == 'Belfast') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ChurchInfoPage(
                    jsonPath: 'assets/info/churches/belfast.json',
                    imageSrc: 'assets/images/bel1.png',
                  )));
    } else if (church == 'Portadown') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ChurchInfoPage(
                  jsonPath: 'assets/info/churches/portadown.json', imageSrc: 'assets/images/port1.png')));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ChurchInfoPage(
                  jsonPath: 'assets/info/churches/nc.json', imageSrc: 'assets/images/northC1.png')));
    }
  }

  void _onTestimonialTap(final String person) {
    switch (person) {
      case 'Maije':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const TestimonialInfoPage(
                      jsonPath: 'assets/info/testimonials/maije.json',
                      initialImageSrc: 'assets/images/maije.jpg',
                    )));
        break;
      default:
    }
  }

  void _openCtrimInfoPage(final String topic) {
    switch (topic) {
      case 'Core Values':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CTRIMInfoPage(
                      jsonPath: "assets/info/ctrim_info/core_values.json",
                    )));
        break;
      case '4XD Acts DNA':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CTRIMInfoPage(jsonPath: "assets/info/ctrim_info/4xd.json")));
        break;
      case 'Cell Groups':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CTRIMInfoPage(jsonPath: "assets/info/ctrim_info/cell_group.json")));
        break;
      case 'Devotionals':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CTRIMInfoPage(jsonPath: "assets/info/ctrim_info/devotionals.json")));
        break;
    }
  }
}
