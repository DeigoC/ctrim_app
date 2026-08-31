import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/info/church_info.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/church_location.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../widgets/information/info_section_card.dart';
import '../../widgets/paired_row_list.dart';
import '../../widgets/user_avatar.dart';
import '../personal/select_users_page.dart';
import 'edit_info_body_shared.dart';

class _ImageUrlTestUiState {
  bool validated = true;
  bool testing = false;
  bool showSuccess = false;
  String? errorMessage;
  List<String> previewUrls = const [];
}

class EditChurchInfoBody extends StatefulWidget {
  const EditChurchInfoBody({super.key, this.info});

  final ChurchInfo? info;

  @override
  State<EditChurchInfoBody> createState() => _EditChurchInfoBodyState();
}

class _EditChurchInfoBodyState extends State<EditChurchInfoBody>
    with EditInfoBodyEditorMixin<EditChurchInfoBody> {
  late final TextEditingController _summaryController;
  late final TextEditingController _mapLinkController;
  late final TextEditingController _addressController;
  late final TextEditingController _heroImageController;
  late final TextEditingController _pastorsImageController;
  late final TextEditingController _galleryImagesController;
  late final String _initialSummary;
  late final String _initialLocation;
  late final String _initialMapLink;
  late final String _initialAddress;
  late final String _initialHeroImage;
  late final String _initialPastorsImage;
  late final String _initialGalleryImages;
  late final List<String> _initialPastorUserIds;
  String? _selectedLocation;
  List<String> _pastorUserIds = const [];
  List<ChurchInfo> _allChurches = const [];
  final _heroImageTest = _ImageUrlTestUiState();
  final _pastorsImageTest = _ImageUrlTestUiState();
  final _galleryImagesTest = _ImageUrlTestUiState();

  @override
  bool get usesDefaultImageUrlField => false;

  @override
  double get formMaxWidth => ResponsiveLayout.tabletContentMaxWidth;

  @override
  bool get isEditing => widget.info != null;

  @override
  String get pageTitle =>
      widget.info == null ? 'Add Church Info' : 'Edit Church Info';

  @override
  String get bodyPlaceholder =>
      'Tap here to write about the pastors — who they are, '
      'how they serve, or anything visitors should know…';

  @override
  String get primaryLabel => 'Church title';

  @override
  String get deleteConfirmContent =>
      'This also deletes extra pages added for this church. This cannot be undone.';

  @override
  List<dynamic> get resolveInitialBody => List<dynamic>.from(
      widget.info?.body ?? EditInfoBodyEditorMixin.emptyBody);

  @override
  String get initialPrimaryValue => widget.info?.title ?? '';

  @override
  String get initialImagesValue => '';

  @override
  String get initialDisplayOrderValue =>
      (widget.info?.displayOrder ?? 0).toString();

  @override
  void initSectionControllers() {
    _initialSummary = widget.info?.summary ?? '';
    _initialLocation = widget.info?.location.trim() ?? '';
    _initialMapLink = widget.info?.mapLink ?? '';
    _initialAddress = widget.info?.address ?? '';
    _initialPastorUserIds =
        List<String>.from(widget.info?.pastorUserIds ?? const []);
    _initialHeroImage = widget.info?.heroImageSrc ?? '';
    _initialPastorsImage = widget.info?.pastorsImageSrc ?? '';
    _initialGalleryImages =
        (widget.info?.galleryImageSources ?? const <String>[]).join('\n');
    _selectedLocation = _initialLocation.isEmpty ? null : _initialLocation;
    _pastorUserIds = List<String>.from(_initialPastorUserIds);
    _summaryController = TextEditingController(text: _initialSummary);
    _mapLinkController = TextEditingController(text: _initialMapLink);
    _addressController = TextEditingController(text: _initialAddress);
    _heroImageController = TextEditingController(text: _initialHeroImage);
    _pastorsImageController = TextEditingController(text: _initialPastorsImage);
    _galleryImagesController =
        TextEditingController(text: _initialGalleryImages);
    _heroImageController.addListener(_onHeroImageChanged);
    _pastorsImageController.addListener(_onPastorsImageChanged);
    _galleryImagesController.addListener(_onGalleryImagesChanged);
  }

  void _onHeroImageChanged() {
    _resetImageTestIfUrlChanged(
      controller: _heroImageController,
      initialValue: _initialHeroImage,
      testState: _heroImageTest,
    );
  }

  void _onPastorsImageChanged() {
    _resetImageTestIfUrlChanged(
      controller: _pastorsImageController,
      initialValue: _initialPastorsImage,
      testState: _pastorsImageTest,
    );
  }

  void _onGalleryImagesChanged() {
    final current = _readGalleryImageSources();
    final initial = parseImageSourcesText(_initialGalleryImages);
    if (listEquals(current, initial)) {
      setState(() {
        _galleryImagesTest.validated = true;
        _galleryImagesTest.errorMessage = null;
        _galleryImagesTest.showSuccess = false;
      });
      return;
    }
    setState(() {
      _galleryImagesTest.validated = false;
      _galleryImagesTest.errorMessage = null;
      _galleryImagesTest.showSuccess = false;
      if (current.isEmpty) {
        _galleryImagesTest.previewUrls = const [];
      }
    });
  }

  void _resetImageTestIfUrlChanged({
    required final TextEditingController controller,
    required final String initialValue,
    required final _ImageUrlTestUiState testState,
  }) {
    if (controller.text.trim() == initialValue.trim()) {
      setState(() {
        testState.validated = true;
        testState.errorMessage = null;
        testState.showSuccess = false;
      });
      return;
    }
    setState(() {
      testState.validated = false;
      testState.errorMessage = null;
      testState.showSuccess = false;
      if (controller.text.trim().isEmpty) {
        testState.previewUrls = const [];
      }
    });
  }

  List<String> _readGalleryImageSources() {
    return parseImageSourcesText(_galleryImagesController.text);
  }

  List<String> _readHeroImageSources() {
    final hero = parseImageSourcesText(_heroImageController.text);
    return hero.isEmpty ? const <String>[] : <String>[hero.first];
  }

  List<String> _readPastorsImageSources() {
    final pastors = parseImageSourcesText(_pastorsImageController.text);
    return pastors.isEmpty ? const <String>[] : <String>[pastors.first];
  }

  @override
  void disposeSectionControllers() {
    _heroImageController.removeListener(_onHeroImageChanged);
    _pastorsImageController.removeListener(_onPastorsImageChanged);
    _galleryImagesController.removeListener(_onGalleryImagesChanged);
    _summaryController.dispose();
    _mapLinkController.dispose();
    _addressController.dispose();
    _heroImageController.dispose();
    _pastorsImageController.dispose();
    _galleryImagesController.dispose();
  }

  @override
  bool customImagesReadyForSave() {
    final hero = _readHeroImageSources();
    final pastors = _readPastorsImageSources();
    final gallery = _readGalleryImageSources();
    final heroReady = hero.isEmpty || _heroImageTest.validated;
    final pastorsReady = pastors.isEmpty || _pastorsImageTest.validated;
    final galleryReady = gallery.isEmpty || _galleryImagesTest.validated;
    return heroReady && pastorsReady && galleryReady;
  }

  @override
  bool hasCustomImageChanges() {
    if (_heroImageController.text.trim() != _initialHeroImage.trim()) {
      return true;
    }
    if (_pastorsImageController.text.trim() != _initialPastorsImage.trim()) {
      return true;
    }
    if (_galleryImagesController.text.trim() != _initialGalleryImages.trim()) {
      return true;
    }
    return false;
  }

  @override
  List<Widget> buildFormLayout() {
    final l10n = AppLocalizations.of(context)!;
    final churchCard = _editorCard(
      icon: Icons.church_outlined,
      title: l10n.churchEditorChurchCardTitle,
      subtitle: l10n.churchEditorChurchCardSubtitle,
      children: _buildIdentityFields(),
    );
    final visitCard = _editorCard(
      icon: Icons.place_outlined,
      title: l10n.churchEditorVisitCardTitle,
      subtitle: l10n.churchEditorVisitCardSubtitle,
      children: _buildChurchHubFields(),
    );
    final pastorsCard = _editorCard(
      icon: Icons.groups_outlined,
      title: l10n.churchEditorPastorsCardTitle,
      subtitle: l10n.churchEditorPastorsCardSubtitle,
      children: _buildPastorFields(),
    );
    final mediaCard = _editorCard(
      icon: Icons.photo_library_outlined,
      title: l10n.churchEditorMediaCardTitle,
      subtitle: l10n.churchEditorMediaCardSubtitle,
      children: _buildMediaFields(),
    );

    final bool wide = ResponsiveLayout.isWideScreenOf(context);
    return [
      if (wide)
        PairedRowList(
          itemCount: 2,
          itemBuilder: (_, index) => index == 0 ? churchCard : visitCard,
        )
      else ...[
        churchCard,
        const SizedBox(height: 16),
        visitCard,
      ],
      const SizedBox(height: 16),
      pastorsCard,
      const SizedBox(height: 16),
      mediaCard,
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: isFormBusy || !imagesReadyForSave()
              ? null
              : () {
                  submitSave();
                },
          child: isFormSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.churchEditorSave),
        ),
      ),
    ];
  }

  Widget _editorCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return InfoSectionCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  InputDecoration _filledDecoration({
    required String label,
    String? helperText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: colorScheme.onSurfaceVariant),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    );
  }

  @override
  List<Widget> buildCustomImageFields() => _buildMediaFields();

  @override
  List<Widget> buildSectionMetadataFields() => const [];

  List<Widget> _buildIdentityFields() {
    return [
      TextFormField(
        controller: primaryController,
        decoration: _filledDecoration(
          label: primaryLabel,
          prefixIcon: Icons.title_outlined,
        ),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _summaryController,
        decoration: _filledDecoration(
          label: 'Summary / subtitle',
          prefixIcon: Icons.short_text,
        ),
        minLines: 2,
        maxLines: 3,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: displayOrderController,
        decoration: _filledDecoration(
          label: 'Display order',
          prefixIcon: Icons.format_list_numbered,
        ),
        keyboardType: TextInputType.number,
      ),
    ];
  }

  List<Widget> _buildMediaFields() {
    return [
      _buildSingleImageField(
        controller: _heroImageController,
        label: 'Hero image URL',
        helperText:
            'Shown on the church list and as the wide cover on the church page.',
        prefixIcon: Icons.image_outlined,
        testState: _heroImageTest,
        onTest: _testHeroImage,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _galleryImagesController,
        decoration: _filledDecoration(
          label: 'Gallery image URLs',
          helperText:
              'One URL per line. Gallery photos only — not the hero image.',
          prefixIcon: Icons.collections_outlined,
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
          onPressed: _galleryImagesTest.testing ||
                  _galleryImagesController.text.trim().isEmpty
              ? null
              : _testGalleryImages,
          icon: _galleryImagesTest.testing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.visibility_outlined),
          label: Text(_galleryImagesTest.testing ? 'Testing…' : 'Test gallery'),
        ),
      ),
      if (!_galleryImagesTest.validated &&
          _galleryImagesController.text.trim().isNotEmpty &&
          !_galleryImagesTest.testing &&
          !_galleryImagesTest.showSuccess &&
          _galleryImagesTest.errorMessage == null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Test these images before saving.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      if (_galleryImagesTest.previewUrls.isNotEmpty &&
          (_galleryImagesTest.testing ||
              _galleryImagesTest.showSuccess ||
              _galleryImagesTest.errorMessage != null)) ...[
        const SizedBox(height: 12),
        buildImageUrlTestFeedback(
          previewUrls: _galleryImagesTest.previewUrls,
          testing: _galleryImagesTest.testing,
          showSuccess: _galleryImagesTest.showSuccess,
          errorMessage: _galleryImagesTest.errorMessage,
        ),
      ],
    ];
  }

  Widget _buildSingleImageField({
    required TextEditingController controller,
    required String label,
    required String helperText,
    required _ImageUrlTestUiState testState,
    required Future<void> Function() onTest,
    IconData prefixIcon = Icons.link,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          decoration: _filledDecoration(
            label: label,
            helperText: helperText,
            prefixIcon: prefixIcon,
            suffixIcon: IconButton(
              onPressed: _onImageHelpClick,
              icon: const Icon(Icons.help_outline),
              tooltip: 'Image URL help',
            ),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: testState.testing || controller.text.trim().isEmpty
                ? null
                : onTest,
            icon: testState.testing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.visibility_outlined),
            label: Text(testState.testing ? 'Testing…' : 'Test image'),
          ),
        ),
        if (!testState.validated &&
            controller.text.trim().isNotEmpty &&
            !testState.testing &&
            !testState.showSuccess &&
            testState.errorMessage == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Test this image before saving.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        if (testState.previewUrls.isNotEmpty &&
            (testState.testing ||
                testState.showSuccess ||
                testState.errorMessage != null)) ...[
          const SizedBox(height: 12),
          buildImageUrlTestFeedback(
            previewUrls: testState.previewUrls,
            testing: testState.testing,
            showSuccess: testState.showSuccess,
            errorMessage: testState.errorMessage,
          ),
        ],
      ],
    );
  }

  void _onImageHelpClick() {
    DialogManager.showAlertDialog(
      context: context,
      title: 'Adding images',
      content: 'Provide web links to the image files you want.\n\n'
          'When providing specific/personal media files, upload them to Google Drive, '
          'change access to “Anyone with the link”, and paste that link here. '
          'Share links are converted to direct links when you tap Test.\n\n'
          'Supported formats:\n'
          '• Direct HTTPS URLs to images\n'
          '• Google Drive public links\n'
          '• Any publicly accessible image URL',
    );
  }

  Future<void> _testHeroImage() => _testSingleImageField(
        controller: _heroImageController,
        testState: _heroImageTest,
      );

  Future<void> _testPastorsImage() => _testSingleImageField(
        controller: _pastorsImageController,
        testState: _pastorsImageTest,
      );

  Future<void> _testGalleryImages() async {
    final urls = _readGalleryImageSources();
    if (urls.isEmpty) return;

    setState(() {
      _galleryImagesTest.testing = true;
      _galleryImagesTest.validated = false;
      _galleryImagesTest.showSuccess = false;
      _galleryImagesTest.errorMessage = null;
      _galleryImagesTest.previewUrls = urls;
    });

    final sanitizedText = urls.join('\n');
    if (_galleryImagesController.text.trim() != sanitizedText) {
      _galleryImagesController.text = sanitizedText;
    }

    final ok = await validateImageUrls(urls);
    if (!mounted) return;

    setState(() {
      _galleryImagesTest.testing = false;
      _galleryImagesTest.validated = ok;
      _galleryImagesTest.showSuccess = ok;
      _galleryImagesTest.errorMessage =
          ok ? null : imageUrlTestFailureMessage(urls);
      _galleryImagesTest.previewUrls = urls;
    });
  }

  Future<void> _testSingleImageField({
    required TextEditingController controller,
    required _ImageUrlTestUiState testState,
  }) async {
    final urls = parseImageSourcesText(controller.text);
    if (urls.isEmpty) return;

    setState(() {
      testState.testing = true;
      testState.validated = false;
      testState.showSuccess = false;
      testState.errorMessage = null;
      testState.previewUrls = <String>[urls.first];
    });

    final sanitized = urls.first;
    if (controller.text.trim() != sanitized) {
      controller.text = sanitized;
    }

    final ok = await validateImageUrls(<String>[sanitized]);
    if (!mounted) return;

    setState(() {
      testState.testing = false;
      testState.validated = ok;
      testState.showSuccess = ok;
      testState.errorMessage =
          ok ? null : imageUrlTestFailureMessage(<String>[sanitized]);
      testState.previewUrls = <String>[sanitized];
    });
  }

  @override
  void onAccessGranted() {
    infoRepository.fetchChurches().then((churches) {
      if (mounted) setState(() => _allChurches = churches);
    });
  }

  @override
  bool hasUnsavedChangesExtras() {
    if (_summaryController.text.trim() != _initialSummary.trim()) {
      return true;
    }
    if ((_selectedLocation ?? '') != _initialLocation) {
      return true;
    }
    if (_mapLinkController.text.trim() != _initialMapLink.trim()) {
      return true;
    }
    if (_addressController.text.trim() != _initialAddress.trim()) {
      return true;
    }
    if (!listEquals(_pastorUserIds, _initialPastorUserIds)) {
      return true;
    }
    return false;
  }

  List<Widget> _buildPastorFields() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return [
      OutlinedButton.icon(
        onPressed: _pickPastors,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Choose pastors'),
      ),
      ..._pastorUserIds.map(_buildPastorTile),
      const SizedBox(height: 12),
      _buildSingleImageField(
        controller: _pastorsImageController,
        label: 'Pastors image URL',
        helperText: 'Optional team photo shown in the pastors card.',
        prefixIcon: Icons.photo_outlined,
        testState: _pastorsImageTest,
        onTest: _testPastorsImage,
      ),
      const SizedBox(height: 16),
      Text(
        l10n.churchEditorPastorsBodyLabel,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      buildBodyEditor(),
    ];
  }

  Widget _buildPastorTile(final String userId) {
    final user = _userById(userId);
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: user != null
          ? MyUserAvatar(user, radius: 20)
          : CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      title: Text(user?.fullname ?? 'Unknown user'),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() => _pastorUserIds.remove(userId)),
      ),
    );
  }

  Future<void> _pickPastors() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: List<String>.from(_pastorUserIds),
          includeCurrentUser: true,
          title: 'Pastors',
          preferServing: true,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _pastorUserIds = result);
  }

  User? _userById(final String id) {
    final appContext = Provider.of<AppContext>(context, listen: false);
    return appContext.userById(id);
  }

  List<Widget> _buildChurchHubFields() {
    final appContext = Provider.of<AppContext>(context);
    final assignable = VolunteerLocations.assignableFrom(
      appContext.activeLocations,
    );
    final occupied = ChurchLocation.occupiedLocationNames(
      churches: _allChurches,
      excludingId: widget.info?.id,
    );
    final names = List<String>.from(assignable);
    if (_selectedLocation != null && !names.contains(_selectedLocation)) {
      names.insert(0, _selectedLocation!);
    }

    return [
      DropdownButtonFormField<String>(
        initialValue:
            names.contains(_selectedLocation) ? _selectedLocation : null,
        decoration: _filledDecoration(
          label: 'Location',
          helperText:
              'Each church must use a unique location from the catalogue.',
          prefixIcon: Icons.place_outlined,
        ),
        items: names.map(
          (name) {
            final taken = occupied.contains(name);
            return DropdownMenuItem<String>(
              value: name,
              enabled: !taken,
              child: Text(taken ? '$name (in use)' : name),
            );
          },
        ).toList(),
        onChanged: (value) => setState(() => _selectedLocation = value),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _addressController,
        decoration: _filledDecoration(
          label: 'Address',
          helperText: 'Optional street address shown on the church page.',
          prefixIcon: Icons.home_outlined,
        ),
        minLines: 1,
        maxLines: 2,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _mapLinkController,
        decoration: _filledDecoration(
          label: 'Maps URL',
          helperText: 'Optional Google Maps (or similar) link.',
          prefixIcon: Icons.map_outlined,
          suffixIcon: IconButton(
            onPressed: _onMapLinkHelpClick,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Maps URL help',
          ),
        ),
        keyboardType: TextInputType.url,
      ),
    ];
  }

  void _onMapLinkHelpClick() {
    DialogManager.showAlertDialog(
      context: context,
      icon: Icons.map_outlined,
      title: 'Maps URL',
      content: 'Help people find this church with a direct map link.\n\n'
          'How to get a Google Maps link:\n'
          '1. Go to Google Maps\n'
          '2. Search for the church address\n'
          '3. Tap Share and copy the link\n'
          '4. Paste it here',
    );
  }

  @override
  Future<bool> prepareSave() async {
    final location = (_selectedLocation ?? '').trim();
    var churches = _allChurches;
    if (churches.isEmpty) {
      churches = await infoRepository.fetchChurches();
      if (mounted) setState(() => _allChurches = churches);
    }
    if (!mounted) return false;
    final conflict = ChurchLocation.otherChurchUsingLocation(
      churches: churches,
      location: location,
      excludingId: widget.info?.id,
    );
    if (conflict != null) {
      await DialogManager.showAlertDialog(
        context: context,
        title: 'Location already used',
        content: 'Location “$location” is already used by ${conflict.title}. '
            'Each church must have its own location.',
        isError: true,
      );
      return false;
    }
    return true;
  }

  @override
  Future<void> persistSave({
    required final AppContext appContext,
    required final List<dynamic> body,
    required final List<String> imageSources,
    required final int displayOrder,
    required final DateTime now,
  }) async {
    final existingChurch = widget.info;
    final location = (_selectedLocation ?? '').trim();
    final heroUrls = _readHeroImageSources();
    final pastorsUrls = _readPastorsImageSources();
    final church = ChurchInfo(
      id: existingChurch?.id ??
          generateDocumentId(primaryController.text, 'church'),
      title: primaryController.text.trim(),
      analyticsTitle: primaryController.text.trim(),
      body: body,
      heroImageSrc: heroUrls.isNotEmpty ? heroUrls.first : '',
      pastorsImageSrc: pastorsUrls.isNotEmpty ? pastorsUrls.first : '',
      galleryImageSources: _readGalleryImageSources(),
      summary: _summaryController.text.trim(),
      location: location,
      mapLink: _mapLinkController.text.trim(),
      address: _addressController.text.trim(),
      pastorUserIds: List<String>.from(_pastorUserIds),
      updatedBy: appContext.currentUser.id,
      updatedAt: now,
      displayOrder: displayOrder,
    );
    await infoRepository.saveChurchInfo(church);
    await UserActivityRecorder().record(
      actorUserId: appContext.currentUser.id,
      log: existingChurch == null
          ? UserActivityMessages.createdChurchRecord
          : UserActivityMessages.editedChurchRecord,
      documentId: church.id,
    );
  }

  @override
  Future<void> persistDelete(final AppContext appContext) async {
    await infoRepository.deleteChurchInfo(widget.info!.id);
    await UserActivityRecorder().record(
      actorUserId: appContext.currentUser.id,
      log: UserActivityMessages.deletedChurchRecord,
      documentId: widget.info!.id,
    );
  }
}
