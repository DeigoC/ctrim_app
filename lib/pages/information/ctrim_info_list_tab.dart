import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/info/ctrim_info.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/information/info_section_card.dart';
import '../../widgets/load_progress_body.dart';
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

  static const _sections = <({
    CtrimInfoCategory category,
    String subtitle,
    IconData icon,
  })>[
    (
      category: CtrimInfoCategory.principle,
      subtitle: 'Our core ideologies',
      icon: Icons.auto_awesome_outlined,
    ),
    (
      category: CtrimInfoCategory.teaching,
      subtitle: 'Simple lessons to get started!',
      icon: Icons.menu_book_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool canManageInfo =
        context.select((AppContext c) => c.currentUser.canManageInfo);

    return FutureBuilder<List<CtrimInfo>>(
      future: ctrimInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadProgressBody(
            message: 'Loading…',
            completedSteps: 0,
            totalSteps: 1,
          );
        }

        if (snapshot.hasError) {
          return InfoErrorState(
            error: snapshot.error,
            canManageInfo: canManageInfo,
            addLabel: 'Add CTRIM Topic',
            addDescription: 'Create a new Principles or Teachings topic.',
            onRetry: onRefresh,
            onAdd: () => _openEditor(
              context,
              category: CtrimInfoCategory.principle,
            ),
          );
        }

        final items = snapshot.data ?? <CtrimInfo>[];
        if (items.isEmpty && !canManageInfo) {
          return const InfoEmptyState(
            message: 'No CTRIM information available yet.',
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final double contentWidth = constraints.maxWidth;
            final bool isWideScreen =
                ResponsiveLayout.isWideScreen(contentWidth);
            final double maxWidth =
                ResponsiveLayout.maxContentWidth(contentWidth);
            final double horizontalPadding = isWideScreen
                ? ((contentWidth - maxWidth) / 2).clamp(16.0, double.infinity)
                : 16.0;
            final int crossAxisCount =
                ResponsiveLayout.crossAxisCount(contentWidth);

            return ListView(
              key: const PageStorageKey<String>('information_ctrim_tab'),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isWideScreen ? 16 : 8,
                horizontalPadding,
                24,
              ),
              children: [
                for (var i = 0; i < _sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 20),
                  _buildCategorySection(
                    context: context,
                    section: _sections[i],
                    items: items
                        .where((info) => info.category == _sections[i].category)
                        .toList(),
                    canManageInfo: canManageInfo,
                    isWideScreen: isWideScreen,
                    crossAxisCount: crossAxisCount,
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCategorySection({
    required BuildContext context,
    required ({
      CtrimInfoCategory category,
      String subtitle,
      IconData icon,
    }) section,
    required List<CtrimInfo> items,
    required bool canManageInfo,
    required bool isWideScreen,
    required int crossAxisCount,
  }) {
    final topicCards = <Widget>[
      for (final info in items) _buildTopicCard(context, info, isWideScreen),
      if (canManageInfo)
        InfoAddContentCard(
          label: 'Add ${section.category.label} Topic',
          description: section.category == CtrimInfoCategory.principle
              ? 'Create a new core ideology topic.'
              : 'Create a new teaching or starter lesson.',
          onTap: () => _openEditor(context, category: section.category),
        ),
    ];

    Widget content;
    if (topicCards.isEmpty) {
      content = Text(
        'No ${section.category.label.toLowerCase()} yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    } else if (isWideScreen) {
      content = GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topicCards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          // Taller cells so topic titles/descriptions do not overflow.
          childAspectRatio: crossAxisCount >= 3 ? 2.0 : 1.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) => topicCards[index],
      );
    } else {
      content = Column(
        children: [
          for (var i = 0; i < topicCards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            topicCards[i],
          ],
        ],
      );
    }

    return InfoSectionCard(
      icon: section.icon,
      title: section.category.label,
      subtitle: section.subtitle,
      content: content,
    );
  }

  Widget _buildTopicCard(
    BuildContext context,
    CtrimInfo info,
    bool wide,
  ) {
    void openDetail() => openInfoDetailAndRefresh(
          context: context,
          page: CTRIMInfoPage(documentId: info.id),
          onRefresh: onRefresh,
        );

    if (wide && info.imgSrc.isNotEmpty) {
      return InfoHeroOverlayCard(
        imageUrl: info.imgSrc,
        heroTag: 'info_ctrim_${info.id}',
        onTap: openDetail,
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
                maxLines: 3,
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
      onTap: openDetail,
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    required CtrimInfoCategory category,
  }) {
    return openInfoEditorAndRefresh(
      context: context,
      editor: EditInfoBodyPage.forCtrim(initialCategory: category),
      onRefresh: onRefresh,
    );
  }
}
