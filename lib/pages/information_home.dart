import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/info/church_info.dart';
import '../models/info/ctrim_info.dart';
import '../models/info/testimonial_into.dart';
import '../utility/app_context.dart';
import '../utility/info_repository.dart';
import '../widgets/media/cached_image_widget.dart';
import 'information/church_info_page.dart';
import 'information/ctrim_info_page.dart';
import 'information/edit_info_body_page.dart';
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

  // Responsive breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;
  static const double _desktopBreakpoint = 1200;

  // Images - Information
  static const String _mission = 'https://drive.google.com/uc?id=1RWa_4vx6vo1dXCP3SNc6WglxYTBoRY9T';
  static const String _vision = 'https://drive.google.com/uc?id=1J7ZOPtjkb6iietVPyOdFMMIU29XwfjUX';
  static const String _community = 'https://drive.google.com/uc?id=1bxbAq9RDwUPcf8yAzOAu6Ah-OG3YC1BI';
  static const String _coreValues = 'https://drive.google.com/uc?id=1v4_0sABmlwLCvahonbVMs5GOLO8iWDzX';

  final InfoRepository _infoRepository = InfoRepository();
  late Future<List<ChurchInfo>> _churchesFuture;
  late Future<List<TestimonialInfo>> _testimonialsFuture;
  late Future<List<CtrimInfo>> _ctrimInfoFuture;

  @override
  void initState() {
    super.initState();
    _refreshInfoFutures(setStateCall: false);
  }

  void _refreshInfoFutures({final bool setStateCall = true}) {
    void assignFutures() {
      _churchesFuture = _infoRepository.fetchChurches();
      _testimonialsFuture = _infoRepository.fetchTestimonials();
      _ctrimInfoFuture = _infoRepository.fetchCtrimInfo();
    }

    if (setStateCall) {
      setState(assignFutures);
    } else {
      assignFutures();
    }
  }

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
    final bool isAreaAdmin = Provider.of<AppContext>(context).currentUser.isAreaAdmin;

    return FutureBuilder<List<ChurchInfo>>(
      future: _churchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildInfoErrorState(
            snapshot.error,
            isAreaAdmin: isAreaAdmin,
            addLabel: 'Add Church',
            addDescription: 'Create the first church information record.',
            onAdd: _onAddChurchTap,
          );
        }

        final churches = snapshot.data ?? const <ChurchInfo>[];
        if (churches.isEmpty && !isAreaAdmin) {
          return _buildEmptyInfoState('No church information available yet.');
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth;
            final int crossAxisCount = _getCrossAxisCount(screenWidth);
            final bool isWideScreen = screenWidth >= _tabletBreakpoint;
            final int itemCount = churches.length + (isAreaAdmin ? 1 : 0);

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
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (isAreaAdmin && index == churches.length) {
                    return _buildAddContentCard(
                      label: 'Add Church',
                      description: 'Create a new church information record.',
                      onTap: _onAddChurchTap,
                    );
                  }
                  return _buildChurchCard(churches[index]);
                },
              );
            }

            return MediaQuery.removePadding(
              removeTop: true,
              context: context,
              child: ListView.builder(
                key: const PageStorageKey<String>('information_churches_tab'),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (isAreaAdmin && index == churches.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildAddContentCard(
                        label: 'Add Church',
                        description: 'Create a new church information record.',
                        onTap: _onAddChurchTap,
                      ),
                    );
                  }
                  return _buildChurchSlot(churches[index]);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChurchCard(final ChurchInfo church) {
    final img = church.imgSrc;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _onChurchTap(church),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCardImage(img, 'info_church_${church.id}'),
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
                  church.title,
                  style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChurchSlot(final ChurchInfo church) {
    return InkWell(
        onTap: () => _onChurchTap(church),
        child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            child: Stack(children: [
              Positioned.fill(
                child: _buildCardImage(church.imgSrc, 'info_church_${church.id}'),
              ),
              Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(church.title, style: const TextStyle(fontSize: 36, color: Colors.white))))
            ])));
  }

  Widget _buildTestimonials() {
    final bool isAreaAdmin = Provider.of<AppContext>(context).currentUser.isAreaAdmin;

    return FutureBuilder<List<TestimonialInfo>>(
      future: _testimonialsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildInfoErrorState(
            snapshot.error,
            isAreaAdmin: isAreaAdmin,
            addLabel: 'Add Testimonial',
            addDescription: 'Create the first testimonial record.',
            onAdd: _onAddTestimonialTap,
          );
        }

        final testimonials = snapshot.data ?? const <TestimonialInfo>[];
        if (testimonials.isEmpty && !isAreaAdmin) {
          return _buildEmptyInfoState('No testimonials available yet.');
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = _getCrossAxisCount(screenWidth);
            final isWideScreen = screenWidth >= _tabletBreakpoint;
            final itemCount = testimonials.length + (isAreaAdmin ? 1 : 0);

            if (isWideScreen) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (isAreaAdmin && index == testimonials.length) {
                    return _buildAddContentCard(
                      label: 'Add Testimonial',
                      description: 'Create a new testimony record.',
                      onTap: _onAddTestimonialTap,
                    );
                  }
                  return _buildTestimonialCard(testimonials[index]);
                },
              );
            }

            return MediaQuery.removePadding(
              removeTop: true,
              context: context,
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (isAreaAdmin && index == testimonials.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildAddContentCard(
                        label: 'Add Testimonial',
                        description: 'Create a new testimony record.',
                        onTap: _onAddTestimonialTap,
                      ),
                    );
                  }
                  return _buildTestimonialSlot(testimonials[index]);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTestimonialCard(final TestimonialInfo testimonial) {
    final img = testimonial.imgSrc;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _onTestimonialTap(testimonial),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCardImage(img, 'info_testimonial_${testimonial.id}', alignment: Alignment.topCenter),
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
                        testimonial.name,
                        style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(testimonial.church, style: const TextStyle(fontSize: 14, color: Colors.white70))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialSlot(final TestimonialInfo testimonial) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: InkWell(
                onTap: () => _onTestimonialTap(testimonial),
                borderRadius: BorderRadius.circular(32),
                child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.32,
                    width: double.infinity,
                    child: Stack(children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(32)),
                          child: _buildCardImage(
                            testimonial.imgSrc,
                            'info_testimonial_${testimonial.id}',
                            alignment: Alignment.topCenter,
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
                              Text(testimonial.name, style: const TextStyle(fontSize: 24, color: Colors.white))
                            ]),
                            const SizedBox(height: 4),
                            Text(testimonial.church, style: const TextStyle(fontSize: 16, color: Colors.white70))
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
    final bool isAreaAdmin = Provider.of<AppContext>(context).currentUser.isAreaAdmin;

    return FutureBuilder<List<CtrimInfo>>(
      future: _ctrimInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildInfoErrorState(
            snapshot.error,
            isAreaAdmin: isAreaAdmin,
            addLabel: 'Add CTRIM Topic',
            addDescription: 'Create the first CTRIM information topic.',
            onAdd: _onAddCtrimTap,
          );
        }

        final infoRecords = snapshot.data ?? const <CtrimInfo>[];
        if (infoRecords.isEmpty && !isAreaAdmin) {
          return _buildEmptyInfoState('No CTRIM information available yet.');
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth >= _desktopBreakpoint ? 3 : (screenWidth >= _tabletBreakpoint ? 2 : 1);
            final isWideScreen = screenWidth >= _tabletBreakpoint;
            final itemCount = infoRecords.length + (isAreaAdmin ? 1 : 0);

            if (isWideScreen) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  // Keep cards tall enough for image + title + description without overflow.
                  childAspectRatio: crossAxisCount >= 3 ? 2.4 : 2.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (isAreaAdmin && index == infoRecords.length) {
                    return _buildAddContentCard(
                      label: 'Add CTRIM Topic',
                      description: 'Create a new teaching or information topic.',
                      onTap: _onAddCtrimTap,
                    );
                  }
                  return _buildCtrimInfoSlot(infoRecords[index]);
                },
              );
            }

            return MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (isAreaAdmin && index == infoRecords.length) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: _buildAddContentCard(
                        label: 'Add CTRIM Topic',
                        description: 'Create a new teaching or information topic.',
                        onTap: _onAddCtrimTap,
                      ),
                    );
                  }
                  return _buildCtrimInfoSlot(infoRecords[index]);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCtrimInfoSlot(final CtrimInfo info) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
                onTap: () => _onCtrimInfoTap(info),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(children: [
                      _buildCtrimThumbnail(info, colorScheme),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(info.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(info.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)
                      ])),
                      Icon(Icons.arrow_forward_ios, color: colorScheme.outline, size: 16)
                    ])))));
  }

  Widget _buildAddContentCard({
    required final String label,
    required final String description,
    required final VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxHeight < 130;

              if (compact) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, size: 30, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.add_circle_outline, size: 36, color: colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage(final String imageUrl, final String heroTag, {final Alignment alignment = Alignment.center}) {
    if (imageUrl.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 40),
      );
    }

    return CachedImageWidget(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      alignment: alignment,
      heroTag: heroTag,
    );
  }

  Widget _buildCtrimThumbnail(final CtrimInfo info, final ColorScheme colorScheme) {
    if (info.imgSrc.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.info, color: colorScheme.primary, size: 24),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 56,
        width: 56,
        child: CachedImageWidget(
          imageUrl: info.imgSrc,
          fit: BoxFit.cover,
          heroTag: 'info_ctrim_${info.id}',
        ),
      ),
    );
  }

  Widget _buildEmptyInfoState(final String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildInfoErrorState(
    final Object? error, {
    required final bool isAreaAdmin,
    required final String addLabel,
    required final String addDescription,
    required final VoidCallback onAdd,
  }) {
    final bool isPermissionError = error.toString().contains('permission-denied');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isPermissionError
                    ? 'The information collection is not readable with the current backend rules.'
                    : 'Something went wrong: $error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _refreshInfoFutures,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              if (isAreaAdmin) ...[
                const SizedBox(height: 16),
                _buildAddContentCard(
                  label: addLabel,
                  description: addDescription,
                  onTap: onAdd,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAddChurchTap() async {
    final changed =
        await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditInfoBodyPage.forChurch()));
    if (changed == true) {
      _refreshInfoFutures();
    }
  }

  Future<void> _onAddTestimonialTap() async {
    final changed =
        await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditInfoBodyPage.forTestimonial()));
    if (changed == true) {
      _refreshInfoFutures();
    }
  }

  Future<void> _onAddCtrimTap() async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditInfoBodyPage.forCtrim()));
    if (changed == true) {
      _refreshInfoFutures();
    }
  }

  void _onChurchTap(final ChurchInfo church) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChurchInfoPage(documentId: church.id))).then((_) {
      _refreshInfoFutures();
    });
  }

  void _onTestimonialTap(final TestimonialInfo testimonial) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => TestimonialInfoPage(documentId: testimonial.id)))
        .then((_) {
      _refreshInfoFutures();
    });
  }

  void _onCtrimInfoTap(final CtrimInfo info) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => CTRIMInfoPage(documentId: info.id))).then((_) {
      _refreshInfoFutures();
    });
  }
}
