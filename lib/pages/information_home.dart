import 'package:ctrim_app/pages/information/testimonial_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    'Cell Groups': 'Our core strategy in winning souls and strengthing with each other',
    'Devotionals': 'How do we take care of our relationship with God?',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NestedScrollView(
      controller: widget.scrollController,
      headerSliverBuilder: (_, __) => [
        SliverAppBar.large(
          title: Text(
            'CTRIM',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          floating: true,
          snap: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                _ctrimLogo,
                fit: BoxFit.contain,
                height: kToolbarHeight,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.church,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          bottom: TabBar(
            controller: widget.tabController,
            indicator: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(25),
            ),
            labelColor: colorScheme.onPrimary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: theme.textTheme.titleSmall,
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            isScrollable: true,
            tabs: const [
              Tab(text: 'About'),
              Tab(text: 'Churches'),
              Tab(text: 'Testimonials'),
              Tab(text: 'Information'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: widget.tabController,
        children: [
          _buildAbout(),
          _buildChurchesTab(),
          _buildTestimonials(),
          _buildCtrimInformationSection(),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    const String matthewVerse = '"Therefore go and make disciples of all nations, baptizing them in the '
        'name of the Father and of the Son and of the Holy Spirit, and '
        'teaching them to obey everything I have commanded you. And '
        'surely I am with you always, to the very end of the age."';
    const String visionParagraph = 'Our vision is to become like the early Church in the Book of Acts, effective '
        'and strategic in disciple making. Effective and strategic in harnessing the power of The Holy Spirit, causing '
        'them to multiply rapidly and having the power to turn the world upside down for the Glory of God.';

    const List<String> coreValues = [
      'I Am a True Disciple. Christ-likeness and Multiplying Ministry',
      'Caught by the Vision. Understand, Live and Transmit the Vision',
      'Committed to Cell Life. Evangelism, Leadership Development and Multiplication',
      'Passionate Spirituality Devotional Life, Prayer, Fasting and Holiness',
      'Submission to Authority Love, Honour and Respect My Leaders',
      'Commitment to Time Management and Invest My Time for the Kingdom of God',
      'Lifelong Relationship. Accountable and Responsible',
      'I Love Equipping and Training. Training is My Happy Hour',
      'I Am a Leader of 7 Disciples. I Am Born to Multiply',
      'Accomplishing Church Goal Setting. Support, Help and Fulfil the Goals',
      'I Want to See My Church Grow. I Pray, Work and Pay',
      'The Importance of Young People. I Will Prepare the Next Generation',
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero Introduction Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.church,
                  size: 48,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Christ the Redeemer International Ministries',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dedicated and committed to making true disciples who will passionately advance the Kingdom of God.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Mission Section
          _buildSectionCard(
            icon: Icons.flag,
            title: 'OUR MISSION',
            subtitle: 'To Win Souls and Make Disciples.',
            content: Column(
              children: [
                Text(
                  'Matthew 28:19-20',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    matthewVerse,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            theme: theme,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 20),

          // Vision Section
          _buildSectionCard(
            icon: Icons.visibility,
            title: 'OUR VISION',
            subtitle: 'To become an effective and strategic disciple-making church.',
            content: Text(
              visionParagraph,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
            theme: theme,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 20),

          // Core Values Section
          _buildSectionCard(
            icon: Icons.favorite,
            title: 'OUR CORE VALUES',
            subtitle: 'The foundation of what is really important to us',
            content: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Core values are the foundation of what is really important to us. It gives us CLARITY about who we are and what we stand for. It gives us the ability to STAY FOCUS on what matters most. It gives us UNITY, MATURITY and HEALTH to grow and multiply.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...coreValues.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
            theme: theme,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget content,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildChurchesTab() {
    return MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ListView(key: const PageStorageKey<String>('information_churches_tab'), children: [
          _buildChurchSlot('Belfast', 'assets/images/bel1.png'),
          _buildChurchSlot('Portadown', 'assets/images/port1.png'),
          _buildChurchSlot('North Coast', 'assets/images/northC1.png'),
          // _buildChurchSlot('Larne/Carrickfergus', 'assets/images/northC1.png'),
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
                      child: Text(church, style: const TextStyle(fontSize: 36, color: Colors.white))))
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
            child: InkWell(
                onTap: () => _onTestimonialTap(personName),
                borderRadius: BorderRadius.circular(32),
                child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.32,
                    width: double.infinity,
                    child: Stack(children: [
                      Positioned.fill(
                          child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(32)),
                              child: Hero(
                                  tag: 'initialTestimonialImage_$img', child: Image.asset(img, fit: BoxFit.cover)))),
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(32)),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Icon(Icons.person, color: Colors.white, size: 28),
                              const SizedBox(width: 8),
                              Text(personName, style: const TextStyle(fontSize: 24, color: Colors.white))
                            ]),
                            const SizedBox(height: 4),
                            const Text('Tap to read more...',
                                style: TextStyle(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic))
                          ]))
                    ])))));
  }

  Widget _buildMoreTestimonialSlot() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: InkWell(
                onTap: () => _onMoreTestimonialsTap(),
                borderRadius: const BorderRadius.all(Radius.circular(32)),
                child: Container(
                    height: MediaQuery.of(context).size.height * 0.32,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(32)),
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
                          colorScheme.primary.withOpacity(0.8),
                          colorScheme.secondary.withOpacity(0.8),
                        ])),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add, color: Colors.white, size: 48),
                      SizedBox(height: 16),
                      Text('More Testimonials',
                          style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Tap to see more testimonials...',
                          style: TextStyle(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic))
                    ])))));
  }

  Widget _buildCtrimInformationSection() {
    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView(children: [
          const SizedBox(height: 16),
          ..._ctrimInfoTopics.entries.map((entry) => _buildCtrimInfoSlot(entry.key, entry.value)).toList(),
          const SizedBox(height: 32)
        ]));
  }

  Widget _buildCtrimInfoSlot(final String topic, final String description) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
                onTap: () => _onCtrimInfoTap(topic),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.info, color: colorScheme.primary, size: 24)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(topic,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            )),
                        const SizedBox(height: 4),
                        Text(description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ))
                      ])),
                      Icon(Icons.arrow_forward_ios, color: colorScheme.outline, size: 16)
                    ])))));
  }

  void _onChurchTap(final String church) {
    HapticFeedback.lightImpact();
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
    HapticFeedback.lightImpact();
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

  void _onMoreTestimonialsTap() {
    HapticFeedback.lightImpact();
    // Navigate to more testimonials or implement additional functionality
  }

  void _onCtrimInfoTap(final String topic) {
    HapticFeedback.lightImpact();
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
