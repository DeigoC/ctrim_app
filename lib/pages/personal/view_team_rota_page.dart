import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/event/event_program.dart';
import '../../models/user.dart';
import '../../models/user_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/app_links.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/team_rota.dart';
import '../../widgets/catalog/colored_chip.dart';
import '../../widgets/catalog/user_tag_chip.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/my_avatar_stack.dart';
import '../../widgets/paired_row_list.dart';

/// Signed-in serving view: tagged programme slots over the next few months.
class ViewTeamRotaPage extends StatefulWidget {
  const ViewTeamRotaPage({super.key});

  @override
  State<ViewTeamRotaPage> createState() => _ViewTeamRotaPageState();
}

class _ViewTeamRotaPageState extends State<ViewTeamRotaPage> {
  static const int _horizonMonths = TeamRotaQuery.defaultHorizonMonths;

  late final AppContext _appContext;
  final EventHeadDBManager _headsDb = EventHeadDBManager();
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  late String _locationFilter;
  late Set<String> _selectedTagIDs;

  List<EventHead> _rangeHeads = [];
  final Map<String, EventProgram?> _programs = {};

  bool _loading = true;
  Object? _error;
  String _statusMessage = '';
  int _completedSteps = 0;
  int _totalSteps = 2;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    _locationFilter = VolunteerLocations.defaultFilterForUser(
      _appContext.currentUser.location,
      VolunteerLocations.assignableFrom(_appContext.allLocations),
    );
    _selectedTagIDs = UserTagHelpers.tagsForUser(
      user: _appContext.currentUser,
      allTags: _appContext.allTags,
    ).map((tag) => tag.id).toSet();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
      _completedSteps = 0;
      _totalSteps = 2;
      _statusMessage = l10n.teamRotaLoadingHeads;
    });

    try {
      final now = DateTime.now();
      final heads = await _headsDb.fetchHeadsWithEventDateInRange(
        startInclusive: TeamRotaQuery.rangeStart(now),
        endExclusive: TeamRotaQuery.rangeEndExclusive(now),
      );
      if (!mounted) return;

      setState(() {
        _rangeHeads = heads;
        _completedSteps = 1;
        _statusMessage = l10n.teamRotaLoadingProgrammes;
      });

      await _ensureProgramsForFilter();
      if (!mounted) return;

      setState(() {
        _loading = false;
        _completedSteps = 2;
      });
    } catch (e, st) {
      debugPrint('Could not load team rota: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _ensureProgramsForFilter() async {
    final needed = _rangeHeads.where((head) {
      if (!TeamRotaQuery.headMatchesLocation(
        head: head,
        locationFilter: _locationFilter,
      )) {
        return false;
      }
      return !_programs.containsKey(head.id);
    }).toList();
    if (needed.isEmpty) return;

    final fetched = await Future.wait(
      needed.map(
        (head) => EventSupplementalDBManager(head.id).fetchProgramIfExists(),
      ),
    );
    for (var i = 0; i < needed.length; i++) {
      _programs[needed[i].id] = fetched[i];
    }
  }

  List<TeamRotaPost> _matchingPosts() {
    final posts = <({EventHead head, EventProgram program})>[];
    for (final head in _rangeHeads) {
      final program = _programs[head.id];
      if (program == null) continue;
      posts.add((head: head, program: program));
    }
    return TeamRotaQuery.matchingPosts(
      posts: posts,
      selectedTagIDs: _selectedTagIDs,
      locationFilter: _locationFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => (c.catalogsEpoch, c.usersEpoch));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamRota),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      ),
      body: _loading || _error != null
          ? LoadProgressBody(
              message: _statusMessage,
              completedSteps: _completedSteps,
              totalSteps: _totalSteps,
              error: _error,
              errorTitle: l10n.teamRotaCouldNotLoad,
              onRetry: _load,
            )
          : _buildLoadedBody(l10n),
    );
  }

  Widget _buildLoadedBody(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final matching = _matchingPosts();
    final groups = TeamRotaQuery.groupByMonth(matching);
    final isWide = ResponsiveLayout.isWideScreenOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;
        final horizontalPadding = isWide
            ? ((contentWidth - ResponsiveLayout.maxContentWidth(contentWidth)) /
                    2)
                .clamp(16.0, double.infinity)
            : 16.0;

        return ListView(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 32),
          children: [
            Text(
              l10n.teamRotaHorizon(_horizonMonths),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilters(l10n, theme),
            const SizedBox(height: 24),
            if (_selectedTagIDs.isEmpty)
              _buildEmptyState(
                theme,
                icon: Icons.sell_outlined,
                title: l10n.teamRotaEmptyNoTeamsTitle,
                body: l10n.teamRotaEmptyNoTeamsBody,
              )
            else if (groups.isEmpty)
              _buildEmptyState(
                theme,
                icon: Icons.event_note,
                title: l10n.teamRotaEmptyTitle,
                body: l10n.teamRotaEmptyBody,
              )
            else
              for (var i = 0; i < groups.length; i++) ...[
                if (i > 0) const SizedBox(height: 28),
                _buildMonthHeader(theme, groups[i]),
                const SizedBox(height: 8),
                _buildPostGrid(groups[i].posts, isWide: isWide, l10n: l10n),
              ],
          ],
        );
      },
    );
  }

  Widget _buildFilters(AppLocalizations l10n, ThemeData theme) {
    final locationOptions = VolunteerLocations.filterOptionsFrom(
      _appContext.allLocations,
    );
    final tags = _appContext.activeTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.teamRotaFilterLocation,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final location in locationOptions)
              ColoredChip(
                label: location == VolunteerLocations.all
                    ? l10n.volunteersFilterAll
                    : location,
                selected: _locationFilter == location,
                onTap: () => _onLocationSelected(location),
              ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.teamRotaFilterTeams,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                UserTagChip(
                  tag: tag,
                  selected: _selectedTagIDs.contains(tag.id),
                  onTap: () => _toggleTag(tag),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _onLocationSelected(final String location) async {
    if (_locationFilter == location) return;
    setState(() => _locationFilter = location);
    await _ensureProgramsForFilter();
    if (mounted) setState(() {});
  }

  void _toggleTag(final UserTag tag) {
    setState(() {
      if (_selectedTagIDs.contains(tag.id)) {
        _selectedTagIDs.remove(tag.id);
      } else {
        _selectedTagIDs.add(tag.id);
      }
    });
  }

  Widget _buildMonthHeader(ThemeData theme, TeamRotaMonthGroup group) {
    final locale = Localizations.localeOf(context).toString();
    final label = DateFormat.yMMMM(locale).format(group.monthDate);
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildPostGrid(
    List<TeamRotaPost> posts, {
    required bool isWide,
    required AppLocalizations l10n,
  }) {
    if (!isWide) {
      return Column(
        children: [
          for (var i = 0; i < posts.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildPostCard(posts[i], l10n),
          ],
        ],
      );
    }
    return PairedRowList(
      itemCount: posts.length,
      runSpacing: 12,
      itemBuilder: (_, i) => _buildPostCard(posts[i], l10n),
    );
  }

  Widget _buildPostCard(TeamRotaPost post, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = post.head.eventDate != null
        ? _eventDateFormat.format(post.head.eventDate!)
        : l10n.personalScheduleDateTbc;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPost(post.head),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post.head.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (post.head.location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              VolunteerLocations.normalizePostLocation(
                                post.head.location,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
                for (var i = 0; i < post.roles.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _buildRoleRow(post.roles[i], l10n, theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleRow(
    Map<String, dynamic> role,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final start = role['start'] as DateTime?;
    final end = role['end'] as DateTime?;
    final timeLabel = start != null && end != null
        ? '${_timeFormat.format(start)} – ${_timeFormat.format(end)}'
        : null;
    final assigned = _assignedUsers(role);
    final tags = UserTagHelpers.resolveTags(
      tagIDs: EventProgram.tagIDsOf(role),
      allTags: _appContext.allTags,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                role['title'] as String? ?? '',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (timeLabel != null) ...[
              const SizedBox(width: 12),
              Text(
                timeLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (assigned.isNotEmpty)
          MyAvatarStack(
            users: assigned,
            height: 28,
            width: (28.0 * assigned.length.clamp(1, 4)).clamp(28, 88),
            borderWidth: 1.2,
          )
        else
          Text(
            l10n.teamRotaUnassigned,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          UserTagChipRow(tags: tags, dense: true),
        ],
      ],
    );
  }

  List<User> _assignedUsers(Map<String, dynamic> role) {
    final users = <User>[];
    for (final id in TeamRotaQuery.uidsOf(role)) {
      final user = _appContext.userById(id);
      if (user != null) users.add(user);
    }
    return users;
  }

  Widget _buildEmptyState(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _openPost(EventHead head) {
    AppLinks.openPost(context, id: head.id, extra: head);
  }
}
