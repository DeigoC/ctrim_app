import 'package:flutter/material.dart';

import '../../models/catalog_picker_entry.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/catalog/catalog_picker_helpers.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../widgets/app_search_bar.dart';

/// Full-screen searchable multi-select picker for admin catalogs (post tags,
/// cell groups, and similar lists).
class SelectCatalogItemsPage extends StatefulWidget {
  const SelectCatalogItemsPage({
    super.key,
    required this.title,
    required this.searchHint,
    required this.emptyMessage,
    required this.noResultsMessage,
    required this.allEntries,
    required this.selectedIds,
    this.showLocationFilter = false,
    this.showNotifiableFilter = false,
    this.notifiableFilterLabel,
  });

  final String title;
  final String searchHint;
  final String emptyMessage;
  final String noResultsMessage;
  final List<CatalogPickerEntry> allEntries;
  final Set<String> selectedIds;
  final bool showLocationFilter;
  final bool showNotifiableFilter;
  final String? notifiableFilterLabel;

  static Future<Set<String>?> open({
    required BuildContext context,
    required SelectCatalogItemsPage page,
  }) {
    return Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  State<SelectCatalogItemsPage> createState() => _SelectCatalogItemsPageState();
}

class _SelectCatalogItemsPageState extends State<SelectCatalogItemsPage> {
  final TextEditingController _searchController = TextEditingController();
  late Set<String> _selectedIds;
  late List<CatalogPickerEntry> _visibleEntries;
  late List<String> _locationOptions;
  late String _locationFilter;

  bool _isSearching = false;
  String _searchQuery = '';
  bool _notifiableOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.selectedIds);
    _visibleEntries = CatalogPickerHelpers.visibleEntries(
      allEntries: widget.allEntries,
      selectedIds: _selectedIds,
    );
    _locationOptions = CatalogPickerHelpers.locationFilterOptions(_visibleEntries);
    _locationFilter =
        _locationOptions.length > 1 ? _locationOptions.first : VolunteerLocations.all;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CatalogPickerEntry> get _filteredEntries {
    return CatalogPickerHelpers.filterEntries(
      entries: _visibleEntries,
      searchQuery: _searchQuery,
      locationFilter: widget.showLocationFilter ? _locationFilter : VolunteerLocations.all,
      notifiableOnly: widget.showNotifiableFilter && _notifiableOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveLayout.isWideScreen(screenWidth);
    final horizontalPadding = isWide
        ? ((screenWidth - ResponsiveLayout.maxContentWidth(screenWidth)) / 2)
            .clamp(16.0, double.infinity)
        : 0.0;
    final filterHorizontalPadding =
        horizontalPadding > 0 ? horizontalPadding : 16.0;
    final filtered = _filteredEntries;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_selectedIds);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? AppSearchBar(
                  controller: _searchController,
                  hintText: widget.searchHint,
                  inAppBar: true,
                  autofocus: true,
                  onChanged: (value) => setState(() => _searchQuery = value),
                )
              : Text(widget.title),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: filterHorizontalPadding,
                  vertical: 8,
                ),
                child: Text(
                  l10n.selectCatalogSelected(_selectedIds.length),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            if (widget.showLocationFilter && _locationOptions.length > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(
                  filterHorizontalPadding,
                  8,
                  filterHorizontalPadding,
                  8,
                ),
                child: Row(
                  children: _locationOptions.map((location) {
                    final label = location == VolunteerLocations.all
                        ? l10n.volunteersFilterAll
                        : location;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: _locationFilter == location,
                        onSelected: (_) =>
                            setState(() => _locationFilter = location),
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (widget.showNotifiableFilter &&
                widget.notifiableFilterLabel != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  filterHorizontalPadding,
                  0,
                  filterHorizontalPadding,
                  8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    avatar: const Icon(Icons.notifications_active_outlined, size: 18),
                    label: Text(widget.notifiableFilterLabel!),
                    selected: _notifiableOnly,
                    onSelected: (selected) =>
                        setState(() => _notifiableOnly = selected),
                  ),
                ),
              ),
            Expanded(
              child: _visibleEntries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding + 16,
                        ),
                        child: Text(
                          widget.emptyMessage,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding + 16,
                            ),
                            child: Text(
                              widget.noResultsMessage,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : isWide
                          ? GridView.builder(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                0,
                                horizontalPadding,
                                16,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 420,
                                mainAxisExtent: 88,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, index) =>
                                  _buildEntryTile(filtered[index]),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, index) =>
                                  _buildEntryTile(filtered[index]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTile(CatalogPickerEntry entry) {
    final isSelected = _selectedIds.contains(entry.id);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = entry.accentColor;

    return ListTile(
      leading: Checkbox(
        value: isSelected,
        onChanged: (_) => _toggleEntry(entry.id),
      ),
      title: Text(
        entry.label,
        style: !entry.isActive
            ? theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              )
            : null,
      ),
      subtitle: entry.subtitle == null
          ? null
          : Text(
              entry.isActive ? entry.subtitle! : '${entry.subtitle!} · Inactive',
            ),
      isThreeLine: false,
      trailing: CircleAvatar(
        radius: 18,
        backgroundColor: accent?.withValues(alpha: 0.15) ??
            colorScheme.surfaceContainerHighest,
        child: Icon(
          entry.icon,
          size: 18,
          color: accent ?? colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () => _toggleEntry(entry.id),
    );
  }

  void _toggleEntry(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }
}
