import 'package:flutter/material.dart';

import '../../models/post_template.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/post_template_loader.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/role_access_gate.dart';

/// Picks the post template used when adding a meeting from a cell group.
///
/// Pops the template id, or an empty string when the user clears it.
class SelectMeetingTemplatePage extends StatefulWidget {
  const SelectMeetingTemplatePage({
    super.key,
    this.currentTemplateId,
    this.cellGroupId,
  });

  final String? currentTemplateId;

  /// When set, templates that already list this group sort first.
  final String? cellGroupId;

  @override
  State<SelectMeetingTemplatePage> createState() =>
      _SelectMeetingTemplatePageState();
}

class _SelectMeetingTemplatePageState extends State<SelectMeetingTemplatePage> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<PostTemplate>>? _loadFuture;
  String _query = '';
  String? _selectedID;

  @override
  void initState() {
    super.initState();
    _selectedID = widget.currentTemplateId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFuture ??= _loadTemplates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<PostTemplate>> _loadTemplates() async {
    final templates = await PostTemplateLoader.load();
    final visible =
        templates.where((template) => template.id != 'blank').toList();
    visible.sort((a, b) {
      final rank = _rank(a).compareTo(_rank(b));
      if (rank != 0) return rank;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return visible;
  }

  int _rank(final PostTemplate template) {
    final groupId = widget.cellGroupId;
    if (groupId != null &&
        groupId.isNotEmpty &&
        template.cellGroupIDs.contains(groupId)) {
      return 0;
    }
    if (template.category == PostTemplateCategory.cellGroup) return 1;
    return 2;
  }

  bool _matches(final PostTemplate template) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return template.title.toLowerCase().contains(query) ||
        template.description.toLowerCase().contains(query) ||
        template.location.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final gutter = ResponsiveLayout.horizontalGutter(
      MediaQuery.sizeOf(context).width,
      narrowPadding: 8,
    );

    return RoleAccessGate(
      allow: (user) => user.canManageCellGroups,
      deniedMessage: l10n.cellGroupsMeetingTemplateDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.cellGroupsMeetingTemplateLabel),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedID ?? ''),
              child: Text(l10n.cellGroupsPickerDone),
            ),
          ],
        ),
        body: FutureBuilder<List<PostTemplate>>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (_loadFuture == null ||
                snapshot.connectionState != ConnectionState.done) {
              return LoadProgressBody(
                message: l10n.cellGroupsMeetingTemplateLoading,
                completedSteps: 0,
                totalSteps: 1,
              );
            }
            if (snapshot.hasError) {
              return LoadProgressBody(
                message: l10n.cellGroupsMeetingTemplateLoading,
                completedSteps: 0,
                totalSteps: 1,
                error: snapshot.error,
                errorTitle: l10n.cellGroupsMeetingTemplateLoadFailed,
                onRetry: () => setState(() {
                  _loadFuture = _loadTemplates();
                }),
              );
            }

            final templates = (snapshot.data ?? const <PostTemplate>[])
                .where(_matches)
                .toList();
            return ResponsiveContent(
              narrowPadding: 0,
              child: ListView(
                padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
                children: [
                  AppSearchBar(
                    controller: _searchController,
                    hintText: l10n.cellGroupsMeetingTemplateSearch,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  _TemplateChoiceCard(
                    title: l10n.cellGroupsMeetingTemplateNotSet,
                    subtitle: l10n.cellGroupsMeetingTemplateClearHint,
                    selected: _selectedID == null || _selectedID!.isEmpty,
                    onTap: () => setState(() => _selectedID = null),
                  ),
                  if (templates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        l10n.cellGroupsMeetingTemplateEmpty,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  else
                    ...templates.map((template) {
                      final linked = widget.cellGroupId != null &&
                          template.cellGroupIDs.contains(widget.cellGroupId);
                      final subtitleParts = <String>[
                        if (linked) l10n.cellGroupsMeetingTemplateLinked,
                        if (template.description.trim().isNotEmpty)
                          template.description.trim(),
                        template.category.label,
                      ];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _TemplateChoiceCard(
                          title: template.title,
                          subtitle: subtitleParts.join(' · '),
                          selected: _selectedID == template.id,
                          onTap: () =>
                              setState(() => _selectedID = template.id),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TemplateChoiceCard extends StatelessWidget {
  const _TemplateChoiceCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
