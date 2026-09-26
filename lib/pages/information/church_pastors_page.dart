import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/info/church_info.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/church_pastor_list_layout.dart';
import '../../utility/info_repository.dart';
import '../../widgets/user_avatar.dart';
import 'edit_info_body_page.dart';
import 'info_detail_scaffold.dart';

class ChurchPastorsPage extends StatelessWidget {
  const ChurchPastorsPage({
    super.key,
    required this.documentId,
    this.initialChurch,
  });

  final String documentId;
  final ChurchInfo? initialChurch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repository = InfoRepository();

    return InfoDetailLoader<ChurchInfo>(
      load: ({required bool forceRefresh}) => repository.fetchChurchById(
        documentId,
        forceRefresh: forceRefresh,
      ),
      analyticsScreenName: (church) =>
          'Church Pastors: ${church.analyticsTitle}',
      pageTitleFallback: l10n.churchPastorsPageTitle,
      notFoundMessage: l10n.churchInfoNotFound,
      initialInfo: initialChurch != null && initialChurch!.id == documentId
          ? initialChurch
          : null,
      openEditor: (context, church) async {
        return await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => EditInfoBodyPage.forChurch(info: church),
              ),
            ) ??
            false;
      },
      buildScaffold: ({
        required context,
        required info,
        required onRefresh,
        required onEdit,
      }) {
        final theme = Theme.of(context);
        final isOutreach = info.isOutreach;
        return InfoDetailPageScaffold(
          title: isOutreach
              ? l10n.churchPlantersPageTitle
              : l10n.churchPastorsPageTitle,
          imageUrls:
              info.hasPastorsImage ? <String>[info.pastorsImageSrc] : const [],
          heroTag: 'info_church_pastors_${info.id}',
          body: info.body,
          onRefresh: onRefresh,
          onEdit: onEdit,
          editTooltip: l10n.churchInfoEditTooltip,
          showCarouselWhenEmpty: false,
          pinPortraitAside: true,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOutreach
                    ? l10n.churchHubPlantersTitle
                    : l10n.churchHubPastorsTitle,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (info.hasPastors) ...[
                const SizedBox(height: 16),
                ChurchPastorUserList(
                  pastorUserIds: info.pastorUserIds,
                  unknownLabel: isOutreach
                      ? l10n.churchHubUnknownPlanter
                      : l10n.churchHubUnknownPastor,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ChurchPastorUserList extends StatelessWidget {
  const ChurchPastorUserList({
    super.key,
    required this.pastorUserIds,
    this.unknownLabel,
    this.onUserTap,
  });

  final List<String> pastorUserIds;
  final String? unknownLabel;
  final ValueChanged<User>? onUserTap;

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => c.usersEpoch);
    if (pastorUserIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final appContext = Provider.of<AppContext>(context, listen: false);
    final fallback = unknownLabel ?? l10n.churchHubUnknownPastor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final columns = ChurchPastorListLayout.columns(
          count: pastorUserIds.length,
          maxWidth: maxWidth,
        );
        final tileWidth = ChurchPastorListLayout.tileWidth(
          columns: columns,
          maxWidth: maxWidth,
        );

        return Wrap(
          spacing: ChurchPastorListLayout.gap,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final userId in pastorUserIds)
              SizedBox(
                width: tileWidth,
                child: _PastorPersonTile(
                  user: appContext.userById(userId),
                  fallbackLabel: fallback,
                  colorScheme: colorScheme,
                  onTap: onUserTap,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PastorPersonTile extends StatelessWidget {
  const _PastorPersonTile({
    required this.user,
    required this.fallbackLabel,
    required this.colorScheme,
    this.onTap,
  });

  final User? user;
  final String fallbackLabel;
  final ColorScheme colorScheme;
  final ValueChanged<User>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guest = context.select((AppContext c) => c.isCurrentUserGuest);
    context.select((AppContext c) => c.usersEpoch);
    final person = user;
    final live = person == null
        ? null
        : context.read<AppContext>().userById(person.id) ?? person;
    final name = live?.nameForViewer(guest: guest) ?? fallbackLabel;
    final tap = onTap;

    return InkWell(
      onTap: person == null || tap == null ? null : () => tap(person),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user != null)
            MyUserAvatar(
              user!,
              radius: ChurchPastorListLayout.avatarRadius,
            )
          else
            CircleAvatar(
              radius: ChurchPastorListLayout.avatarRadius,
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
