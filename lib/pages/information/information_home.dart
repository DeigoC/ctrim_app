import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/info/church_info.dart';
import '../../models/info/ctrim_info.dart';
import '../../models/info/testimonial_info.dart';
import '../../utility/app_context.dart';
import '../../utility/cache/directory_cache.dart';
import '../../utility/info_repository.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/section_tab_bar.dart';
import 'about_tab.dart';
import 'churches_tab.dart';
import 'ctrim_info_list_tab.dart';
import 'testimonials_tab.dart';

class InformationHome extends StatefulWidget {
  const InformationHome({
    super.key,
    required this.tabController,
    required this.scrollController,
  });

  static const String ctrimLogo = 'assets/images/ctrim_logo.png';

  static const List<({String label, IconData icon})> sections = [
    (label: 'About', icon: Icons.info_outline),
    (label: 'Churches', icon: Icons.church),
    (label: 'Testimonials', icon: Icons.format_quote),
    (label: 'Information', icon: Icons.menu_book),
  ];

  final TabController tabController;
  final ScrollController scrollController;

  @override
  State<InformationHome> createState() => _InformationHomeState();
}

class _InformationHomeState extends State<InformationHome> {
  final InfoRepository _infoRepository = InfoRepository();
  final DirectoryCacheCoordinator _directories =
      DirectoryCacheCoordinator.instance;
  late Future<List<ChurchInfo>> _churchesFuture;
  late Future<List<TestimonialInfo>> _testimonialsFuture;
  late Future<List<CtrimInfo>> _ctrimInfoFuture;
  late int _infoEpoch;

  @override
  void initState() {
    super.initState();
    _infoEpoch = _directories.epoch;
    _directories.addListener(_onDirectories);
    widget.tabController.addListener(_onTabChanged);
    _refreshInfoFutures(setStateCall: false);
  }

  @override
  void dispose() {
    _directories.removeListener(_onDirectories);
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onDirectories() {
    if (!mounted || _directories.epoch == _infoEpoch) return;
    _infoEpoch = _directories.epoch;
    _refreshInfoFutures();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  void _refreshInfoFutures({
    final bool setStateCall = true,
    final bool force = false,
  }) {
    if (force) {
      final pref = Provider.of<AppContext>(context, listen: false).sharedPref;
      if (!pref.canRefreshInfo) return;
      pref.setInfoRefreshTime();
    }

    void assignFutures() {
      _churchesFuture = _infoRepository.fetchChurches(forceRefresh: force);
      _testimonialsFuture =
          _infoRepository.fetchTestimonials(forceRefresh: force);
      _ctrimInfoFuture = _infoRepository.fetchCtrimInfo(forceRefresh: force);
    }

    if (setStateCall) {
      setState(assignFutures);
    } else {
      assignFutures();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showTabBar =
        !ResponsiveLayout.isWideScreen(MediaQuery.sizeOf(context).width);
    return _buildInformationScrollView(showTabBar: showTabBar);
  }

  Widget _buildInformationScrollView({required bool showTabBar}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NestedScrollView(
      controller: widget.scrollController,
      headerSliverBuilder: (_, __) => [
        SliverAppBar.large(
          title: Text(
            showTabBar
                ? 'CTRIM'
                : InformationHome.sections[widget.tabController.index].label,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          floating: true,
          snap: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          leading: showTabBar
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      InformationHome.ctrimLogo,
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
                )
              : null,
          bottom: showTabBar
              ? SectionTabBar(
                  controller: widget.tabController,
                  tabs: InformationHome.sections
                      .map((section) => Tab(text: section.label))
                      .toList(),
                )
              : null,
        ),
      ],
      body: TabBarView(
        controller: widget.tabController,
        children: [
          const InformationAboutTab(),
          ChurchesTab(
            churchesFuture: _churchesFuture,
            onRefresh: () => _refreshInfoFutures(force: true),
          ),
          TestimonialsTab(
            testimonialsFuture: _testimonialsFuture,
            onRefresh: () => _refreshInfoFutures(force: true),
          ),
          CtrimInfoListTab(
            ctrimInfoFuture: _ctrimInfoFuture,
            onRefresh: () => _refreshInfoFutures(force: true),
          ),
        ],
      ),
    );
  }
}
