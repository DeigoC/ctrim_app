import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cell_group.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/cell_group_nearest.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/map_area.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/uk_postcode_lookup.dart';
import '../../utility/app_links.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/maps/area_map.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/my_avatar_stack.dart';
import '../../widgets/two_column_masonry.dart';

/// Catalogue list of cell groups (second tab).
class CellGroupsListTab extends StatefulWidget {
  const CellGroupsListTab({
    super.key,
    required this.loading,
    required this.error,
    required this.onRefresh,
    this.onRetry,
    this.rosterUsersByGroupId = const {},
    this.locationFilter,
  });

  final bool loading;
  final Object? error;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onRetry;

  /// Linked roster members keyed by cell group id (signed-in only).
  final Map<String, List<User>> rosterUsersByGroupId;

  /// When set, only groups at this church / volunteer location are listed.
  final String? locationFilter;

  @override
  State<CellGroupsListTab> createState() => _CellGroupsListTabState();
}

class _CellGroupsListTabState extends State<CellGroupsListTab> {
  final TextEditingController _searchController = TextEditingController();
  final UkPostcodeLookup _postcodeLookup = UkPostcodeLookup();
  Timer? _debounce;
  String _query = '';
  bool _lookingUp = false;
  UkPostcodeGeo? _origin;
  UkPostcodeLookupFailure? _lookupFailure;
  int _lookupGeneration = 0;

  String? get _locationFilter {
    final value = widget.locationFilter?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(final String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    setState(() {
      _query = value;
      _lookupFailure = null;
    });

    if (trimmed.isEmpty) {
      _lookupGeneration++;
      setState(() {
        _lookingUp = false;
        _origin = null;
      });
      return;
    }

    if (UkPostcodeLookup.classify(trimmed) == UkPostcodeKind.none) {
      _lookupGeneration++;
      setState(() {
        _lookingUp = false;
        _origin = null;
      });
      return;
    }

    setState(() => _lookingUp = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _lookupPostcode(trimmed);
    });
  }

  Future<void> _lookupPostcode(final String query) async {
    final generation = ++_lookupGeneration;
    try {
      final geo = await _postcodeLookup.lookup(query);
      if (!mounted || generation != _lookupGeneration) return;
      setState(() {
        _origin = geo;
        _lookingUp = false;
        _lookupFailure = null;
      });
    } on UkPostcodeLookupException catch (error) {
      if (!mounted || generation != _lookupGeneration) return;
      setState(() {
        _origin = null;
        _lookingUp = false;
        _lookupFailure = error.failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.select((AppContext c) => (c.catalogsEpoch, c.usersEpoch));
    final appContext = Provider.of<AppContext>(context, listen: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;
        final isWideScreen = ResponsiveLayout.isWideScreenOf(context);
        final maxWidth = ResponsiveLayout.maxContentWidth(contentWidth);
        final horizontalPadding = isWideScreen
            ? ((contentWidth - maxWidth) / 2).clamp(16.0, double.infinity)
            : 16.0;

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            key: PageStorageKey<String>(
              'cell_groups_list_tab_${widget.locationFilter ?? 'all'}',
            ),
            slivers: _buildContentSlivers(
              context: context,
              appContext: appContext,
              l10n: l10n,
              isWideScreen: isWideScreen,
              horizontalPadding: horizontalPadding,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildContentSlivers({
    required BuildContext context,
    required AppContext appContext,
    required AppLocalizations l10n,
    required bool isWideScreen,
    required double horizontalPadding,
  }) {
    if (widget.loading && appContext.allCellGroups.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: LoadProgressBody(
            message: 'Loading cell groups…',
            completedSteps: 0,
            totalSteps: 1,
          ),
        ),
      ];
    }
    if (widget.error != null && appContext.allCellGroups.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: LoadProgressBody(
            message: 'Loading cell groups…',
            completedSteps: 0,
            totalSteps: 1,
            error: widget.error,
            onRetry: () {
              (widget.onRetry ?? widget.onRefresh)();
            },
          ),
        ),
      ];
    }

    final catalogue = _catalogueForLocation(appContext.allCellGroups);
    if (catalogue.isEmpty) {
      final emptyMessage = _locationFilter == null
          ? l10n.cellGroupsEmpty
          : l10n.cellGroupsEmptyLocation(_locationFilter!);
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      ];
    }

    final resolved = _resolveVisibleGroups(catalogue);
    final slivers = <Widget>[
      SliverPadding(
        padding:
            EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 0),
        sliver: SliverToBoxAdapter(
          child: AppSearchBar(
            controller: _searchController,
            hintText: l10n.cellGroupsListSearchHint,
            onChanged: _onQueryChanged,
          ),
        ),
      ),
      if (_lookingUp)
        SliverToBoxAdapter(
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 0),
            child: const LinearProgressIndicator(),
          ),
        ),
    ];

    if (resolved.isEmpty) {
      slivers.add(SliverFillRemaining(
        hasScrollBody: false,
        child: _buildSearchEmptyState(context, l10n),
      ));
      return slivers;
    }

    final origin = _origin;
    final showNearestMap = origin != null &&
        UkPostcodeLookup.classify(_query) != UkPostcodeKind.none;
    if (showNearestMap) {
      slivers.add(
        SliverPadding(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 0),
          sliver: SliverToBoxAdapter(
            child: _NearestGroupsMap(
              origin: origin,
              groups: [for (final entry in resolved) entry.group],
            ),
          ),
        ),
      );
    }

    final isGuest = appContext.isCurrentUserGuest;
    final padding =
        EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 88);
    final nearest = _origin != null &&
        UkPostcodeLookup.classify(_query) != UkPostcodeKind.none;

    if (isWideScreen) {
      slivers.add(
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: TwoColumnMasonry(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final entry in resolved)
                  _buildCard(
                    appContext: appContext,
                    l10n: l10n,
                    entry: entry,
                    isGuest: isGuest,
                    showNearest: nearest,
                  ),
              ],
            ),
          ),
        ),
      );
      return slivers;
    }

    slivers.add(
      SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: resolved.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildCard(
            appContext: appContext,
            l10n: l10n,
            entry: resolved[index],
            isGuest: isGuest,
            showNearest: nearest,
          ),
        ),
      ),
    );
    return slivers;
  }

  List<_VisibleGroup> _resolveVisibleGroups(final List<CellGroup> catalogue) {
    final trimmed = _query.trim();
    if (trimmed.isEmpty) {
      return catalogue.map((group) => _VisibleGroup(group: group)).toList();
    }

    final kind = UkPostcodeLookup.classify(trimmed);
    if (kind == UkPostcodeKind.none) {
      return CellGroupNearestQuery.filterByText(
        groups: catalogue,
        query: trimmed,
      ).map((group) => _VisibleGroup(group: group)).toList();
    }

    if (_lookingUp && _origin == null) return const [];
    if (_lookupFailure != null) return const [];
    final origin = _origin;
    if (origin == null) return const [];

    return CellGroupNearestQuery.rank(
      groups: catalogue,
      originLat: origin.latitude,
      originLng: origin.longitude,
    )
        .map((match) => _VisibleGroup(group: match.group, miles: match.miles))
        .toList();
  }

  Widget _buildSearchEmptyState(
    final BuildContext context,
    final AppLocalizations l10n,
  ) {
    final trimmed = _query.trim();
    final kind = UkPostcodeLookup.classify(trimmed);
    if (kind != UkPostcodeKind.none) {
      if (_lookingUp && _origin == null) {
        return const SizedBox.shrink();
      }
      if (_lookupFailure == UkPostcodeLookupFailure.invalid) {
        return _SearchEmptyPanel(
          icon: Icons.wrong_location_outlined,
          title: l10n.cellGroupsSearchInvalidPostcodeTitle,
          body: l10n.cellGroupsSearchInvalidPostcodeBody,
        );
      }
      if (_lookupFailure == UkPostcodeLookupFailure.failed) {
        return _SearchEmptyPanel(
          icon: Icons.wifi_off_outlined,
          title: l10n.cellGroupsSearchLookupFailedTitle,
          body: l10n.cellGroupsSearchLookupFailedBody,
        );
      }
      return _SearchEmptyPanel(
        icon: Icons.place_outlined,
        title: l10n.cellGroupsSearchNoNearbyTitle,
        body: l10n.cellGroupsSearchNoNearbyBody,
      );
    }
    return _SearchEmptyPanel(
      icon: Icons.search_off,
      title: l10n.cellGroupsSearchNoNameMatchesTitle,
      body: l10n.cellGroupsSearchNoNameMatchesBody,
    );
  }

  Widget _buildCard({
    required AppContext appContext,
    required AppLocalizations l10n,
    required _VisibleGroup entry,
    required bool isGuest,
    required bool showNearest,
  }) {
    return _CellGroupCard(
      group: entry.group,
      isGuest: isGuest,
      leader: _leaderFor(appContext, entry.group),
      rosterUsers: widget.rosterUsersByGroupId[entry.group.id] ?? const [],
      appDir: appContext.appDir,
      distanceLabel: showNearest ? _distanceLabel(l10n, entry.miles) : null,
      showPostcode: showNearest,
      showLocation: _locationFilter == null,
    );
  }

  String? _distanceLabel(final AppLocalizations l10n, final double? miles) {
    if (miles == null) return null;
    if (miles < 0.1) return l10n.cellGroupsDistanceUnderPointOne;
    return l10n.cellGroupsDistanceMiles(miles.toStringAsFixed(1));
  }

  User? _leaderFor(AppContext appContext, CellGroup group) {
    for (final uid in group.leaderUserIds) {
      final match = appContext.allUsers.where((u) => u.id == uid);
      if (match.isNotEmpty) return match.first;
    }
    return null;
  }

  List<CellGroup> _catalogueForLocation(final Iterable<CellGroup> groups) {
    final location = _locationFilter;
    return groups.where((group) {
      if (group.isArchived) {
        return false;
      }
      if (location == null) {
        return true;
      }
      return VolunteerLocations.postLocationMatchesFilter(
        postLocation: group.location,
        locationFilter: location,
      );
    }).toList();
  }
}

class _VisibleGroup {
  const _VisibleGroup({required this.group, this.miles});

  final CellGroup group;
  final double? miles;
}

class _SearchEmptyPanel extends StatelessWidget {
  const _SearchEmptyPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 40),
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
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CellGroupCard extends StatelessWidget {
  const _CellGroupCard({
    required this.group,
    required this.isGuest,
    required this.leader,
    required this.rosterUsers,
    required this.appDir,
    this.distanceLabel,
    this.showPostcode = false,
    this.showLocation = true,
  });

  final CellGroup group;
  final bool isGuest;
  final User? leader;
  final List<User> rosterUsers;
  final String? appDir;
  final String? distanceLabel;
  final bool showPostcode;
  final bool showLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cadence = group.cadenceLabel;
    final titleLine = !showLocation || group.location.trim().isEmpty
        ? group.name
        : '${group.name} | ${group.location}';
    final postcode = showPostcode ? group.postcode : null;
    final showMeta = cadence.isNotEmpty ||
        group.isPaused ||
        distanceLabel != null ||
        (postcode != null && postcode.isNotEmpty);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          AppLinks.openCellGroup(context, id: group.id);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stripWidth = (constraints.maxWidth * 0.28).clamp(96.0, 148.0);
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 132),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(stripWidth + 14, 14, 14, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleLine,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (group.summary.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            group.summary,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (showMeta) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (distanceLabel != null)
                                Text(
                                  distanceLabel!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (postcode != null && postcode.isNotEmpty)
                                Text(
                                  postcode,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (cadence.isNotEmpty)
                                Text(
                                  cadence,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (group.isPaused)
                                Text(
                                  l10n.cellGroupsStatusPaused,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.tertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (!isGuest && rosterUsers.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: MyAvatarStack(
                                users: rosterUsers,
                                appDir: appDir,
                              ),
                            ),
                          ),
                        ] else if (!isGuest) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.cellGroupsMemberCount(group.memberCount),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: stripWidth,
                    child: _LeaderPhotoStrip(leader: leader),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Tall leading panel (~28% of card) with leader photo or groups placeholder.
class _LeaderPhotoStrip extends StatelessWidget {
  const _LeaderPhotoStrip({required this.leader});

  final User? leader;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = leader;

    if (user != null && user.imgSrc.isNotEmpty) {
      return ColoredBox(
        color: colorScheme.secondaryContainer,
        child: Image.network(
          NetworkImageHelper.getImageUrl(user.imgSrc),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _placeholder(colorScheme, user.initials),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            );
          },
        ),
      );
    }

    if (user != null) {
      return _placeholder(colorScheme, user.initials);
    }

    return ColoredBox(
      color: colorScheme.secondaryContainer,
      child: Center(
        child: Icon(
          Icons.groups,
          size: 36,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme colorScheme, String initials) {
    return ColoredBox(
      color: colorScheme.secondaryContainer,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}

class _NearestGroupsMap extends StatelessWidget {
  const _NearestGroupsMap({
    required this.origin,
    required this.groups,
  });

  final UkPostcodeGeo origin;
  final List<CellGroup> groups;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final circles = <MapAreaCircle>[];
    for (final group in groups) {
      final radius = MapArea.cellGroupRadiusMeters(group.postcode);
      final latitude = group.latitude;
      final longitude = group.longitude;
      if (radius == null || latitude == null || longitude == null) continue;
      circles.add(
        MapAreaCircle(
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radius,
        ),
      );
    }
    if (circles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AreaMap(
          height: 220,
          maxZoom: MapArea.cellGroupMaxZoom,
          circles: circles,
          pins: [
            MapAreaPin(
              latitude: origin.latitude,
              longitude: origin.longitude,
              origin: true,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.mapApproximateAreas,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
