import 'package:flutter/material.dart';

import '../../models/info/church_page.dart';
import '../../models/user.dart';
import '../../utility/info_repository.dart';
import 'edit_info_body_page.dart';
import 'info_detail_scaffold.dart';

class ChurchPageInfoPage extends StatelessWidget {
  const ChurchPageInfoPage({
    super.key,
    required this.churchId,
    required this.documentId,
  });

  final String churchId;
  final String documentId;

  @override
  Widget build(BuildContext context) {
    final repository = InfoRepository();

    return InfoDetailLoader<ChurchPage>(
      load: ({required bool forceRefresh}) => repository.fetchChurchPageById(
        churchId,
        documentId,
        forceRefresh: forceRefresh,
      ),
      analyticsScreenName: (page) => 'Church Page: ${page.title}',
      pageTitleFallback: 'Church page',
      notFoundMessage: 'No page found.',
      canEdit: (User user) => user.canManageChurchPages,
      openEditor: (context, page) async {
        return await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => EditInfoBodyPage.forChurchPage(
                  churchId: churchId,
                  info: page,
                ),
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
        return InfoDetailPageScaffold(
          title: info.title,
          imageUrls: info.imageSources,
          heroTag: 'info_church_page_${info.churchId}_${info.id}',
          body: info.body,
          onRefresh: onRefresh,
          onEdit: onEdit,
          editTooltip: 'Edit page',
          showCarouselWhenEmpty: false,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.title,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (info.summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  info.summary,
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
