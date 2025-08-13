import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../firebase/db_managers/event_db_manager.dart';
import '../models/event/event_head.dart';
import '../utility/app_context.dart';
import '../utility/dialog_manager.dart';
import '../widgets/posts/post_head.dart';

class ViewEventsHome extends StatefulWidget {
  const ViewEventsHome({super.key, required this.rebuildFunction, required this.scrollController});
  final Function() rebuildFunction;
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';
  final ScrollController scrollController;

  @override
  State<ViewEventsHome> createState() => _ViewEventsHomeState();
}

class _ViewEventsHomeState extends State<ViewEventsHome> with TickerProviderStateMixin {
  late final AppContext _appContext;
  late AnimationController _refreshAnimationController;
  late Animation<double> _refreshAnimation;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    _appContext.sortPostsByIndex();

    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshAnimationController, curve: Curves.easeOut),
    );

    super.initState();
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<AppContext>(builder: (context, appContext, child) {
      final bool defaultFilter = appContext.postSortIndex == 0;
      final List<EventHead> eventHeads =
          defaultFilter ? List.empty() : List.from(appContext.eventHeads, growable: true);

      if (!defaultFilter) {
        if (appContext.postSortIndex == 1) {
          eventHeads.removeWhere(
              (e) => e.eventDate == null || e.eventDate!.add(const Duration(hours: 12)).isBefore(DateTime.now()));
        } else if (appContext.postSortIndex == 2) {
          eventHeads.removeWhere((e) => e.eventDate == null || e.eventDate!.isAfter(DateTime.now()));
        } else if (appContext.postSortIndex == 3) {
          eventHeads.removeWhere((e) => !appContext.sharedPref.bookmarkedPosts.contains(e.id));
        }
      }

      final int itemCount = defaultFilter ? appContext.eventHeads.length : eventHeads.length;
      final double webHorizontalPadding =
          MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 5 : 0;

      return RefreshIndicator(
        edgeOffset: (kToolbarHeight * 2) - 8,
        backgroundColor: colorScheme.surface,
        color: colorScheme.primary,
        onRefresh: () => _onRefresh().then((value) {
          _refreshAnimationController.forward().then((_) {
            _refreshAnimationController.reset();
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: !appContext.currentUser.isLeader ? SnackBarBehavior.floating : null,
            backgroundColor: colorScheme.inverseSurface,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: colorScheme.onInverseSurface, size: 20),
                const SizedBox(width: 8),
                Text(
                  'You are up to date!',
                  style: TextStyle(color: colorScheme.onInverseSurface),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ));
        }),
        child: CustomScrollView(
            controller: widget.scrollController,
            key: const PageStorageKey<String>('events_page'),
            slivers: [
              SliverAppBar.large(
                title: Row(
                  children: [
                    Icon(
                      Icons.campaign,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Bulletin',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                centerTitle: false,
                floating: true,
                snap: true,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: colorScheme.surfaceTint,
                actions: [
                  AnimatedBuilder(
                    animation: _refreshAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _refreshAnimation.value * 2 * 3.14159,
                        child: IconButton(
                          onPressed: () => _showFilterModel(context),
                          icon: const Icon(Icons.sort),
                          tooltip: 'Sort & Filter',
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
                            foregroundColor: colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      ViewEventsHome._ctrimLogo,
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
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: _buildFilterIndicator(appContext, colorScheme),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: webHorizontalPadding + 8,
                  vertical: 8,
                ),
                sliver: itemCount == 0
                    ? _buildEmptyState(colorScheme, theme)
                    : SliverList.separated(
                        itemCount: itemCount,
                        itemBuilder: (_, index) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: PostHead(
                            thisHead: defaultFilter ? appContext.eventHeads[index] : eventHeads[index],
                            updatePost: () => widget.rebuildFunction(),
                          ),
                        ),
                        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Bottom padding
            ]),
      );
    });
  }

  Widget _buildFilterIndicator(AppContext appContext, ColorScheme colorScheme) {
    if (appContext.postSortIndex == 0) return const SizedBox.shrink();

    final Map<int, Map<String, dynamic>> filterInfo = {
      1: {'label': 'Upcoming Events', 'icon': Icons.upcoming, 'color': Colors.green},
      2: {'label': 'Recent Events', 'icon': Icons.history, 'color': Colors.orange},
      3: {'label': 'Bookmarked', 'icon': Icons.bookmark, 'color': Colors.purple},
    };

    final info = filterInfo[appContext.postSortIndex];
    if (info == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (info['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (info['color'] as Color).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            info['icon'] as IconData,
            size: 16,
            color: info['color'] as Color,
          ),
          const SizedBox(width: 8),
          Text(
            'Showing: ${info['label']}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: info['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note,
                size: 64,
                color: colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Events Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no events matching your current filter.\nTry adjusting your sort preferences.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => _showFilterModel(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_alt, size: 20),
                  SizedBox(width: 8),
                  Text('Change Filter'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModel(final BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
        showDragHandle: true,
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        builder: (_) => SafeArea(
                child: BulletinSettingSheet(
              sortIndex: _appContext.postSortIndex,
              relevancySort: () => _onSortPosts(0),
              descendingEventDate: () => _onSortPosts(1),
              ascendingEventDate: () => _onSortPosts(2),
              showBookmarks: () => _onSortPosts(3),
            )));
  }

  // * Logic
  Future<void> _onRefresh() async {
    if (_appContext.sharedPref.canRefreshPosts) {
      debugPrint('refreshing now!');
      await _refreshPosts();
      _appContext.sharedPref.setPostRefreshTime();
    } else {
      debugPrint('cannot refresh cause of timer');
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void _onSortPosts(int newSortIndex) {
    if (newSortIndex != _appContext.postSortIndex) {
      setState(() {
        _appContext.setPostSortIndex(newSortIndex);
        _appContext.sortPostsByIndex();
      });
    }
  }

  Future<void> _refreshPosts() async {
    final EventHeadDBManager headDBManager = EventHeadDBManager();
    final heads = await headDBManager.fetchEventHeads();
    setState(() {
      _appContext.setRefreshedHeads(heads);
    });
  }
}

class BulletinSettingSheet extends StatefulWidget {
  const BulletinSettingSheet(
      {super.key,
      required this.sortIndex,
      required this.relevancySort,
      required this.descendingEventDate,
      required this.ascendingEventDate,
      required this.showBookmarks});
  final int sortIndex;
  final void Function() relevancySort, descendingEventDate, ascendingEventDate, showBookmarks;

  @override
  State<BulletinSettingSheet> createState() => _BulletinSettingSheetState();
}

class _BulletinSettingSheetState extends State<BulletinSettingSheet> with TickerProviderStateMixin {
  int _sortIndex = 0;
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    _sortIndex = widget.sortIndex;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimations = List.generate(4, (index) {
      return Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.15,
          0.6 + (index * 0.1),
          curve: Curves.easeOutBack,
        ),
      ));
    });

    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.sort,
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
                          'Sort & Filter',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose how to organize your events',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.outline.withOpacity(0.1),
                    colorScheme.outline.withOpacity(0.3),
                    colorScheme.outline.withOpacity(0.1),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Filter Options
            ..._buildFilterOptions(theme, colorScheme),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilterOptions(ThemeData theme, ColorScheme colorScheme) {
    final List<Map<String, dynamic>> options = [
      {
        'index': 0,
        'title': 'Relevancy',
        'subtitle': 'See the most relevant posts first',
        'icon': Icons.star_rounded,
        'color': Colors.amber,
      },
      {
        'index': 1,
        'title': 'Upcoming Events',
        'subtitle': 'Exciting events happening soon',
        'icon': Icons.upcoming,
        'color': Colors.green,
      },
      {
        'index': 2,
        'title': 'Recent Events',
        'subtitle': 'See what you missed',
        'icon': Icons.history,
        'color': Colors.orange,
      },
      {
        'index': 3,
        'title': 'Bookmarks',
        'subtitle': 'Posts you want to keep track of',
        'icon': Icons.bookmark_rounded,
        'color': Colors.purple,
        'hasHelp': true,
      },
    ];

    return options.map((option) {
      final index = option['index'] as int;
      final isSelected = _sortIndex == index;

      return SlideTransition(
        position: _slideAnimations[index],
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? colorScheme.primary.withOpacity(0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: ListTile(
            title: Text(
              option['title'] as String,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              option['subtitle'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? colorScheme.onPrimaryContainer.withOpacity(0.8) : colorScheme.onSurfaceVariant,
              ),
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (option['color'] as Color).withOpacity(0.2)
                    : (option['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                option['icon'] as IconData,
                color: option['color'] as Color,
                size: 20,
              ),
            ),
            trailing: option['hasHelp'] == true
                ? IconButton(
                    icon: Icon(
                      Icons.help_outline,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _onBookmarkedHelp,
                    tooltip: 'Learn about bookmarks',
                  )
                : isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: colorScheme.primary,
                        size: 20,
                      )
                    : null,
            selected: isSelected,
            onTap: () => _onSortClick(index),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      );
    }).toList();
  }

  void _onSortClick(final int sortIndex) {
    HapticFeedback.selectionClick();
    Navigator.pop(context); // close the modal
    setState(() {
      _sortIndex = sortIndex;
      switch (sortIndex) {
        case 0:
          widget.relevancySort();
          break;
        case 1:
          widget.descendingEventDate();
          break;
        case 2:
          widget.ascendingEventDate();
          break;
        case 3:
          widget.showBookmarks();
          break;
      }
    });
  }

  void _onBookmarkedHelp() {
    HapticFeedback.lightImpact();
    DialogManager.showAlertDialog(
        context: context,
        title: 'Bookmarked Posts',
        content:
            'You will be notified of updates made to the posts you bookmark.\n\nTo bookmark a post, tap and hold on any event card.');
  }
}
