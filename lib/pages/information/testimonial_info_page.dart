import 'package:flutter/material.dart';

import '../../models/info/testimonial_info.dart';
import '../../utility/info_repository.dart';
import 'edit_info_body_page.dart';
import 'info_detail_scaffold.dart';

class TestimonialInfoPage extends StatelessWidget {
  const TestimonialInfoPage({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final repository = InfoRepository();

    return InfoDetailLoader<TestimonialInfo>(
      load: ({required bool forceRefresh}) => repository
          .fetchTestimonialById(documentId, forceRefresh: forceRefresh),
      analyticsScreenName: (info) => 'Testimonial: ${info.name}',
      pageTitleFallback: 'Testimonial',
      notFoundMessage: 'No testimonial found.',
      openEditor: (context, info) async {
        return await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => EditInfoBodyPage.forTestimonial(info: info)),
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
          title: 'Testimonial',
          imageUrls: info.imageSources,
          heroTag: 'info_testimonial_${info.id}',
          body: info.body,
          onRefresh: onRefresh,
          onEdit: onEdit,
          editTooltip: 'Edit testimonial',
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.name,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (info.church.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  info.church,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (info.summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(info.summary, style: theme.textTheme.titleMedium),
              ],
            ],
          ),
        );
      },
    );
  }
}
