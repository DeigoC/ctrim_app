import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/info/testimonial_into.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import 'edit_info_body_page.dart';
import 'info_tab_widgets.dart';
import 'testimonial_info_page.dart';

class TestimonialsTab extends StatelessWidget {
  const TestimonialsTab({
    super.key,
    required this.testimonialsFuture,
    required this.onRefresh,
  });

  final Future<List<TestimonialInfo>> testimonialsFuture;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final bool isAreaAdmin =
        Provider.of<AppContext>(context).currentUser.isAreaAdmin;

    return FutureBuilder<List<TestimonialInfo>>(
      future: testimonialsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return InfoErrorState(
            error: snapshot.error,
            isAreaAdmin: isAreaAdmin,
            addLabel: 'Add Testimonial',
            addDescription: 'Create the first testimonial record.',
            onRetry: onRefresh,
            onAdd: () => _onAddTestimonialTap(context),
          );
        }

        final testimonials = snapshot.data ?? const <TestimonialInfo>[];
        if (testimonials.isEmpty && !isAreaAdmin) {
          return const InfoEmptyState(
              message: 'No testimonials available yet.');
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = ResponsiveLayout.crossAxisCount(screenWidth);
            final isWideScreen = screenWidth >= ResponsiveLayout.tablet;
            final itemCount = testimonials.length + (isAreaAdmin ? 1 : 0);

            if (isWideScreen) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (isAreaAdmin && index == testimonials.length) {
                    return InfoAddContentCard(
                      label: 'Add Testimonial',
                      description: 'Create a new testimony record.',
                      onTap: () => _onAddTestimonialTap(context),
                    );
                  }
                  return _TestimonialCard(
                    testimonial: testimonials[index],
                    onTap: () =>
                        _onTestimonialTap(context, testimonials[index]),
                  );
                },
              );
            }

            return MediaQuery.removePadding(
              removeTop: true,
              context: context,
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (isAreaAdmin && index == testimonials.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: InfoAddContentCard(
                        label: 'Add Testimonial',
                        description: 'Create a new testimony record.',
                        onTap: () => _onAddTestimonialTap(context),
                      ),
                    );
                  }
                  return _TestimonialListSlot(
                    testimonial: testimonials[index],
                    onTap: () =>
                        _onTestimonialTap(context, testimonials[index]),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onAddTestimonialTap(BuildContext context) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditInfoBodyPage.forTestimonial()),
    );
    if (changed == true) {
      onRefresh();
    }
  }

  void _onTestimonialTap(BuildContext context, TestimonialInfo testimonial) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => TestimonialInfoPage(documentId: testimonial.id)),
    ).then((_) => onRefresh());
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.testimonial, required this.onTap});

  final TestimonialInfo testimonial;
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
              imageUrl: testimonial.imgSrc,
              heroTag: 'info_testimonial_${testimonial.id}',
              alignment: Alignment.topCenter,
            ),
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
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        testimonial.name,
                        style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(testimonial.church,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimonialListSlot extends StatelessWidget {
  const _TestimonialListSlot({required this.testimonial, required this.onTap});

  final TestimonialInfo testimonial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.32,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(32)),
                    child: InfoCardImage(
                      imageUrl: testimonial.imgSrc,
                      heroTag: 'info_testimonial_${testimonial.id}',
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(32)),
                    child: Container(
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
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          Text(testimonial.name,
                              style: const TextStyle(
                                  fontSize: 24, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(testimonial.church,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
