import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/info/ctrim_info.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/media/cached_image_widget.dart';
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
    final bool isAreaAdmin =
        Provider.of<AppContext>(context).currentUser.isAreaAdmin;

    return FutureBuilder<List<CtrimInfo>>(
      future: ctrimInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return InfoErrorState(
            error: snapshot.error,
            isAreaAdmin: isAreaAdmin,
            addLabel: 'Add CTRIM Topic',
            addDescription: 'Create the first CTRIM information topic.',
            onRetry: onRefresh,
            onAdd: () => _onAddCtrimTap(context),
          );
        }

        final infoRecords = snapshot.data ?? const <CtrimInfo>[];
        if (infoRecords.isEmpty && !isAreaAdmin) {
          return const InfoEmptyState(
              message: 'No CTRIM information available yet.');
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = ResponsiveLayout.crossAxisCount(screenWidth);
            final isWideScreen = screenWidth >= ResponsiveLayout.tablet;
            final itemCount = infoRecords.length + (isAreaAdmin ? 1 : 0);

            if (isWideScreen) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: crossAxisCount >= 3 ? 2.4 : 2.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (isAreaAdmin && index == infoRecords.length) {
                    return InfoAddContentCard(
                      label: 'Add CTRIM Topic',
                      description:
                          'Create a new teaching or information topic.',
                      onTap: () => _onAddCtrimTap(context),
                    );
                  }
                  return _CtrimInfoListTile(
                    info: infoRecords[index],
                    onTap: () => _onCtrimInfoTap(context, infoRecords[index]),
                  );
                },
              );
            }

            return MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (isAreaAdmin && index == infoRecords.length) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: InfoAddContentCard(
                        label: 'Add CTRIM Topic',
                        description:
                            'Create a new teaching or information topic.',
                        onTap: () => _onAddCtrimTap(context),
                      ),
                    );
                  }
                  return _CtrimInfoListTile(
                    info: infoRecords[index],
                    onTap: () => _onCtrimInfoTap(context, infoRecords[index]),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onAddCtrimTap(BuildContext context) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditInfoBodyPage.forCtrim()),
    );
    if (changed == true) {
      onRefresh();
    }
  }

  void _onCtrimInfoTap(BuildContext context, CtrimInfo info) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CTRIMInfoPage(documentId: info.id)),
    ).then((_) => onRefresh());
  }
}

class _CtrimInfoListTile extends StatelessWidget {
  const _CtrimInfoListTile({required this.info, required this.onTap});

  final CtrimInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _CtrimThumbnail(info: info, colorScheme: colorScheme),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: colorScheme.outline, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CtrimThumbnail extends StatelessWidget {
  const _CtrimThumbnail({required this.info, required this.colorScheme});

  final CtrimInfo info;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (info.imgSrc.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.info, color: colorScheme.primary, size: 24),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 56,
        width: 56,
        child: CachedImageWidget(
          imageUrl: info.imgSrc,
          fit: BoxFit.cover,
          heroTag: 'info_ctrim_${info.id}',
        ),
      ),
    );
  }
}
