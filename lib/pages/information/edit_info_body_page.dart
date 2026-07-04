import 'package:ctrim_app/models/info/church_info.dart';
import 'package:ctrim_app/models/info/ctrim_info.dart';
import 'package:ctrim_app/models/info/testimonial_into.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/utility/info_repository.dart';
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
  });

  factory EditInfoBodyPage.forChurch({final ChurchInfo? info}) {
    return EditInfoBodyPage._(section: InfoEditorSection.church, churchInfo: info);
  }

  factory EditInfoBodyPage.forTestimonial({final TestimonialInfo? info}) {
    return EditInfoBodyPage._(section: InfoEditorSection.testimonial, testimonialInfo: info);
  }

  factory EditInfoBodyPage.forCtrim({final CtrimInfo? info}) {
    return EditInfoBodyPage._(section: InfoEditorSection.ctrim, ctrimInfo: info);
  }

  final ChurchInfo? churchInfo;
  final CtrimInfo? ctrimInfo;
  final InfoEditorSection section;
  final TestimonialInfo? testimonialInfo;

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialBody = _resolveInitialBody();
    _primaryController = TextEditingController(text: _initialPrimaryValue());
    _secondaryController = TextEditingController(text: _initialSecondaryValue());
    _summaryController = TextEditingController(text: _initialSummaryValue());
    _imagesController = TextEditingController(text: _initialImageSourcesValue());
    _displayOrderController = TextEditingController(text: _initialDisplayOrderValue());
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle()),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._buildMetadataFields(),
              const SizedBox(height: 16),
              Text('Body', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return QuillEditorWidget(
      key: _editorKey,
      jsonContent: _initialBody,
      showAlignmentButtons: true,
      showSubscript: false,
      showSuperscript: true,
      showCodeBlock: true,
      multiRowsDisplay: true,
    );
  }

  List<Widget> _buildMetadataFields() {
    final List<Widget> fields = [
      TextFormField(
        controller: _primaryController,
        decoration: InputDecoration(labelText: _primaryLabel()),
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _secondaryController,
        decoration: InputDecoration(labelText: _secondaryLabel()),
        minLines: widget.section == InfoEditorSection.ctrim ? 2 : 1,
        maxLines: widget.section == InfoEditorSection.ctrim ? 3 : 1,
        validator: widget.section == InfoEditorSection.ctrim
            ? (value) => (value == null || value.trim().isEmpty) ? 'Required' : null
            : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _summaryController,
        decoration: const InputDecoration(labelText: 'Summary / subtitle'),
        minLines: 2,
        maxLines: 3,
      ),
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
          helperText: 'Enter one image URL per line.',
        ),
        minLines: 3,
        maxLines: 6,
      ),
    ];

    return fields;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appContext = Provider.of<AppContext>(context, listen: false);
    if (!appContext.currentUser.isAreaAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only area admin users can edit this content.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final body = _editorKey.currentState?.getDocumentJson() ?? _initialBody;
      final imageSources = _readImageSources();
      final displayOrder = int.tryParse(_displayOrderController.text.trim()) ?? 0;
      final now = DateTime.now();

      switch (widget.section) {
        case InfoEditorSection.church:
          final existingChurch = widget.churchInfo;
          final church = ChurchInfo(
            id: existingChurch?.id ?? _generateDocumentId(_primaryController.text, 'church'),
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
          break;
        case InfoEditorSection.testimonial:
          final existingTestimonial = widget.testimonialInfo;
          final testimonial = TestimonialInfo(
            id: existingTestimonial?.id ?? _generateDocumentId(_primaryController.text, 'testimonial'),
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
          break;
        case InfoEditorSection.ctrim:
          final existingInfo = widget.ctrimInfo;
          final info = CtrimInfo(
            id: existingInfo?.id ?? _generateDocumentId(_primaryController.text, 'ctrim'),
            title: _primaryController.text.trim(),
            description: _secondaryController.text.trim(),
            analyticsTitle: _primaryController.text.trim(),
            body: body,
            imageSources: imageSources,
            updatedBy: appContext.currentUser.id,
            updatedAt: now,
            displayOrder: displayOrder,
          );
          await _infoRepository.saveCtrimInfo(info);
          break;
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
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

  String _generateDocumentId(final String source, final String prefix) {
    final normalized =
        source.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }

  List<String> _readImageSources() {
    return _imagesController.text.split('\n').map((entry) => entry.trim()).where((entry) => entry.isNotEmpty).toList();
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
        return (widget.testimonialInfo?.imageSources ?? const <String>[]).join('\n');
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
        return widget.churchInfo == null ? 'Add Church Info' : 'Edit Church Info';
      case InfoEditorSection.testimonial:
        return widget.testimonialInfo == null ? 'Add Testimonial' : 'Edit Testimonial';
      case InfoEditorSection.ctrim:
        return widget.ctrimInfo == null ? 'Add CTRIM Info' : 'Edit CTRIM Info';
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
        return 'Location / subtitle (optional)';
      case InfoEditorSection.testimonial:
        return 'Church';
      case InfoEditorSection.ctrim:
        return 'Description';
    }
  }
}
