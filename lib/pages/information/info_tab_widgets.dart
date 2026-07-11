import 'package:flutter/material.dart';

import '../../widgets/media/cached_image_widget.dart';

class InfoSectionCard extends StatelessWidget {
  const InfoSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }
}

class InfoAddContentCard extends StatelessWidget {
  const InfoAddContentCard({
    super.key,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxHeight < 130;

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
    required this.isAreaAdmin,
    required this.addLabel,
    required this.addDescription,
    required this.onRetry,
    required this.onAdd,
  });

  final Object? error;
  final bool isAreaAdmin;
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
          constraints: const BoxConstraints(maxWidth: 420),
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
              if (isAreaAdmin) ...[
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
