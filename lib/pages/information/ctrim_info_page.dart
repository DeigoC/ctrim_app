import 'package:flutter/material.dart';

import '../../models/info/ctrim_info.dart';
import '../../utility/info_repository.dart';
import 'edit_info_body_page.dart';
import 'info_detail_scaffold.dart';

class CTRIMInfoPage extends StatelessWidget {
  const CTRIMInfoPage({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final repository = InfoRepository();

    return InfoDetailLoader<CtrimInfo>(
      load: ({required bool forceRefresh}) =>
          repository.fetchCtrimInfoById(documentId, forceRefresh: forceRefresh),
      analyticsScreenName: (info) => 'CTRIM Info: ${info.analyticsTitle}',
      pageTitleFallback: 'CTRIM Information',
      notFoundMessage: 'No information found.',
      openEditor: (context, info) async {
        return await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => EditInfoBodyPage.forCtrim(info: info)),
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
        return InfoDetailPageScaffold(
          title: info.title,
          imageUrls: info.imageSources,
          heroTag: 'info_ctrim_${info.id}',
          body: info.body,
          onRefresh: onRefresh,
          onEdit: onEdit,
          editTooltip: 'Edit CTRIM info',
          showCarouselWhenEmpty: false,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.title,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (info.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  info.description,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
