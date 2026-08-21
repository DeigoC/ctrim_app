import 'package:ctrim_app/models/info/church_info.dart';
import 'package:ctrim_app/models/info/ctrim_info.dart';
import 'package:ctrim_app/models/info/testimonial_info.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/utility/info_repository.dart';
import 'package:ctrim_app/utility/responsive_layout.dart';
import 'package:ctrim_app/utility/user_activity_messages.dart';
import 'package:ctrim_app/utility/user_activity_recorder.dart';
import 'package:ctrim_app/widgets/quill_editor_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum InfoEditorSection { church, testimonial, ctrim }

class EditInfoBodyPage extends StatefulWidget {
  const EditInfoBodyPage._({
    required this.section,
    this.churchInfo,
    this.testimonialInfo,
    this.ctrimInfo,
    this.initialCtrimCategory = CtrimInfoCategory.principle,
  });

  factory EditInfoBodyPage.forChurch({final ChurchInfo? info}) {
    return EditInfoBodyPage._(
        section: InfoEditorSection.church, churchInfo: info);
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
  final CtrimInfo? ctrimInfo;
  final CtrimInfoCategory initialCtrimCategory;
  final InfoEditorSection section;
  final TestimonialInfo? testimonialInfo;

  bool get isEditing => switch (section) {
        InfoEditorSection.church => churchInfo != null,
        InfoEditorSection.testimonial => testimonialInfo != null,
        InfoEditorSection.ctrim => ctrimInfo != null,
      };

  @override
  State<EditInfoBodyPage> createState() => _EditInfoBodyPageState();
}

class _EditInfoBodyPageState extends State<EditInfoBodyPage> {
  static const List<dynamic> _emptyBody = <dynamic>[
    <String, dynamic>{'insert': '\n'}
  ];

  final GlobalKey<QuillEditorWidgetState> _editorKey = GlobalKey();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final InfoRepository _infoRepository = InfoRepository();
  late final TextEditingController _primaryController;
  late final TextEditingController _secondaryController;
  late final TextEditingController _summaryController;
  late final TextEditingController _imagesController;
  late final TextEditingController _displayOrderController;
  late final List<dynamic> _initialBody;
  late final String _initialPrimary;
  late final String _initialSecondary;
  late final String _initialSummary;
  late final String _initialImages;
  late final String _initialDisplayOrder;
  late final CtrimInfoCategory _initialCtrimCategory;
  late CtrimInfoCategory _selectedCtrimCategory;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isSaved = false;
  bool _allowPop = false;
  bool _checkedAccess = false;

  void _popRouteAfterAllowing({final Object? result}) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initialBody = _resolveInitialBody();
    _initialPrimary = _initialPrimaryValue();
    _initialSecondary = _initialSecondaryValue();
    _initialSummary = _initialSummaryValue();
    _initialImages = _initialImageSourcesValue();
    _initialDisplayOrder = _initialDisplayOrderValue();
    _initialCtrimCategory = widget.initialCtrimCategory;
    _selectedCtrimCategory = _initialCtrimCategory;
    _primaryController = TextEditingController(text: _initialPrimary);
    _secondaryController = TextEditingController(text: _initialSecondary);
    _summaryController = TextEditingController(text: _initialSummary);
    _imagesController = TextEditingController(text: _initialImages);
    _displayOrderController = TextEditingController(text: _initialDisplayOrder);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedAccess) return;
    _checkedAccess = true;
    final canManage = Provider.of<AppContext>(context, listen: false)
        .currentUser
        .canManageInfo;
    if (!canManage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Only area admins and leaders can edit this content.'),
          ),
        );
        _popRouteAfterAllowing();
      });
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _summaryController.dispose();
    _imagesController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final double gutter =
        ResponsiveLayout.horizontalGutter(size.width, narrowPadding: 16);
    final bool busy = _isSaving || _isDeleting;

    return PopScope(
      canPop: _allowPop || _isSaved,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowPop || _isSaved) {
          return;
        }
        if (!_hasUnsavedChanges()) {
          _popRouteAfterAllowing();
          return;
        }
        final shouldPop = await DialogManager.discardChanges(context: context);
        if (shouldPop && mounted) {
          _popRouteAfterAllowing();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_pageTitle()),
          actions: [
            if (widget.isEditing)
              IconButton(
                onPressed: busy ? null : _delete,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                tooltip: 'Delete',
              ),
            TextButton.icon(
              onPressed: busy ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: ResponsiveLayout.chordMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._buildMetadataFields(),
                    const SizedBox(height: 16),
                    Text('Body',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    QuillEditorWidget(
                      key: _editorKey,
                      jsonContent: _initialBody,
                      showAlignmentButtons: true,
                      showSubscript: false,
                      showSuperscript: true,
                      showCodeBlock: true,
                      multiRowsDisplay: true,
                      placeholder: _bodyPlaceholder(),
                      expands: false,
                      minHeight: 180,
                      maxHeight: 420,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasUnsavedChanges() {
    if (_primaryController.text.trim() != _initialPrimary.trim()) {
      return true;
    }
    if (_secondaryController.text.trim() != _initialSecondary.trim()) {
      return true;
    }
    if (_summaryController.text.trim() != _initialSummary.trim()) {
      return true;
    }
    if (_imagesController.text.trim() != _initialImages.trim()) {
      return true;
    }
    if (_displayOrderController.text.trim() != _initialDisplayOrder.trim()) {
      return true;
    }
    if (widget.section == InfoEditorSection.ctrim &&
        _selectedCtrimCategory != _initialCtrimCategory) {
      return true;
    }

    final currentBody =
        _editorKey.currentState?.getDocumentJson() ?? _initialBody;
    return !_isSameBody(currentBody, _initialBody);
  }

  bool _isSameBody(final List<dynamic> a, final List<dynamic> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].toString() != b[i].toString()) {
        return false;
      }
    }
    return true;
  }

  List<Widget> _buildMetadataFields() {
    final fields = <Widget>[
      TextFormField(
        controller: _primaryController,
        decoration: InputDecoration(labelText: _primaryLabel()),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
    ];

    if (widget.section != InfoEditorSection.church) {
      fields.addAll([
        const SizedBox(height: 12),
        TextFormField(
          controller: _secondaryController,
          decoration: InputDecoration(labelText: _secondaryLabel()),
          minLines: widget.section == InfoEditorSection.ctrim ? 2 : 1,
          maxLines: widget.section == InfoEditorSection.ctrim ? 3 : 1,
          validator: widget.section == InfoEditorSection.ctrim
              ? (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      ]);
    }

    if (widget.section != InfoEditorSection.ctrim) {
      fields.addAll([
        const SizedBox(height: 12),
        TextFormField(
          controller: _summaryController,
          decoration: InputDecoration(
            labelText: widget.section == InfoEditorSection.church
                ? 'Summary / subtitle'
                : 'Summary',
          ),
          minLines: 2,
          maxLines: 3,
        ),
      ]);
    }

    if (widget.section == InfoEditorSection.ctrim) {
      fields.addAll([
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
      ]);
    }

    fields.addAll([
      const SizedBox(height: 12),
      TextFormField(
        controller: _displayOrderController,
        decoration: const InputDecoration(labelText: 'Display order'),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _imagesController,
        decoration: const InputDecoration(
          labelText: 'Image URLs',
          helperText:
              'Enter one image URL per line. The first image is used as the cover.',
        ),
        minLines: 3,
        maxLines: 6,
      ),
    ]);

    return fields;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appContext = Provider.of<AppContext>(context, listen: false);
    if (!appContext.currentUser.canManageInfo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Only area admins and leaders can edit this content.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final body = _editorKey.currentState?.getDocumentJson() ?? _initialBody;
      final imageSources = _readImageSources();
      final displayOrder =
          int.tryParse(_displayOrderController.text.trim()) ?? 0;
      final now = DateTime.now();

      switch (widget.section) {
        case InfoEditorSection.church:
          final existingChurch = widget.churchInfo;
          final church = ChurchInfo(
            id: existingChurch?.id ??
                _generateDocumentId(_primaryController.text, 'church'),
            title: _primaryController.text.trim(),
            analyticsTitle: _primaryController.text.trim(),
            body: body,
            imageSources: imageSources,
            summary: _summaryController.text.trim(),
            updatedBy: appContext.currentUser.id,
            updatedAt: now,
            displayOrder: displayOrder,
          );
          await _infoRepository.saveChurchInfo(church);
          await UserActivityRecorder().record(
            actorUserId: appContext.currentUser.id,
            log: existingChurch == null
                ? UserActivityMessages.createdChurchRecord
                : UserActivityMessages.editedChurchRecord,
            documentId: church.id,
          );
          break;
        case InfoEditorSection.testimonial:
          final existingTestimonial = widget.testimonialInfo;
          final testimonial = TestimonialInfo(
            id: existingTestimonial?.id ??
                _generateDocumentId(_primaryController.text, 'testimonial'),
            name: _primaryController.text.trim(),
            church: _secondaryController.text.trim(),
            body: body,
            imageSources: imageSources,
            summary: _summaryController.text.trim(),
            updatedBy: appContext.currentUser.id,
            updatedAt: now,
            displayOrder: displayOrder,
          );
          await _infoRepository.saveTestimonialInfo(testimonial);
          await UserActivityRecorder().record(
            actorUserId: appContext.currentUser.id,
            log: existingTestimonial == null
                ? UserActivityMessages.createdTestimonial
                : UserActivityMessages.editedTestimonial,
            documentId: testimonial.id,
          );
          break;
        case InfoEditorSection.ctrim:
          final existingInfo = widget.ctrimInfo;
          final info = CtrimInfo(
            id: existingInfo?.id ??
                _generateDocumentId(_primaryController.text, 'ctrim'),
            title: _primaryController.text.trim(),
            description: _secondaryController.text.trim(),
            analyticsTitle: _primaryController.text.trim(),
            body: body,
            imageSources: imageSources,
            updatedBy: appContext.currentUser.id,
            updatedAt: now,
            displayOrder: displayOrder,
            category: _selectedCtrimCategory,
          );
          await _infoRepository.saveCtrimInfo(info);
          await UserActivityRecorder().record(
            actorUserId: appContext.currentUser.id,
            log: existingInfo == null
                ? UserActivityMessages.createdCtrimInfo
                : UserActivityMessages.editedCtrimInfo,
            documentId: info.id,
          );
          break;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _isSaved = true;
      });
      _popRouteAfterAllowing(result: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      await DialogManager.showAlertDialog(
        context: context,
        title: 'Save failed',
        content: error.toString(),
        isError: true,
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    if (!appContext.currentUser.canManageInfo) {
      return;
    }

    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: 'Delete this content?',
      content: 'This cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      switch (widget.section) {
        case InfoEditorSection.church:
          await _infoRepository.deleteChurchInfo(widget.churchInfo!.id);
          await UserActivityRecorder().record(
            actorUserId: appContext.currentUser.id,
            log: UserActivityMessages.deletedChurchRecord,
            documentId: widget.churchInfo!.id,
          );
          break;
        case InfoEditorSection.testimonial:
          await _infoRepository
              .deleteTestimonialInfo(widget.testimonialInfo!.id);
          await UserActivityRecorder().record(
            actorUserId: appContext.currentUser.id,
            log: UserActivityMessages.deletedTestimonial,
            documentId: widget.testimonialInfo!.id,
          );
          break;
        case InfoEditorSection.ctrim:
          await _infoRepository.deleteCtrimInfo(widget.ctrimInfo!.id);
          await UserActivityRecorder().record(
            actorUserId: appContext.currentUser.id,
            log: UserActivityMessages.deletedCtrimInfo,
            documentId: widget.ctrimInfo!.id,
          );
          break;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _isSaved = true;
      });
      _popRouteAfterAllowing(result: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      await DialogManager.showAlertDialog(
        context: context,
        title: 'Delete failed',
        content: error.toString(),
        isError: true,
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  String _generateDocumentId(final String source, final String prefix) {
    final normalized = source
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }

  List<String> _readImageSources() {
    return _imagesController.text
        .split('\n')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  List<dynamic> _resolveInitialBody() {
    switch (widget.section) {
      case InfoEditorSection.church:
        return List<dynamic>.from(widget.churchInfo?.body ?? _emptyBody);
      case InfoEditorSection.testimonial:
        return List<dynamic>.from(widget.testimonialInfo?.body ?? _emptyBody);
      case InfoEditorSection.ctrim:
        return List<dynamic>.from(widget.ctrimInfo?.body ?? _emptyBody);
    }
  }

  String _initialDisplayOrderValue() {
    switch (widget.section) {
      case InfoEditorSection.church:
        return (widget.churchInfo?.displayOrder ?? 0).toString();
      case InfoEditorSection.testimonial:
        return (widget.testimonialInfo?.displayOrder ?? 0).toString();
      case InfoEditorSection.ctrim:
        return (widget.ctrimInfo?.displayOrder ?? 0).toString();
    }
  }

  String _initialImageSourcesValue() {
    switch (widget.section) {
      case InfoEditorSection.church:
        return (widget.churchInfo?.imageSources ?? const <String>[]).join('\n');
      case InfoEditorSection.testimonial:
        return (widget.testimonialInfo?.imageSources ?? const <String>[])
            .join('\n');
      case InfoEditorSection.ctrim:
        return (widget.ctrimInfo?.imageSources ?? const <String>[]).join('\n');
    }
  }

  String _initialPrimaryValue() {
    switch (widget.section) {
      case InfoEditorSection.church:
        return widget.churchInfo?.title ?? '';
      case InfoEditorSection.testimonial:
        return widget.testimonialInfo?.name ?? '';
      case InfoEditorSection.ctrim:
        return widget.ctrimInfo?.title ?? '';
    }
  }

  String _initialSecondaryValue() {
    switch (widget.section) {
      case InfoEditorSection.church:
        return '';
      case InfoEditorSection.testimonial:
        return widget.testimonialInfo?.church ?? '';
      case InfoEditorSection.ctrim:
        return widget.ctrimInfo?.description ?? '';
    }
  }

  String _initialSummaryValue() {
    switch (widget.section) {
      case InfoEditorSection.church:
        return widget.churchInfo?.summary ?? '';
      case InfoEditorSection.testimonial:
        return widget.testimonialInfo?.summary ?? '';
      case InfoEditorSection.ctrim:
        return '';
    }
  }

  String _pageTitle() {
    switch (widget.section) {
      case InfoEditorSection.church:
        return widget.churchInfo == null
            ? 'Add Church Info'
            : 'Edit Church Info';
      case InfoEditorSection.testimonial:
        return widget.testimonialInfo == null
            ? 'Add Testimonial'
            : 'Edit Testimonial';
      case InfoEditorSection.ctrim:
        return widget.ctrimInfo == null ? 'Add CTRIM Info' : 'Edit CTRIM Info';
    }
  }

  String _bodyPlaceholder() {
    switch (widget.section) {
      case InfoEditorSection.church:
        return 'Tap here to write about this church — history, location, '
            'meeting times, or anything visitors should know…';
      case InfoEditorSection.testimonial:
        return 'Tap here to write the testimony…';
      case InfoEditorSection.ctrim:
        return 'Tap here to write the topic content…';
    }
  }

  String _primaryLabel() {
    switch (widget.section) {
      case InfoEditorSection.church:
        return 'Church title';
      case InfoEditorSection.testimonial:
        return 'Name';
      case InfoEditorSection.ctrim:
        return 'Topic title';
    }
  }

  String _secondaryLabel() {
    switch (widget.section) {
      case InfoEditorSection.church:
        return '';
      case InfoEditorSection.testimonial:
        return 'Church';
      case InfoEditorSection.ctrim:
        return 'Description';
    }
  }
}
