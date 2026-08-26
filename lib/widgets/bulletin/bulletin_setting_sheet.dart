import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/post_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/bulletin_listing.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/volunteer_locations.dart';
import '../action_sheet.dart';
import '../post_tag_chip.dart';

class BulletinSettingSheet extends StatefulWidget {
  const BulletinSettingSheet({
    super.key,
    required this.sort,
    required this.timeFilter,
    required this.bookmarksOnly,
    required this.availableTags,
    required this.selectedTagIDs,
    required this.locationOptions,
    required this.selectedLocation,
    required this.onSortChanged,
    required this.onTimeFilterChanged,
    required this.onBookmarksOnlyChanged,
    required this.onLocationChanged,
    required this.onTagSelectionChanged,
  });

  final BulletinSort sort;
  final BulletinTimeFilter timeFilter;
  final bool bookmarksOnly;
  final List<PostTag> availableTags;
  final Set<String> selectedTagIDs;
  final List<String> locationOptions;
  final String selectedLocation;
  final void Function(BulletinSort sort) onSortChanged;
  final void Function(BulletinTimeFilter filter) onTimeFilterChanged;
  final void Function(bool bookmarksOnly) onBookmarksOnlyChanged;
  final void Function(String location) onLocationChanged;
  final void Function(Set<String> selected) onTagSelectionChanged;

  @override
  State<BulletinSettingSheet> createState() => _BulletinSettingSheetState();
}

class _BulletinSettingSheetState extends State<BulletinSettingSheet> {
  late BulletinSort _sort;
  late BulletinTimeFilter _timeFilter;
  late bool _bookmarksOnly;
  late Set<String> _selectedTagIDs;
  late String _selectedLocation;

  @override
  void initState() {
    super.initState();
    _sort = widget.sort;
    _timeFilter = widget.timeFilter;
    _bookmarksOnly = widget.bookmarksOnly;
    _selectedTagIDs = Set<String>.from(widget.selectedTagIDs);
    _selectedLocation = widget.selectedLocation;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return ActionSheetShell(
      icon: Icons.sort,
      title: l10n.bulletinSortFilterTitle,
      subtitle: l10n.bulletinSortFilterSubtitle,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            l10n.bulletinSortSection,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        ActionSheetOptionGrid(children: _buildSortOptions(l10n)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            l10n.bulletinShowSection,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(l10n.bulletinShowAll),
                selected: _timeFilter == BulletinTimeFilter.all,
                onSelected: (_) => _onTimeFilterChanged(BulletinTimeFilter.all),
              ),
              FilterChip(
                label: Text(l10n.bulletinShowUpcoming),
                selected: _timeFilter == BulletinTimeFilter.upcoming,
                onSelected: (_) =>
                    _onTimeFilterChanged(BulletinTimeFilter.upcoming),
              ),
              FilterChip(
                label: Text(l10n.bulletinShowPast),
                selected: _timeFilter == BulletinTimeFilter.past,
                onSelected: (_) =>
                    _onTimeFilterChanged(BulletinTimeFilter.past),
              ),
              FilterChip(
                label: Text(l10n.bulletinShowBookmarks),
                selected: _bookmarksOnly,
                onSelected: (_) => _onBookmarksOnlyChanged(!_bookmarksOnly),
              ),
              IconButton(
                icon: Icon(
                  Icons.help_outline,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _onBookmarkedHelp(l10n),
                tooltip: l10n.bulletinBookmarksHelpTooltip,
              ),
            ],
          ),
        ),
        if (widget.locationOptions.length > 1) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              l10n.bulletinLocationSection,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              l10n.bulletinLocationSubtitle,
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
              children: widget.locationOptions.map((location) {
                final selected = _selectedLocation == location;
                final label = location == VolunteerLocations.all
                    ? l10n.volunteersFilterAll
                    : location;
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => _onLocationChanged(location),
                );
              }).toList(),
            ),
          ),
        ],
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
              l10n.bulletinTagsSubtitle,
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

  List<Widget> _buildSortOptions(AppLocalizations l10n) {
    final options = [
      (
        BulletinSort.relevancy,
        l10n.bulletinSortRelevancy,
        l10n.bulletinSortRelevancySubtitle,
        Icons.star_rounded,
        Colors.amber,
      ),
      (
        BulletinSort.eventDateSoonest,
        l10n.bulletinSortSoonest,
        l10n.bulletinSortSoonestSubtitle,
        Icons.upcoming,
        Colors.green,
      ),
      (
        BulletinSort.eventDateLatest,
        l10n.bulletinSortLatest,
        l10n.bulletinSortLatestSubtitle,
        Icons.history,
        Colors.orange,
      ),
    ];

    return options.map((option) {
      final (sort, title, subtitle, icon, color) = option;
      return ActionSheetOption(
        icon: icon,
        color: color,
        title: title,
        subtitle: subtitle,
        selected: _sort == sort,
        showChevron: false,
        onTap: () => _onSortChanged(sort),
      );
    }).toList();
  }

  void _onSortChanged(final BulletinSort sort) {
    HapticFeedback.selectionClick();
    setState(() => _sort = sort);
    widget.onSortChanged(sort);
  }

  void _onTimeFilterChanged(final BulletinTimeFilter filter) {
    HapticFeedback.selectionClick();
    setState(() => _timeFilter = filter);
    widget.onTimeFilterChanged(filter);
  }

  void _onBookmarksOnlyChanged(final bool value) {
    HapticFeedback.selectionClick();
    setState(() => _bookmarksOnly = value);
    widget.onBookmarksOnlyChanged(value);
  }

  void _onTagsChanged(Set<String> selected) {
    HapticFeedback.selectionClick();
    setState(() => _selectedTagIDs = selected);
    widget.onTagSelectionChanged(selected);
  }

  void _onLocationChanged(String location) {
    HapticFeedback.selectionClick();
    setState(() => _selectedLocation = location);
    widget.onLocationChanged(location);
  }

  void _onBookmarkedHelp(AppLocalizations l10n) {
    HapticFeedback.lightImpact();
    DialogManager.showAlertDialog(
      context: context,
      title: l10n.bulletinBookmarksHelpTitle,
      content: l10n.bulletinBookmarksHelpBody,
    );
  }
}
