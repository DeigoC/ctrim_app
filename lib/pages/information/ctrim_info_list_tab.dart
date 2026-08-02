import 'package:flutter/material.dart';

import '../../models/info/ctrim_info.dart';
import 'ctrim_info_page.dart';
import 'edit_info_body_page.dart';
import 'info_tab_widgets.dart';

class CtrimInfoListTab extends StatelessWidget {
  const CtrimInfoListTab({
    super.key,
    required this.ctrimInfoFuture,
    required this.onRefresh,
  });

  final Future<List<CtrimInfo>> ctrimInfoFuture;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return InfoSectionListTab<CtrimInfo>(
      future: ctrimInfoFuture,
      onRefresh: onRefresh,
      storageKey: 'information_ctrim_tab',
      emptyMessage: 'No CTRIM information available yet.',
      addLabel: 'Add CTRIM Topic',
      addDescription: 'Create a new teaching or information topic.',
      onAdd: (context) => openInfoEditorAndRefresh(
        context: context,
        editor: EditInfoBodyPage.forCtrim(),
        onRefresh: onRefresh,
      ),
      gridAspectRatio: (crossAxisCount) => crossAxisCount >= 3 ? 2.6 : 2.2,
      itemBuilder: (context, info, {required bool wide}) {
        // Prefer hero card on wide grids when a cover image exists.
        if (wide && info.imgSrc.isNotEmpty) {
          return InfoHeroOverlayCard(
            imageUrl: info.imgSrc,
            heroTag: 'info_ctrim_${info.id}',
            onTap: () => openInfoDetailAndRefresh(
              context: context,
              page: CTRIMInfoPage(documentId: info.id),
              onRefresh: onRefresh,
            ),
            overlay: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  info.title,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (info.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    info.description,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        }

        return InfoTopicListCard(
          title: info.title,
          description: info.description,
          imageUrl: info.imgSrc,
          heroTag: 'info_ctrim_${info.id}',
          onTap: () => openInfoDetailAndRefresh(
            context: context,
            page: CTRIMInfoPage(documentId: info.id),
            onRefresh: onRefresh,
          ),
        );
      },
    );
  }
}
