import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/media/cached_image_widget.dart';

class InfoAddContentCard extends StatelessWidget {
  const InfoAddContentCard({
    super.key,
    required this.label,
    required this.description,
    required this.onTap,
    this.compact,
  });

  final String label;
  final String description;
  final VoidCallback onTap;

  /// When null, compact vs tall follows available height (`maxHeight < 175`).
  final bool? compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = this.compact ?? constraints.maxHeight < 175;

              if (compact) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline,
                        size: 30, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 36, color: colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class InfoCardImage extends StatelessWidget {
  const InfoCardImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.alignment = Alignment.center,
  });

  final String imageUrl;
  final String heroTag;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.photo_library_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 40,
        ),
      );
    }

    return CachedImageWidget(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      alignment: alignment,
      heroTag: heroTag,
    );
  }
}

/// Image hero card used by churches and testimonials (and wide CTRIM when image-led).
class InfoHeroOverlayCard extends StatelessWidget {
  const InfoHeroOverlayCard({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    required this.onTap,
    required this.overlay,
    this.imageAlignment = Alignment.center,
    this.height,
  });

  final String imageUrl;
  final String heroTag;
  final VoidCallback onTap;
  final Widget overlay;
  final Alignment imageAlignment;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InfoCardImage(
              imageUrl: imageUrl,
              heroTag: heroTag,
              alignment: imageAlignment,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0xB3000000),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: overlay,
              ),
            ),
          ],
        ),
      ),
    );

    if (height == null) {
      return card;
    }

    return SizedBox(height: height, width: double.infinity, child: card);
  }
}

/// Title + description row card used for CTRIM topics.
class InfoTopicListCard extends StatelessWidget {
  const InfoTopicListCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.heroTag,
    required this.onTap,
    this.fallbackIcon = Icons.menu_book_outlined,
  });

  final String title;
  final String description;
  final String imageUrl;
  final String heroTag;
  final VoidCallback onTap;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _TopicThumbnail(
                imageUrl: imageUrl,
                heroTag: heroTag,
                fallbackIcon: fallbackIcon,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: colorScheme.outline, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicThumbnail extends StatelessWidget {
  const _TopicThumbnail({
    required this.imageUrl,
    required this.heroTag,
    required this.fallbackIcon,
    required this.colorScheme,
  });

  final String imageUrl;
  final String heroTag;
  final IconData fallbackIcon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: colorScheme.primary, size: 24),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 56,
        width: 56,
        child: CachedImageWidget(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          heroTag: heroTag,
        ),
      ),
    );
  }
}

class InfoEmptyState extends StatelessWidget {
  const InfoEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class InfoErrorState extends StatelessWidget {
  const InfoErrorState({
    super.key,
    required this.error,
    required this.canManageInfo,
    required this.addLabel,
    required this.addDescription,
    required this.onRetry,
    required this.onAdd,
  });

  final Object? error;
  final bool canManageInfo;
  final String addLabel;
  final String addDescription;
  final VoidCallback onRetry;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final bool isPermissionError =
        error.toString().contains('permission-denied');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: ResponsiveLayout.dialogMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isPermissionError
                    ? 'The information collection is not readable with the current backend rules.'
                    : 'Something went wrong: $error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              if (canManageInfo) ...[
                const SizedBox(height: 16),
                InfoAddContentCard(
                  label: addLabel,
                  description: addDescription,
                  onTap: onAdd,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared grid/list shell for churches, testimonials, and CTRIM info tabs.
class InfoSectionListTab<T> extends StatelessWidget {
  const InfoSectionListTab({
    super.key,
    required this.future,
    required this.onRefresh,
    required this.storageKey,
    required this.emptyMessage,
    required this.addLabel,
    required this.addDescription,
    required this.onAdd,
    required this.itemBuilder,
    required this.gridAspectRatio,
    this.mobileItemHeight,
  });

  final Future<List<T>> future;
  final VoidCallback onRefresh;
  final String storageKey;
  final String emptyMessage;
  final String addLabel;
  final String addDescription;
  final Future<void> Function(BuildContext context) onAdd;
  final Widget Function(BuildContext context, T item, {required bool wide})
      itemBuilder;
  final double Function(int crossAxisCount) gridAspectRatio;
  final double? mobileItemHeight;

  @override
  Widget build(BuildContext context) {
    final bool canManageInfo =
        context.select((AppContext c) => c.currentUser.canManageInfo);

    return FutureBuilder<List<T>>(
      future: future,
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
            addLabel: addLabel,
            addDescription: addDescription,
            onRetry: onRefresh,
            onAdd: () => onAdd(context),
          );
        }

        final items = snapshot.data ?? <T>[];
        if (items.isEmpty && !canManageInfo) {
          return InfoEmptyState(message: emptyMessage);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final double contentWidth = constraints.maxWidth;
            final bool isWideScreen = ResponsiveLayout.isWideScreenOf(context);
            final double maxWidth =
                ResponsiveLayout.maxContentWidth(contentWidth);
            final double horizontalPadding = isWideScreen
                ? ((contentWidth - maxWidth) / 2).clamp(16.0, double.infinity)
                : 16.0;
            final int crossAxisCount =
                ResponsiveLayout.cardCrossAxisCount(context, contentWidth);
            final int itemCount = items.length + (canManageInfo ? 1 : 0);

            if (isWideScreen) {
              return GridView.builder(
                key: PageStorageKey<String>(storageKey),
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 16, horizontalPadding, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: gridAspectRatio(crossAxisCount),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (canManageInfo && index == items.length) {
                    return InfoAddContentCard(
                      label: addLabel,
                      description: addDescription,
                      onTap: () => onAdd(context),
                    );
                  }
                  return itemBuilder(context, items[index], wide: true);
                },
              );
            }

            return MediaQuery.removePadding(
              removeTop: true,
              context: context,
              child: ListView.separated(
                key: PageStorageKey<String>(storageKey),
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 8, horizontalPadding, 24),
                itemCount: itemCount,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (canManageInfo && index == items.length) {
                    return InfoAddContentCard(
                      label: addLabel,
                      description: addDescription,
                      onTap: () => onAdd(context),
                    );
                  }
                  final item = itemBuilder(context, items[index], wide: false);
                  if (mobileItemHeight == null) {
                    return item;
                  }
                  return SizedBox(height: mobileItemHeight, child: item);
                },
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> openInfoEditorAndRefresh({
  required BuildContext context,
  required Widget editor,
  required VoidCallback onRefresh,
}) async {
  final changed = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => editor),
  );
  if (changed == true) {
    onRefresh();
  }
}

void openInfoDetailAndRefresh({
  required BuildContext context,
  required Widget page,
  required VoidCallback onRefresh,
}) {
  HapticFeedback.lightImpact();
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => page),
  ).then((_) => onRefresh());
}
