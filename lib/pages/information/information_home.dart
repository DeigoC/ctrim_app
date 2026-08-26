import 'package:flutter/material.dart';

import '../../models/info/church_info.dart';
import '../../models/info/ctrim_info.dart';
import '../../models/info/testimonial_info.dart';
import '../../utility/info_repository.dart';
import '../../utility/responsive_layout.dart';
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

  final TabController tabController;
  final ScrollController scrollController;

  @override
  State<InformationHome> createState() => _InformationHomeState();
}

class _InformationHomeState extends State<InformationHome> {
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';

  static const List<({String label, IconData icon})> _sections = [
    (label: 'About', icon: Icons.info_outline),
    (label: 'Churches', icon: Icons.church),
    (label: 'Testimonials', icon: Icons.format_quote),
    (label: 'Information', icon: Icons.menu_book),
  ];

  final InfoRepository _infoRepository = InfoRepository();
  late Future<List<ChurchInfo>> _churchesFuture;
  late Future<List<TestimonialInfo>> _testimonialsFuture;
  late Future<List<CtrimInfo>> _ctrimInfoFuture;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
    _refreshInfoFutures(setStateCall: false);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final useSideNav =
        ResponsiveLayout.isWideScreen(MediaQuery.sizeOf(context).width);

    if (useSideNav) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInformationSectionNav(context),
          const VerticalDivider(width: 1),
          Expanded(child: _buildInformationScrollView(showTabBar: false)),
        ],
      );
    }

    return _buildInformationScrollView(showTabBar: true);
  }

  Widget _buildInformationSectionNav(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: 220,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'CTRIM',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              for (var index = 0; index < _sections.length; index++)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: ListTile(
                    selected: widget.tabController.index == index,
                    selectedTileColor: colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: Icon(
                      _sections[index].icon,
                      color: widget.tabController.index == index
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      _sections[index].label,
                      style: TextStyle(
                        fontWeight: widget.tabController.index == index
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      if (widget.tabController.index != index) {
                        widget.tabController.animateTo(index);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInformationScrollView({required bool showTabBar}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NestedScrollView(
      controller: widget.scrollController,
      headerSliverBuilder: (_, __) => [
        SliverAppBar.large(
          title: Text(
            showTabBar ? 'CTRIM' : _sections[widget.tabController.index].label,
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
                )
              : null,
          bottom: showTabBar
              ? TabBar(
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
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  isScrollable: true,
                  tabs: _sections
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
            onRefresh: () => _refreshInfoFutures(),
          ),
          TestimonialsTab(
            testimonialsFuture: _testimonialsFuture,
            onRefresh: () => _refreshInfoFutures(),
          ),
          CtrimInfoListTab(
            ctrimInfoFuture: _ctrimInfoFuture,
            onRefresh: () => _refreshInfoFutures(),
          ),
        ],
      ),
    );
  }
}
