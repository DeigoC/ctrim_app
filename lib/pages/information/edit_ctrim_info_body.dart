import 'package:flutter/material.dart';

import '../../models/info/ctrim_info.dart';
import '../../utility/app_context.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import 'edit_info_body_shared.dart';

class EditCtrimInfoBody extends StatefulWidget {
  const EditCtrimInfoBody({
    super.key,
    this.info,
    this.initialCategory = CtrimInfoCategory.principle,
  });

  final CtrimInfo? info;
  final CtrimInfoCategory initialCategory;

  @override
  State<EditCtrimInfoBody> createState() => _EditCtrimInfoBodyState();
}

class _EditCtrimInfoBodyState extends State<EditCtrimInfoBody>
    with EditInfoBodyEditorMixin<EditCtrimInfoBody> {
  late final TextEditingController _secondaryController;
  late final String _initialSecondary;
  late final CtrimInfoCategory _initialCtrimCategory;
  late CtrimInfoCategory _selectedCtrimCategory;

  @override
  bool get isEditing => widget.info != null;

  @override
  String get pageTitle =>
      widget.info == null ? 'Add CTRIM Info' : 'Edit CTRIM Info';

  @override
  String get bodyPlaceholder => 'Tap here to write the topic content…';

  @override
  String get primaryLabel => 'Topic title';

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
  void initSectionControllers() {
    _initialCtrimCategory = widget.initialCategory;
    _selectedCtrimCategory = _initialCtrimCategory;
    _initialSecondary = widget.info?.description ?? '';
    _secondaryController = TextEditingController(text: _initialSecondary);
  }

  @override
  void disposeSectionControllers() {
    _secondaryController.dispose();
  }

  @override
  bool hasUnsavedChangesExtras() {
    if (_secondaryController.text.trim() != _initialSecondary.trim()) {
      return true;
    }
    if (_selectedCtrimCategory != _initialCtrimCategory) {
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
        decoration: const InputDecoration(labelText: 'Description'),
        minLines: 2,
        maxLines: 3,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<CtrimInfoCategory>(
        initialValue: _selectedCtrimCategory,
        decoration: const InputDecoration(
          labelText: 'Section',
          helperText:
              'Principles appear under “Our core ideologies”; Teachings under '
              '“Simple lessons to get started!”',
        ),
        items: CtrimInfoCategory.values
            .map(
              (category) => DropdownMenuItem<CtrimInfoCategory>(
                value: category,
                child: Text(category.label),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() => _selectedCtrimCategory = value);
        },
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
    final existingInfo = widget.info;
    final info = CtrimInfo(
      id: existingInfo?.id ??
          generateDocumentId(primaryController.text, 'ctrim'),
      title: primaryController.text.trim(),
      description: _secondaryController.text.trim(),
      analyticsTitle: primaryController.text.trim(),
      body: body,
      imageSources: imageSources,
      updatedBy: appContext.currentUser.id,
      updatedAt: now,
      displayOrder: displayOrder,
      category: _selectedCtrimCategory,
    );
    await infoRepository.saveCtrimInfo(info);
    await UserActivityRecorder().record(
      actorUserId: appContext.currentUser.id,
      log: existingInfo == null
          ? UserActivityMessages.createdCtrimInfo
          : UserActivityMessages.editedCtrimInfo,
      documentId: info.id,
    );
  }

  @override
  Future<void> persistDelete(final AppContext appContext) async {
    await infoRepository.deleteCtrimInfo(widget.info!.id);
    await UserActivityRecorder().record(
      actorUserId: appContext.currentUser.id,
      log: UserActivityMessages.deletedCtrimInfo,
      documentId: widget.info!.id,
    );
  }
}
