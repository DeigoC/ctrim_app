import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/event/event_head.dart';
import '../models/post_tag.dart';
import '../utility/app_context.dart';
import '../utility/dialog_manager.dart';
import '../utility/event_heads_repository.dart';
import '../utility/responsive_layout.dart';
import '../widgets/action_sheet.dart';
import '../widgets/bulletin/bulletin_first_time_dialog.dart';
import '../widgets/post_tag_chip.dart';
import '../widgets/posts/post_head.dart';
import '../utility/post_tag_helpers.dart';
import '../src/localization/app_localizations.dart';

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
  final Set<String> _selectedPostTagIDs = {};

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

    // Show first-time dialog if user hasn't seen it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_appContext.sharedPref.hasSeenBulletinDialog) {
        _showBulletinFirstTimeDialog();
      }
    });

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
          defaultFilter ? List.from(appContext.eventHeads, growable: true) : List.from(appContext.eventHeads, growable: true);

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

      if (_selectedPostTagIDs.isNotEmpty) {
        eventHeads.removeWhere(
          (e) => !PostTagHelpers.headMatchesTagFilter(
            head: e,
            selectedTagIDs: _selectedPostTagIDs,
          ),
        );
      }

      final int itemCount = eventHeads.length;
      final List<EventHead> heads = eventHeads;

      return RefreshIndicator(
        edgeOffset: kToolbarHeight + 20,
        backgroundColor: colorScheme.surface,
        color: colorScheme.primary,
        onRefresh: () => _onRefresh().then((value) {
          _refreshAnimationController.forward().then((_) {
            _refreshAnimationController.reset();
          });

          if (!context.mounted) return;
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double contentWidth = constraints.maxWidth;
            final bool isWideScreen = ResponsiveLayout.isWideScreen(contentWidth);
            final double maxWidth = ResponsiveLayout.maxContentWidth(contentWidth);
            final double horizontalPadding = isWideScreen
                ? ((contentWidth - maxWidth) / 2).clamp(16.0, double.infinity)
                : 8.0;

            return CustomScrollView(
              controller: widget.scrollController,
              key: const PageStorageKey<String>('events_page'),
              slivers: [
                SliverAppBar(
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
                  expandedHeight: 100,
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
                              backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                          color: colorScheme.shadow.withValues(alpha: 0.1),
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
                ),
                if (appContext.postSortIndex != 0 || _selectedPostTagIDs.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _buildFilterIndicator(appContext, colorScheme),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 8,
                  ),
                  sliver: itemCount == 0
                      ? _buildEmptyState(colorScheme, theme)
                      : isWideScreen
                          ? SliverToBoxAdapter(
                              child: _buildWidePostColumns(colorScheme, heads),
                            )
                          : SliverList.separated(
                              itemCount: itemCount,
                              itemBuilder: (_, index) => _buildPostCard(
                                colorScheme,
                                heads[index],
                              ),
                              separatorBuilder: (BuildContext context, int index) =>
                                  const SizedBox(height: 8),
                            ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
      );
    });
  }

  /// Two columns with intrinsic card heights (avoids fixed-aspect dead space).
  Widget _buildWidePostColumns(ColorScheme colorScheme, List<EventHead> heads) {
    final List<EventHead> left = [];
    final List<EventHead> right = [];
    for (var i = 0; i < heads.length; i++) {
      (i.isEven ? left : right).add(heads[i]);
    }

    Widget column(List<EventHead> columnHeads) {
      return Column(
        children: [
          for (var i = 0; i < columnHeads.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _buildPostCard(colorScheme, columnHeads[i], verticalMargin: 0),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(left)),
        const SizedBox(width: 16),
        Expanded(child: column(right)),
      ],
    );
  }

  Widget _buildPostCard(
    ColorScheme colorScheme,
    EventHead head, {
    double verticalMargin = 4,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: verticalMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PostHead(
        thisHead: head,
        updatePost: () => widget.rebuildFunction(),
      ),
    );
  }

  Widget _buildFilterIndicator(AppContext appContext, ColorScheme colorScheme) {
    final Map<int, Map<String, dynamic>> filterInfo = {
      1: {'label': 'Upcoming Events', 'icon': Icons.upcoming, 'color': Colors.green},
      2: {'label': 'Recent Events', 'icon': Icons.history, 'color': Colors.orange},
      3: {'label': 'Bookmarked', 'icon': Icons.bookmark, 'color': Colors.purple},
    };

    final sortInfo = filterInfo[appContext.postSortIndex];
    final selectedTags = PostTagHelpers.resolveTags(
      tagIDs: _selectedPostTagIDs.toList(),
      allTags: appContext.allPostTags,
    );
    if (sortInfo == null && selectedTags.isEmpty) return const SizedBox.shrink();

    final Color accent = (sortInfo?['color'] as Color?) ?? colorScheme.primary;
    final parts = <String>[];
    if (sortInfo != null) parts.add(sortInfo['label'] as String);
    if (selectedTags.isNotEmpty) {
      parts.add(selectedTags.map((t) => t.name).join(', '));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            sortInfo != null ? sortInfo['icon'] as IconData : Icons.label_outline,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing: ${parts.join(' · ')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: accent,
              ),
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
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.7),
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
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
        isScrollControlled: true,
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        builder: (_) => SafeArea(
                child: BulletinSettingSheet(
              sortIndex: _appContext.postSortIndex,
              availableTags: _appContext.activePostTags,
              selectedTagIDs: Set<String>.from(_selectedPostTagIDs),
              onTagSelectionChanged: (selected) {
                setState(() {
                  _selectedPostTagIDs
                    ..clear()
                    ..addAll(selected);
                });
              },
              relevancySort: () => _onSortPosts(0),
              descendingEventDate: () => _onSortPosts(1),
              ascendingEventDate: () => _onSortPosts(2),
              showBookmarks: () => _onSortPosts(3),
            )));
  }

  // * Logic
  void _showBulletinFirstTimeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BulletinFirstTimeDialog(),
    ).then((_) {
      _appContext.sharedPref.setHasSeenBulletinDialog();
    });
  }

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
    final heads = await EventHeadsRepository().fetchEventHeads(forceRefresh: true);
    setState(() {
      _appContext.setRefreshedHeads(heads);
    });
  }
}

class BulletinSettingSheet extends StatefulWidget {
  const BulletinSettingSheet({
    super.key,
    required this.sortIndex,
    required this.availableTags,
    required this.selectedTagIDs,
    required this.onTagSelectionChanged,
    required this.relevancySort,
    required this.descendingEventDate,
    required this.ascendingEventDate,
    required this.showBookmarks,
  });

  final int sortIndex;
  final List<PostTag> availableTags;
  final Set<String> selectedTagIDs;
  final void Function(Set<String> selected) onTagSelectionChanged;
  final void Function() relevancySort, descendingEventDate, ascendingEventDate, showBookmarks;

  @override
  State<BulletinSettingSheet> createState() => _BulletinSettingSheetState();
}

class _BulletinSettingSheetState extends State<BulletinSettingSheet> with TickerProviderStateMixin {
  int _sortIndex = 0;
  late Set<String> _selectedTagIDs;
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    _sortIndex = widget.sortIndex;
    _selectedTagIDs = Set<String>.from(widget.selectedTagIDs);
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
    final l10n = AppLocalizations.of(context)!;

    return ActionSheetShell(
      icon: Icons.sort,
      title: 'Sort & Filter',
      subtitle: 'Choose how to organize your events',
      children: [
        ActionSheetOptionGrid(children: _buildFilterOptions()),
        if (widget.availableTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              l10n.postTagsAssignLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Narrow the bulletin by content type',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedTagIDs.isNotEmpty)
                  ActionChip(
                    label: Text(l10n.postTagsFilterClear),
                    onPressed: () => _onTagsChanged({}),
                  ),
                ...widget.availableTags.map((tag) {
                  final selected = _selectedTagIDs.contains(tag.id);
                  return PostTagChip(
                    tag: tag,
                    selected: selected,
                    onTap: () {
                      final next = Set<String>.from(_selectedTagIDs);
                      if (selected) {
                        next.remove(tag.id);
                      } else {
                        next.add(tag.id);
                      }
                      _onTagsChanged(next);
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _onTagsChanged(Set<String> selected) {
    HapticFeedback.selectionClick();
    setState(() => _selectedTagIDs = selected);
    widget.onTagSelectionChanged(selected);
  }

  List<Widget> _buildFilterOptions() {
    final List<Map<String, dynamic>> options = [
      {
        'index': 0,
        'title': 'Relevancy',
        'subtitle': 'Today\'s events, recent posts, and what\'s coming up',
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
      final colorScheme = Theme.of(context).colorScheme;

      return SlideTransition(
        position: _slideAnimations[index],
        child: ActionSheetOption(
          icon: option['icon'] as IconData,
          color: option['color'] as Color,
          title: option['title'] as String,
          subtitle: option['subtitle'] as String,
          selected: isSelected,
          showChevron: false,
          onTap: () => _onSortClick(index),
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
              : null,
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
