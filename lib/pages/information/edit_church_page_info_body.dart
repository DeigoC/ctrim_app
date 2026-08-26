import 'package:flutter/material.dart';

import '../../models/info/church_page.dart';
import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import 'edit_info_body_shared.dart';

class EditChurchPageInfoBody extends StatefulWidget {
  const EditChurchPageInfoBody({
    super.key,
    this.churchId,
    this.info,
  });

  final String? churchId;
  final ChurchPage? info;

  @override
  State<EditChurchPageInfoBody> createState() => _EditChurchPageInfoBodyState();
}

class _EditChurchPageInfoBodyState extends State<EditChurchPageInfoBody>
    with EditInfoBodyEditorMixin<EditChurchPageInfoBody> {
  late final TextEditingController _summaryController;
  late final String _initialSummary;

  @override
  bool get isEditing => widget.info != null;

  @override
  String get pageTitle =>
      widget.info == null ? 'Add Church Page' : 'Edit Church Page';

  @override
  String get bodyPlaceholder =>
      'Tap here to write this page — getting here, Sunday service, '
      'or other details visitors should know…';

  @override
  String get primaryLabel => 'Page title';

  @override
  List<dynamic> get resolveInitialBody => List<dynamic>.from(
      widget.info?.body ?? EditInfoBodyEditorMixin.emptyBody);

  @override
  String get initialPrimaryValue => widget.info?.title ?? '';

  @override
  String get initialImagesValue =>
      (widget.info?.imageSources ?? const <String>[]).join('\n');

  @override
  String get initialDisplayOrderValue =>
      (widget.info?.displayOrder ?? 0).toString();

  @override
  bool canEditSection(final User user) => user.canManageChurchPages;

  @override
  String accessDeniedMessage() => 'Only area admins can edit church pages.';

  @override
  void initSectionControllers() {
    _initialSummary = widget.info?.summary ?? '';
    _summaryController = TextEditingController(text: _initialSummary);
  }

  @override
  void disposeSectionControllers() {
    _summaryController.dispose();
  }

  @override
  bool hasUnsavedChangesExtras() {
    return _summaryController.text.trim() != _initialSummary.trim();
  }

  @override
  List<Widget> buildSectionMetadataFields() {
    return [
      const SizedBox(height: 12),
      TextFormField(
        controller: _summaryController,
        decoration: const InputDecoration(
          labelText: 'Summary / subtitle',
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
    final parentChurchId = widget.churchId ?? widget.info?.churchId;
    if (parentChurchId == null || parentChurchId.isEmpty) {
      throw StateError('Church page editor is missing churchId.');
    }
    final existingPage = widget.info;
    final page = ChurchPage(
      id: existingPage?.id ??
          generateDocumentId(primaryController.text, 'church_page'),
      churchId: parentChurchId,
      title: primaryController.text.trim(),
      body: body,
      imageSources: imageSources,
      summary: _summaryController.text.trim(),
      updatedBy: appContext.currentUser.id,
      updatedAt: now,
      displayOrder: displayOrder,
    );
    await infoRepository.saveChurchPage(page);
    await UserActivityRecorder().record(
      actorUserId: appContext.currentUser.id,
      log: existingPage == null
          ? UserActivityMessages.createdChurchPage
          : UserActivityMessages.editedChurchPage,
      documentId: page.id,
    );
  }

  @override
  Future<void> persistDelete(final AppContext appContext) async {
    final parentChurchId = widget.churchId ?? widget.info!.churchId;
    await infoRepository.deleteChurchPage(
      parentChurchId,
      widget.info!.id,
    );
    await UserActivityRecorder().record(
      actorUserId: appContext.currentUser.id,
      log: UserActivityMessages.deletedChurchPage,
      documentId: widget.info!.id,
    );
  }
}
