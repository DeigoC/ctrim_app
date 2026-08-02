import 'package:flutter/material.dart';

import '../../models/info/church_info.dart';
import '../../utility/info_repository.dart';
import 'edit_info_body_page.dart';
import 'info_detail_scaffold.dart';

class ChurchInfoPage extends StatelessWidget {
  const ChurchInfoPage({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final repository = InfoRepository();

    return InfoDetailLoader<ChurchInfo>(
      load: ({required bool forceRefresh}) =>
          repository.fetchChurchById(documentId, forceRefresh: forceRefresh),
      analyticsScreenName: (info) => 'Church Info: ${info.analyticsTitle}',
      pageTitleFallback: 'Church Info',
      notFoundMessage: 'No church information found.',
      openEditor: (context, info) async {
        return await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => EditInfoBodyPage.forChurch(info: info)),
            ) ??
            false;
      },
      buildScaffold: ({
        required context,
        required info,
        required onRefresh,
        required onEdit,
      }) {
        return InfoDetailPageScaffold(
          title: info.title,
          imageUrls: info.imageSources,
          heroTag: 'info_church_${info.id}',
          body: info.body,
          onRefresh: onRefresh,
          onEdit: onEdit,
          editTooltip: 'Edit church info',
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (info.summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  info.summary,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
