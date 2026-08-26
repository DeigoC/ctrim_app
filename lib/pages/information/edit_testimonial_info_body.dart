import 'package:flutter/material.dart';

import '../../models/info/testimonial_info.dart';
import '../../utility/app_context.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import 'edit_info_body_shared.dart';

class EditTestimonialInfoBody extends StatefulWidget {
  const EditTestimonialInfoBody({super.key, this.info});

  final TestimonialInfo? info;

  @override
  State<EditTestimonialInfoBody> createState() =>
      _EditTestimonialInfoBodyState();
}

class _EditTestimonialInfoBodyState extends State<EditTestimonialInfoBody>
    with EditInfoBodyEditorMixin<EditTestimonialInfoBody> {
  late final TextEditingController _secondaryController;
  late final TextEditingController _summaryController;
  late final String _initialSecondary;
  late final String _initialSummary;

  @override
  bool get isEditing => widget.info != null;

  @override
  String get pageTitle =>
      widget.info == null ? 'Add Testimonial' : 'Edit Testimonial';

  @override
  String get bodyPlaceholder => 'Tap here to write the testimony…';

  @override
  String get primaryLabel => 'Name';

  @override
  List<dynamic> get resolveInitialBody => List<dynamic>.from(
      widget.info?.body ?? EditInfoBodyEditorMixin.emptyBody);

  @override
  String get initialPrimaryValue => widget.info?.name ?? '';

  @override
  String get initialImagesValue =>
      (widget.info?.imageSources ?? const <String>[]).join('\n');

  @override
  String get initialDisplayOrderValue =>
      (widget.info?.displayOrder ?? 0).toString();

  @override
  void initSectionControllers() {
    _initialSecondary = widget.info?.church ?? '';
    _initialSummary = widget.info?.summary ?? '';
    _secondaryController = TextEditingController(text: _initialSecondary);
    _summaryController = TextEditingController(text: _initialSummary);
  }

  @override
  void disposeSectionControllers() {
    _secondaryController.dispose();
    _summaryController.dispose();
  }

  @override
  bool hasUnsavedChangesExtras() {
    if (_secondaryController.text.trim() != _initialSecondary.trim()) {
      return true;
    }
    if (_summaryController.text.trim() != _initialSummary.trim()) {
      return true;
    }
    return false;
  }

  @override
  List<Widget> buildSectionMetadataFields() {
    return [
      const SizedBox(height: 12),
      TextFormField(
        controller: _secondaryController,
        decoration: const InputDecoration(labelText: 'Church'),
        minLines: 1,
        maxLines: 1,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _summaryController,
        decoration: const InputDecoration(
          labelText: 'Summary',
        ),
        minLines: 2,
        maxLines: 3,
      ),
    ];
  }

  @override
  Future<void> persistSave({
    required final AppContext appContext,
    required final List<dynamic> body,
    required final List<String> imageSources,
    required final int displayOrder,
    required final DateTime now,
  }) async {
    final existingTestimonial = widget.info;
    final testimonial = TestimonialInfo(
      id: existingTestimonial?.id ??
          generateDocumentId(primaryController.text, 'testimonial'),
      name: primaryController.text.trim(),
      church: _secondaryController.text.trim(),
      body: body,
      imageSources: imageSources,
      summary: _summaryController.text.trim(),
      updatedBy: appContext.currentUser.id,
      updatedAt: now,
      displayOrder: displayOrder,
    );
    await infoRepository.saveTestimonialInfo(testimonial);
    await UserActivityRecorder().record(
      actorUserId: appContext.currentUser.id,
      log: existingTestimonial == null
          ? UserActivityMessages.createdTestimonial
          : UserActivityMessages.editedTestimonial,
      documentId: testimonial.id,
    );
  }

  @override
  Future<void> persistDelete(final AppContext appContext) async {
    await infoRepository.deleteTestimonialInfo(widget.info!.id);
    await UserActivityRecorder().record(
      actorUserId: appContext.currentUser.id,
      log: UserActivityMessages.deletedTestimonial,
      documentId: widget.info!.id,
    );
  }
}
