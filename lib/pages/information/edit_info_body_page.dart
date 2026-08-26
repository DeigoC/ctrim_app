import 'package:flutter/material.dart';

import '../../models/info/church_info.dart';
import '../../models/info/church_page.dart';
import '../../models/info/ctrim_info.dart';
import '../../models/info/testimonial_info.dart';
import 'edit_church_info_body.dart';
import 'edit_church_page_info_body.dart';
import 'edit_ctrim_info_body.dart';
import 'edit_testimonial_info_body.dart';

enum InfoEditorSection { church, churchPage, testimonial, ctrim }

class EditInfoBodyPage extends StatelessWidget {
  const EditInfoBodyPage._({
    required this.section,
    this.churchInfo,
    this.churchPage,
    this.churchId,
    this.testimonialInfo,
    this.ctrimInfo,
    this.initialCtrimCategory = CtrimInfoCategory.principle,
  });

  factory EditInfoBodyPage.forChurch({final ChurchInfo? info}) {
    return EditInfoBodyPage._(
        section: InfoEditorSection.church, churchInfo: info);
  }

  factory EditInfoBodyPage.forChurchPage({
    required final String churchId,
    final ChurchPage? info,
  }) {
    return EditInfoBodyPage._(
      section: InfoEditorSection.churchPage,
      churchId: churchId,
      churchPage: info,
    );
  }

  factory EditInfoBodyPage.forTestimonial({final TestimonialInfo? info}) {
    return EditInfoBodyPage._(
        section: InfoEditorSection.testimonial, testimonialInfo: info);
  }

  factory EditInfoBodyPage.forCtrim({
    final CtrimInfo? info,
    final CtrimInfoCategory initialCategory = CtrimInfoCategory.principle,
  }) {
    return EditInfoBodyPage._(
      section: InfoEditorSection.ctrim,
      ctrimInfo: info,
      initialCtrimCategory: info?.category ?? initialCategory,
    );
  }

  final ChurchInfo? churchInfo;
  final ChurchPage? churchPage;
  final String? churchId;
  final CtrimInfo? ctrimInfo;
  final CtrimInfoCategory initialCtrimCategory;
  final InfoEditorSection section;
  final TestimonialInfo? testimonialInfo;

  bool get isEditing => switch (section) {
        InfoEditorSection.church => churchInfo != null,
        InfoEditorSection.churchPage => churchPage != null,
        InfoEditorSection.testimonial => testimonialInfo != null,
        InfoEditorSection.ctrim => ctrimInfo != null,
      };

  @override
  Widget build(final BuildContext context) {
    return switch (section) {
      InfoEditorSection.church => EditChurchInfoBody(info: churchInfo),
      InfoEditorSection.churchPage => EditChurchPageInfoBody(
          churchId: churchId,
          info: churchPage,
        ),
      InfoEditorSection.testimonial =>
        EditTestimonialInfoBody(info: testimonialInfo),
      InfoEditorSection.ctrim => EditCtrimInfoBody(
          info: ctrimInfo,
          initialCategory: initialCtrimCategory,
        ),
    };
  }
}
