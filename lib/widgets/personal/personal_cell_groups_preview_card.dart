import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cell_group.dart';
import '../../models/user.dart';
import '../../pages/cell_groups/cell_group_detail_page.dart';
import '../../pages/events/view_event_page.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/personal_cell_group_meetings.dart';
import '../information/info_section_card.dart';

/// Personal home dashboard card for cell group membership and upcoming meetings.
class PersonalCellGroupsPreviewCard extends StatefulWidget {
  const PersonalCellGroupsPreviewCard({
    super.key,
    required this.appContext,
    this.onBrowseCellGroups,
  });

  final AppContext appContext;
  final VoidCallback? onBrowseCellGroups;

  @override
  State<PersonalCellGroupsPreviewCard> createState() =>
      _PersonalCellGroupsPreviewCardState();
}

class _PersonalCellGroupsPreviewCardState
    extends State<PersonalCellGroupsPreviewCard> {
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');

  late Future<PersonalCellGroupPreviewData> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadPreview();
  }

  Future<PersonalCellGroupPreviewData> _loadPreview() {
    return PersonalCellGroupMeetings.load(
      user: widget.appContext.currentUser,
      catalogue: widget.appContext.allCellGroups,
    );
  }

  void _reload() {
    setState(() {
      _loadFuture = _loadPreview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.select((AppContext c) => (c.catalogsEpoch, c.usersEpoch));

    return FutureBuilder<PersonalCellGroupPreviewData>(
      future: _loadFuture,
      builder: (context, snapshot) {
        Widget body;
        if (snapshot.connectionState != ConnectionState.done) {
          body = const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.cellGroupsActivityLoadError,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.cellGroupsActivityRetry),
              ),
            ],
          );
        } else {
          final data = snapshot.data!;
          body = _buildBody(context, l10n, data);
        }

        return InfoSectionCard(
          icon: Icons.groups_outlined,
          title: l10n.personalCellGroupsTitle,
          subtitle: l10n.personalCellGroupsSubtitle,
          content: body,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    PersonalCellGroupPreviewData data,
  ) {
    if (data.memberGroups.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.personalCellGroupsEmpty,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: widget.onBrowseCellGroups,
            child: Text(l10n.personalCellGroupsBrowse),
          ),
        ],
      );
    }

    final users = widget.appContext.allUsers;
    final children = <Widget>[];

    if (data.upcomingMeetings.isEmpty) {
      children.add(
        Text(
          l10n.personalCellGroupsNoUpcoming,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
      children.add(const SizedBox(height: 12));
      children.add(_buildGroupReminderCard(context, l10n, data.memberGroups, users));
    } else {
      children.add(
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < data.upcomingMeetings.length; i++)
                _buildMeetingTile(
                  context,
                  l10n,
                  data.upcomingMeetings[i],
                  users,
                  showDivider: i > 0,
                ),
            ],
          ),
        ),
      );
      final overflow = data.totalUpcomingCount - data.upcomingMeetings.length;
      if (overflow > 0) {
        children.add(const SizedBox(height: 8));
        children.add(
          Text(
            l10n.personalCellGroupsMoreMeetings(overflow),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildGroupReminderCard(
    BuildContext context,
    AppLocalizations l10n,
    List<CellGroup> groups,
    List<User> users,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < groups.length; i++)
            _buildGroupReminderTile(
              context,
              l10n,
              groups[i],
              users,
              showDivider: i > 0,
            ),
        ],
      ),
    );
  }

  Widget _buildMeetingTile(
    BuildContext context,
    AppLocalizations l10n,
    PersonalCellGroupMeetingPreview preview,
    List<User> users, {
    required bool showDivider,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final head = preview.head;
    final group = preview.group;
    final leaderName = PersonalCellGroupMeetings.leaderDisplayName(
      group: group,
      users: users,
      fallbackLabel: l10n.personalCellGroupLeaderTbc,
    );
    final dateLabel = head.eventDate != null
        ? _eventDateFormat.format(head.eventDate!)
        : l10n.personalScheduleDateTbc;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewEventPage(eventHead: head),
                ),
              );
            },
            child: ListTile(
              leading: Icon(Icons.event, color: colorScheme.primary),
              title: Text(group.name),
              subtitle: Text(
                '${l10n.personalCellGroupLedBy(leaderName)}\n$dateLabel · ${head.title}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupReminderTile(
    BuildContext context,
    AppLocalizations l10n,
    CellGroup group,
    List<User> users, {
    required bool showDivider,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cadence = group.cadenceLabel;
    final leaderName = PersonalCellGroupMeetings.leaderDisplayName(
      group: group,
      users: users,
      fallbackLabel: l10n.personalCellGroupLeaderTbc,
    );
    final subtitleParts = <String>[
      if (cadence.isNotEmpty) cadence,
      l10n.personalCellGroupLedBy(leaderName),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CellGroupDetailPage(groupId: group.id),
                ),
              );
            },
            child: ListTile(
              leading: Icon(Icons.groups_outlined, color: colorScheme.primary),
              title: Text(group.name),
              subtitle: Text(subtitleParts.join(' · ')),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }
}
