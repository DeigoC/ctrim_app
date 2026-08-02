import 'package:flutter/material.dart';

import '../../models/info/church_info.dart';
import 'church_info_page.dart';
import 'edit_info_body_page.dart';
import 'info_tab_widgets.dart';

class ChurchesTab extends StatelessWidget {
  const ChurchesTab({
    super.key,
    required this.churchesFuture,
    required this.onRefresh,
  });

  final Future<List<ChurchInfo>> churchesFuture;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return InfoSectionListTab<ChurchInfo>(
      future: churchesFuture,
      onRefresh: onRefresh,
      storageKey: 'information_churches_tab',
      emptyMessage: 'No church information available yet.',
      addLabel: 'Add Church',
      addDescription: 'Create a new church information record.',
      onAdd: (context) => openInfoEditorAndRefresh(
        context: context,
        editor: EditInfoBodyPage.forChurch(),
        onRefresh: onRefresh,
      ),
      gridAspectRatio: (_) => 16 / 9,
      mobileItemHeight: MediaQuery.sizeOf(context).height * 0.36,
      itemBuilder: (context, church, {required bool wide}) {
        return InfoHeroOverlayCard(
          imageUrl: church.imgSrc,
          heroTag: 'info_church_${church.id}',
          onTap: () => openInfoDetailAndRefresh(
            context: context,
            page: ChurchInfoPage(documentId: church.id),
            onRefresh: onRefresh,
          ),
          overlay: Text(
            church.title,
            style: TextStyle(
              fontSize: wide ? 26 : 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
