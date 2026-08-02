import 'package:flutter/material.dart';

import '../../models/info/testimonial_info.dart';
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
    return InfoSectionListTab<TestimonialInfo>(
      future: testimonialsFuture,
      onRefresh: onRefresh,
      storageKey: 'information_testimonials_tab',
      emptyMessage: 'No testimonials available yet.',
      addLabel: 'Add Testimonial',
      addDescription: 'Create a new testimony record.',
      onAdd: (context) => openInfoEditorAndRefresh(
        context: context,
        editor: EditInfoBodyPage.forTestimonial(),
        onRefresh: onRefresh,
      ),
      gridAspectRatio: (_) => 3 / 4,
      mobileItemHeight: MediaQuery.sizeOf(context).height * 0.34,
      itemBuilder: (context, testimonial, {required bool wide}) {
        return InfoHeroOverlayCard(
          imageUrl: testimonial.imgSrc,
          heroTag: 'info_testimonial_${testimonial.id}',
          imageAlignment: Alignment.topCenter,
          onTap: () => openInfoDetailAndRefresh(
            context: context,
            page: TestimonialInfoPage(documentId: testimonial.id),
            onRefresh: onRefresh,
          ),
          overlay: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: Colors.white, size: wide ? 22 : 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      testimonial.name,
                      style: TextStyle(
                        fontSize: wide ? 20 : 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (testimonial.church.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  testimonial.church,
                  style: TextStyle(
                    fontSize: wide ? 14 : 16,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
