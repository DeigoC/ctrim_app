import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/info_repository.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/quill_editor_wrapper.dart';

/// Shared scaffold, image test/preview, and save/delete chrome for info body
/// editors. Section files override the hooks and persist methods.
mixin EditInfoBodyEditorMixin<T extends StatefulWidget> on State<T> {
  static const List<dynamic> emptyBody = <dynamic>[
    <String, dynamic>{'insert': '\n'}
  ];

  final GlobalKey<QuillEditorWidgetState> _editorKey = GlobalKey();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final InfoRepository infoRepository = InfoRepository();
  late final TextEditingController primaryController;
  late final TextEditingController _imagesController;
  late final TextEditingController _displayOrderController;
  late final List<dynamic> initialBody;
  late final String _initialPrimary;
  late final String _initialImages;
  late final String _initialDisplayOrder;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isSaved = false;
  bool _allowPop = false;
  bool _checkedAccess = false;
  bool _testingImages = false;
  bool _imagesValidated = true;
  bool _showImageTestSuccess = false;
  String? _imageValidationMessage;
  List<String> _previewImageUrls = const <String>[];

  bool get isEditing;
  String get pageTitle;
  String get bodyPlaceholder;
  String get primaryLabel;
  String get deleteConfirmContent => 'This cannot be undone.';
  List<dynamic> get resolveInitialBody;
  String get initialPrimaryValue;
  String get initialImagesValue;
  String get initialDisplayOrderValue;

  bool canEditSection(final User user) => user.canManageInfo;

  String accessDeniedMessage() =>
      'Only area admins and leaders can edit this content.';

  bool hasUnsavedChangesExtras();

  List<Widget> buildSectionMetadataFields();

  Future<void> persistSave({
    required final AppContext appContext,
    required final List<dynamic> body,
    required final List<String> imageSources,
    required final int displayOrder,
    required final DateTime now,
  });

  Future<void> persistDelete(final AppContext appContext);

  Future<bool> prepareSave() async => true;

  void initSectionControllers() {}

  void disposeSectionControllers() {}

  void onAccessGranted() {}

  void popRouteAfterAllowing({final Object? result}) {
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
    initialBody = resolveInitialBody;
    _initialPrimary = initialPrimaryValue;
    _initialImages = initialImagesValue;
    _initialDisplayOrder = initialDisplayOrderValue;
    primaryController = TextEditingController(text: _initialPrimary);
    _imagesController = TextEditingController(text: _initialImages);
    _displayOrderController = TextEditingController(text: _initialDisplayOrder);
    _imagesController.addListener(_onImagesTextChanged);
    _imagesValidated = true;
    initSectionControllers();
  }

  void _onImagesTextChanged() {
    final current = readImageSources();
    final initial = _parseImageSourcesText(_initialImages);
    final unchanged = _stringListsEqual(current, initial);
    final empty = current.isEmpty;
    if (!mounted) return;
    setState(() {
      if (empty || unchanged) {
        _imagesValidated = true;
        _imageValidationMessage = null;
        if (empty) {
          _previewImageUrls = const <String>[];
          _showImageTestSuccess = false;
        }
      } else {
        _imagesValidated = false;
        _imageValidationMessage = null;
        _showImageTestSuccess = false;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedAccess) return;
    _checkedAccess = true;
    final user = Provider.of<AppContext>(context, listen: false).currentUser;
    if (!canEditSection(user)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accessDeniedMessage())),
        );
        popRouteAfterAllowing();
      });
      return;
    }
    onAccessGranted();
  }

  @override
  void dispose() {
    _imagesController.removeListener(_onImagesTextChanged);
    disposeSectionControllers();
    primaryController.dispose();
    _imagesController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
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
          popRouteAfterAllowing();
          return;
        }
        final shouldPop = await DialogManager.discardChanges(context: context);
        if (shouldPop && mounted) {
          popRouteAfterAllowing();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
          actions: [
            if (isEditing)
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
              onPressed:
                  busy || (!_imagesValidated && readImageSources().isNotEmpty)
                      ? null
                      : _save,
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
                      jsonContent: initialBody,
                      showAlignmentButtons: true,
                      showSubscript: false,
                      showSuperscript: true,
                      showCodeBlock: true,
                      multiRowsDisplay: true,
                      placeholder: bodyPlaceholder,
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
    if (primaryController.text.trim() != _initialPrimary.trim()) {
      return true;
    }
    if (_imagesController.text.trim() != _initialImages.trim()) {
      return true;
    }
    if (_displayOrderController.text.trim() != _initialDisplayOrder.trim()) {
      return true;
    }
    if (hasUnsavedChangesExtras()) {
      return true;
    }

    final currentBody =
        _editorKey.currentState?.getDocumentJson() ?? initialBody;
    return !_isSameBody(currentBody, initialBody);
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
    return [
      TextFormField(
        controller: primaryController,
        decoration: InputDecoration(labelText: primaryLabel),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
      ...buildSectionMetadataFields(),
      const SizedBox(height: 12),
      TextFormField(
        controller: _displayOrderController,
        decoration: const InputDecoration(labelText: 'Display order'),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _imagesController,
        decoration: InputDecoration(
          labelText: 'Image URLs',
          helperText:
              'Enter one image URL per line. The first image is used as the cover. '
              'Google Drive share links are converted automatically when you test.',
          suffixIcon: IconButton(
            onPressed: _onImageHelpClick,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Image URL help',
          ),
        ),
        minLines: 3,
        maxLines: 6,
        keyboardType: TextInputType.url,
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: _testingImages || _imagesController.text.trim().isEmpty
              ? null
              : _testImagesClick,
          icon: _testingImages
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.visibility_outlined),
          label: Text(_testingImages ? 'Testing…' : 'Test images'),
        ),
      ),
      if (_imageValidationMessage != null) ...[
        const SizedBox(height: 4),
        Text(
          _imageValidationMessage!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ],
      if (_previewImageUrls.isNotEmpty &&
          (_testingImages || _showImageTestSuccess)) ...[
        const SizedBox(height: 12),
        _buildImagePreviewRow(),
      ],
    ];
  }

  Widget _buildImagePreviewRow() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _imagesValidated ? 'Image preview' : 'Testing images…',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _previewImageUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final url = _previewImageUrls[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ColoredBox(
                    color: colorScheme.surfaceContainerHighest,
                    child: Image.network(
                      NetworkImageHelper.getImageUrl(url),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_showImageTestSuccess) ...[
          const SizedBox(height: 8),
          Text(
            _previewImageUrls.length == 1
                ? 'Image loaded successfully.'
                : 'All ${_previewImageUrls.length} images loaded successfully.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _testImagesClick() async {
    final sanitized = readImageSources();
    if (sanitized.isEmpty) return;

    // Rewrite the field with converted Drive links so saved data matches what we tested.
    final sanitizedText = sanitized.join('\n');
    if (_imagesController.text.trim() != sanitizedText) {
      _imagesController.removeListener(_onImagesTextChanged);
      _imagesController.text = sanitizedText;
      _imagesController.addListener(_onImagesTextChanged);
    }

    setState(() {
      _testingImages = true;
      _imagesValidated = false;
      _showImageTestSuccess = false;
      _imageValidationMessage = null;
      _previewImageUrls = sanitized;
    });

    try {
      for (final url in sanitized) {
        final imageUrl = NetworkImageHelper.getImageUrl(url);
        // No custom headers: Flutter web CORS preflight fails if User-Agent is set.
        final response = await http
            .get(Uri.parse(imageUrl))
            .timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode} for $url');
        }
        if (response.bodyBytes.isEmpty) {
          throw Exception('Empty response for $url');
        }
      }

      if (!mounted) return;
      setState(() {
        _testingImages = false;
        _imagesValidated = true;
        _showImageTestSuccess = true;
        _imageValidationMessage = null;
        _previewImageUrls = sanitized;
      });
    } catch (error) {
      if (!mounted) return;
      final isDrive = sanitized.any((url) => url.contains('drive.google.com'));
      setState(() {
        _testingImages = false;
        _imagesValidated = false;
        _showImageTestSuccess = false;
        _imageValidationMessage = isDrive
            ? 'Could not load one or more images. For Google Drive, share as '
                '“Anyone with the link” (Viewer), then test again.'
            : 'Could not load one or more images. Check each URL is a public '
                'HTTPS image link and try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load image: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onImageHelpClick() {
    DialogManager.showAlertDialog(
      context: context,
      title: 'Adding images',
      content:
          'Provide web links to the image files you want (one URL per line).\n\n'
          'When providing specific/personal media files, upload them to Google Drive, '
          'change access to “Anyone with the link”, and paste that link here. '
          'Share links are converted to direct links when you tap Test images.\n\n'
          'Supported formats:\n'
          '• Direct HTTPS URLs to images\n'
          '• Google Drive public links\n'
          '• Any publicly accessible image URL\n\n'
          'Tip: Keep images reasonably small so they load quickly on mobile.',
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final imageSources = readImageSources();
    if (imageSources.isNotEmpty && !_imagesValidated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test the image URLs before saving.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final appContext = Provider.of<AppContext>(context, listen: false);
    if (!canEditSection(appContext.currentUser)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accessDeniedMessage())),
      );
      return;
    }

    if (!await prepareSave()) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final body = _editorKey.currentState?.getDocumentJson() ?? initialBody;
      final imageSources = readImageSources();
      // Persist sanitised Drive links (same as after a successful Test).
      final sanitisedText = imageSources.join('\n');
      if (_imagesController.text.trim() != sanitisedText) {
        _imagesController.removeListener(_onImagesTextChanged);
        _imagesController.text = sanitisedText;
        _imagesController.addListener(_onImagesTextChanged);
      }
      final displayOrder =
          int.tryParse(_displayOrderController.text.trim()) ?? 0;
      final now = DateTime.now();

      await persistSave(
        appContext: appContext,
        body: body,
        imageSources: imageSources,
        displayOrder: displayOrder,
        now: now,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _isSaved = true;
      });
      popRouteAfterAllowing(result: true);
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
    if (!canEditSection(appContext.currentUser)) {
      return;
    }

    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: 'Delete this content?',
      content: deleteConfirmContent,
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
      await persistDelete(appContext);

      if (!mounted) {
        return;
      }
      setState(() {
        _isSaved = true;
      });
      popRouteAfterAllowing(result: true);
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

  String generateDocumentId(final String source, final String prefix) {
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

  List<String> readImageSources() {
    return _parseImageSourcesText(_imagesController.text);
  }

  List<String> _parseImageSourcesText(final String text) {
    return text
        .split('\n')
        .map(NetworkImageHelper.sanitizeMediaUrl)
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  bool _stringListsEqual(final List<String> a, final List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
