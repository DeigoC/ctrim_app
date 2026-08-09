import 'package:flutter/material.dart';

import '../../src/localization/app_localizations.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/media/cached_image_widget.dart';
import '../information/info_tab_widgets.dart';

/// Intro / teaching content for Cell Groups (first tab).
class CellGroupsOverviewTab extends StatelessWidget {
  const CellGroupsOverviewTab({super.key});

  /// Same Drive `uc?id=` form as Information → About hardcoded images.
  /// [CachedImageWidget] applies the web CORS proxy and local byte cache.
  static const String _overviewImage =
      'https://drive.google.com/uc?id=1nG1r-fbzkxJxD6qa9jsvcubqCbye2DOS';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final maxWidth = ResponsiveLayout.maxContentWidth(screenWidth);
        final horizontalPadding =
            screenWidth < ResponsiveLayout.compact ? 16.0 : 32.0;
        final isWideScreen = screenWidth >= ResponsiveLayout.tablet;

        return SingleChildScrollView(
          padding:
              EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.groups,
                            size: 48, color: colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          l10n.cellGroupsOverviewHeadline,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.cellGroupsOverviewIntro,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  InfoSectionCard(
                    icon: Icons.menu_book,
                    title: l10n.cellGroupsOverviewVerseTitle,
                    subtitle: l10n.cellGroupsOverviewVerseReference,
                    content: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        l10n.cellGroupsOverviewVerseBody,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedImageWidget(
                      imageUrl: _overviewImage,
                      height: isWideScreen ? 250 : 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  InfoSectionCard(
                    icon: Icons.info_outline,
                    title: l10n.cellGroupsOverviewDetailTitle,
                    subtitle: l10n.cellGroupsOverviewDetailSubtitle,
                    content: Text(
                      l10n.cellGroupsOverviewDetailBody,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
