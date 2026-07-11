import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/info/church_info.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
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
    final bool isAreaAdmin =
        Provider.of<AppContext>(context).currentUser.isAreaAdmin;

    return FutureBuilder<List<ChurchInfo>>(
      future: churchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return InfoErrorState(
            error: snapshot.error,
            isAreaAdmin: isAreaAdmin,
            addLabel: 'Add Church',
            addDescription: 'Create the first church information record.',
            onRetry: onRefresh,
            onAdd: () => _onAddChurchTap(context),
          );
        }

        final churches = snapshot.data ?? const <ChurchInfo>[];
        if (churches.isEmpty && !isAreaAdmin) {
          return const InfoEmptyState(
              message: 'No church information available yet.');
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth;
            final int crossAxisCount =
                ResponsiveLayout.crossAxisCount(screenWidth);
            final bool isWideScreen = screenWidth >= ResponsiveLayout.tablet;
            final int itemCount = churches.length + (isAreaAdmin ? 1 : 0);

            if (isWideScreen) {
              return GridView.builder(
                key: const PageStorageKey<String>('information_churches_tab'),
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 16 / 9,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (isAreaAdmin && index == churches.length) {
                    return InfoAddContentCard(
                      label: 'Add Church',
                      description: 'Create a new church information record.',
                      onTap: () => _onAddChurchTap(context),
                    );
                  }
                  return _ChurchCard(
                    church: churches[index],
                    onTap: () => _onChurchTap(context, churches[index]),
                  );
                },
              );
            }

            return MediaQuery.removePadding(
              removeTop: true,
              context: context,
              child: ListView.builder(
                key: const PageStorageKey<String>('information_churches_tab'),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (isAreaAdmin && index == churches.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: InfoAddContentCard(
                        label: 'Add Church',
                        description: 'Create a new church information record.',
                        onTap: () => _onAddChurchTap(context),
                      ),
                    );
                  }
                  return _ChurchListSlot(
                    church: churches[index],
                    onTap: () => _onChurchTap(context, churches[index]),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onAddChurchTap(BuildContext context) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditInfoBodyPage.forChurch()),
    );
    if (changed == true) {
      onRefresh();
    }
  }

  void _onChurchTap(BuildContext context, ChurchInfo church) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChurchInfoPage(documentId: church.id)),
    ).then((_) => onRefresh());
  }
}

class _ChurchCard extends StatelessWidget {
  const _ChurchCard({required this.church, required this.onTap});

  final ChurchInfo church;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InfoCardImage(
                imageUrl: church.imgSrc, heroTag: 'info_church_${church.id}'),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  church.title,
                  style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChurchListSlot extends StatelessWidget {
  const _ChurchListSlot({required this.church, required this.onTap});

  final ChurchInfo church;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: InfoCardImage(
                  imageUrl: church.imgSrc, heroTag: 'info_church_${church.id}'),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  church.title,
                  style: const TextStyle(fontSize: 36, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
