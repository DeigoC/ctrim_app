import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/info/church_info.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/info_repository.dart';
import '../../widgets/user_avatar.dart';
import 'edit_info_body_page.dart';
import 'info_detail_scaffold.dart';

class ChurchPastorsPage extends StatelessWidget {
  const ChurchPastorsPage({super.key, required this.documentId});

  final String documentId;

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
  });

  final List<String> pastorUserIds;
  final String? unknownLabel;

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => c.usersEpoch);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final appContext = Provider.of<AppContext>(context, listen: false);
    final fallback = unknownLabel ?? l10n.churchHubUnknownPastor;

    return Column(
      children: pastorUserIds.map((userId) {
        final user = appContext.userById(userId);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: user != null
              ? MyUserAvatar(user, radius: 20)
              : CircleAvatar(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
          title: Text(user?.fullname ?? fallback),
        );
      }).toList(),
    );
  }
}
