import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/media/cached_image_widget.dart';
import 'information/church_info_page.dart';
import 'information/ctrim_info_page.dart';
import 'information/testimonial_info_page.dart';

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

  // Responsive breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;
  static const double _desktopBreakpoint = 1200;

  // Images - Churches
  static const String _bel1 = 'https://drive.google.com/uc?id=1yb7QD69yvUBdBxdtIHTbcdPQFfFWCFuj';
  static const String _port1 = 'https://drive.google.com/uc?id=165KdT-ldkD_hOq9LxsNvvfvlyAIC24HQ';
  static const String _northC1 = 'https://drive.google.com/uc?id=1o3Zoot7i99_0OFQcEna5BC84Z-2VXVXX';

  // Images - Testimonials
  static const String _maije = 'https://drive.google.com/uc?id=1Ble52s0pPk9em4Xhhr7fULqP5EPSkabr';
  static const String _ching = 'https://drive.google.com/uc?id=1AdMQ35g2hDXDuka_DwBTGutq3fZYvGRU';
  static const String _allen = 'https://drive.google.com/uc?id=1LF2aHii5ZcH1-Eo-uvepLbnA81cVWNEA';
  static const String _clement = 'https://drive.google.com/uc?id=10asayDlBozgIZoAWbxpcpmv_VZ230Wwm';
  static const String _cherry = 'https://drive.google.com/uc?id=1y8e1dtqQezw2-C0qVvRmo8cbqApUZriu';

  // Images - Information
  static const String _mission = 'https://drive.google.com/uc?id=1RWa_4vx6vo1dXCP3SNc6WglxYTBoRY9T';
  static const String _vision = 'https://drive.google.com/uc?id=1J7ZOPtjkb6iietVPyOdFMMIU29XwfjUX';
  static const String _community = 'https://drive.google.com/uc?id=1bxbAq9RDwUPcf8yAzOAu6Ah-OG3YC1BI';
  static const String _coreValues = 'https://drive.google.com/uc?id=1v4_0sABmlwLCvahonbVMs5GOLO8iWDzX';

  // Locations
  static const String _belfast = 'Belfast';
  static const String _northcoast = 'Northcoast Derry/Londonderry';

  // Testimonial names
  static const String _maijeName = 'Maije';
  static const String _chingName = 'Ching';
  static const String _allenName = 'Allen';
  static const String _clementName = 'Clement';
  static const String _cherryName = 'Cherry';

  bool _isMobile(double width) => width < _mobileBreakpoint;

  int _getCrossAxisCount(double width) {
    if (width >= _desktopBreakpoint) return 3;
    if (width >= _tabletBreakpoint) return 2;
    return 1;
  }

  double _getMaxContentWidth(double width) {
    if (width >= _desktopBreakpoint) return 1400;
    if (width >= _tabletBreakpoint) return 1000;
    return width;
  }

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final maxWidth = _getMaxContentWidth(screenWidth);
        final horizontalPadding = _isMobile(screenWidth) ? 16.0 : 32.0;
        final isWideScreen = screenWidth >= _tabletBreakpoint;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
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

                  // Community Fellowship Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedImageWidget(
                      imageUrl: _community,
                      height: isWideScreen ? 250 : 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mission and Vision Sections - Responsive Layout
                  if (isWideScreen)
                    // Wide screen: Side-by-side layout
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mission Section
                        Expanded(
                          child: _buildSectionCard(
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
                                const SizedBox(height: 16),
                                // Mission & Evangelism Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedImageWidget(
                                    imageUrl: _mission,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Vision Section
                        Expanded(
                          child: _buildSectionCard(
                            icon: Icons.visibility,
                            title: 'OUR VISION',
                            subtitle: 'To become an effective and strategic disciple-making church.',
                            content: Column(
                              children: [
                                Text(
                                  visionParagraph,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Church Vision & Growth Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedImageWidget(
                                    imageUrl: _vision,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    )
                  else
                    // Mobile: Stacked layout
                    Column(
                      children: [
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
                              const SizedBox(height: 16),
                              // Mission & Evangelism Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedImageWidget(
                                  imageUrl: _mission,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
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
                          content: Column(
                            children: [
                              Text(
                                visionParagraph,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Church Vision & Growth Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedImageWidget(
                                  imageUrl: _vision,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                      ],
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
                        // Core Values Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedImageWidget(
                            imageUrl: _coreValues,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
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
            ),
          ),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final int crossAxisCount = _getCrossAxisCount(screenWidth);
        final bool isWideScreen = screenWidth >= _tabletBreakpoint;

        final churches = [
          {'name': 'Belfast', 'image': _bel1},
          {'name': 'Portadown', 'image': _port1},
          {'name': 'North Coast', 'image': _northC1},
        ];

        if (isWideScreen) {
          return GridView.builder(
            key: const PageStorageKey<String>('information_churches_tab'),
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 16 / 9,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: churches.length,
            itemBuilder: (context, index) {
              final church = churches[index];
              return _buildChurchCard(church['name']!, church['image']!);
            },
          );
        }

        return MediaQuery.removePadding(
          removeTop: true,
          context: context,
          child: ListView(
            key: const PageStorageKey<String>('information_churches_tab'),
            children: [
              _buildChurchSlot('Belfast', _bel1),
              _buildChurchSlot('Portadown', _port1),
              _buildChurchSlot('North Coast', _northC1),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChurchCard(String church, String img) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _onChurchTap(church),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedImageWidget(
              imageUrl: img,
              fit: BoxFit.cover,
              heroTag: 'initialChurchImage_$img',
            ),
            Container(
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
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  church,
                  style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChurchSlot(final String church, final String img) {
    return InkWell(
        onTap: () => _onChurchTap(church),
        child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            child: Stack(children: [
              Positioned.fill(
                child: CachedImageWidget(
                  imageUrl: img,
                  fit: BoxFit.cover,
                  heroTag: 'initialChurchImage_$img',
                ),
              ),
              Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(church, style: const TextStyle(fontSize: 36, color: Colors.white))))
            ])));
  }

  Widget _buildTestimonials() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final crossAxisCount = _getCrossAxisCount(screenWidth);
        final isWideScreen = screenWidth >= _tabletBreakpoint;

        if (isWideScreen) {
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: crossAxisCount,
            childAspectRatio: 16 / 9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildTestimonialCard('Maije', _maije, _northcoast),
              _buildTestimonialCard('Ching', _ching, _belfast),
              _buildTestimonialCard('Allen', _allen, _belfast),
              _buildTestimonialCard('Clement', _clement, _belfast),
              _buildTestimonialCard('Cherry', _cherry, _belfast),
              _buildMoreComingSoonCard(),
            ],
          );
        }

        return MediaQuery.removePadding(
          removeTop: true,
          context: context,
          child: ListView(
            children: [
              _buildTestimonialSlot('Maije', _maije, _northcoast),
              _buildTestimonialSlot('Ching', _ching, _belfast),
              _buildTestimonialSlot('Allen', _allen, _belfast),
              _buildTestimonialSlot('Clement', _clement, _belfast),
              _buildTestimonialSlot('Cherry', _cherry, _belfast),
              _buildMoreComingSoon(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestimonialCard(final String personName, final String img, final String location) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _onTestimonialTap(personName),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedImageWidget(
              imageUrl: img,
              fit: BoxFit.cover,
              heroTag: 'initialTestimonialImage_$img',
            ),
            Container(
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
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        personName,
                        style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(location, style: const TextStyle(fontSize: 14, color: Colors.white70))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreComingSoonCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade300,
              Colors.grey.shade500,
            ],
          ),
        ),
        child: const Center(
          child: Text(
            'More Coming Soon...',
            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreComingSoon() {
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
                  const Center(
                      child: Text('More Coming Soon...',
                          style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)))
                ]))));
  }

  Widget _buildTestimonialSlot(final String personName, final String img, final String location) {
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
                          child: CachedImageWidget(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            heroTag: 'initialTestimonialImage_$img',
                          ),
                        ),
                      ),
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
                            Text(location, style: const TextStyle(fontSize: 16, color: Colors.white70))
                          ]))
                    ])))));
  }

  // TODO: should only be for admin
  // Widget _buildMoreTestimonialSlot() {
  //   final colorScheme = Theme.of(context).colorScheme;

  //   return Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
  //       child: Card(
  //           elevation: 2,
  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
  //           child: InkWell(
  //               onTap: () => _onMoreTestimonialsTap(),
  //               borderRadius: const BorderRadius.all(Radius.circular(32)),
  //               child: Container(
  //                   height: MediaQuery.of(context).size.height * 0.32,
  //                   width: double.infinity,
  //                   decoration: BoxDecoration(
  //                       borderRadius: const BorderRadius.all(Radius.circular(32)),
  //                       gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
  //                         colorScheme.primary.withOpacity(0.8),
  //                         colorScheme.secondary.withOpacity(0.8),
  //                       ])),
  //                   child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
  //                     Icon(Icons.add, color: Colors.white, size: 48),
  //                     SizedBox(height: 16),
  //                     Text('More Testimonials',
  //                         style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
  //                     SizedBox(height: 8),
  //                     Text('Tap to see more testimonials...',
  //                         style: TextStyle(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic))
  //                   ])))));
  // }

  Widget _buildCtrimInformationSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final crossAxisCount = screenWidth >= _desktopBreakpoint ? 3 : (screenWidth >= _tabletBreakpoint ? 2 : 1);
        final isWideScreen = screenWidth >= _tabletBreakpoint;

        if (isWideScreen) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 3.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _ctrimInfoTopics.length,
            itemBuilder: (context, index) {
              final entry = _ctrimInfoTopics.entries.elementAt(index);
              return _buildCtrimInfoSlot(entry.key, entry.value);
            },
          );
        }

        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView(
            children: [
              const SizedBox(height: 16),
              ..._ctrimInfoTopics.entries.map((entry) => _buildCtrimInfoSlot(entry.key, entry.value)).toList(),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCtrimInfoSlot(final String topic, final String description) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // TODO: Add topic-specific images for each CTRIM info card
    // Core Values: Image of people embodying values (serving, praying, studying)
    // 4XD Acts DNA: Diagram or visual representation of the 4XD framework
    // Cell Groups: Small group meeting, intimate fellowship setting
    // Devotionals: Person reading Bible, prayer journal, quiet time setting
    // Recommended: Thumbnail size 80x80 or 100x100, rounded corners

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
                      // TODO: Replace this icon container with actual image
                      // Container with ClipRRect and Image.asset for rounded image thumbnail
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
                    imageSrc: _bel1,
                  )));
    } else if (church == 'Portadown') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ChurchInfoPage(jsonPath: 'assets/info/churches/portadown.json', imageSrc: _port1)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ChurchInfoPage(jsonPath: 'assets/info/churches/nc.json', imageSrc: _northC1)));
    }
  }

  void _onTestimonialTap(final String person) {
    HapticFeedback.lightImpact();

    void navigateToTestimonialPage(final String jsonPath, final String imageSrc) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TestimonialInfoPage(
                    jsonPath: jsonPath,
                    initialImageSrc: imageSrc,
                  )));
    }

    switch (person) {
      case _maijeName:
        navigateToTestimonialPage('assets/info/testimonials/maije.json', _maije);
        break;
      case _chingName:
        navigateToTestimonialPage('assets/info/testimonials/ching.json', _ching);
        break;
      case _allenName:
        navigateToTestimonialPage('assets/info/testimonials/allen.json', _allen);
        break;
      case _clementName:
        navigateToTestimonialPage('assets/info/testimonials/clement.json', _clement);
        break;
      case _cherryName:
        navigateToTestimonialPage('assets/info/testimonials/cherry.json', _cherry);
        break;
      default:
    }
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
