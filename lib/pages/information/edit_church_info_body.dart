import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/info/church_info.dart';
import '../../models/info/church_social.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/church_hierarchy.dart';
import '../../utility/church_location.dart';
import '../../utility/church_social_ui.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../widgets/information/info_section_card.dart';
import '../../widgets/two_column_masonry.dart';
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
  const EditChurchInfoBody({super.key, this.info, this.parentChurchId});

  final ChurchInfo? info;

  /// When creating under a parent hub, starts as an outreach of this church.
  final String? parentChurchId;

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
  late final List<ChurchSocialLink> _initialSocials;
  late final ChurchKind _initialKind;
  late final String _initialParentChurchId;
  String? _selectedLocation;
  List<String> _pastorUserIds = const [];
  List<ChurchSocialLink> _socials = const [];
  List<ChurchInfo> _allChurches = const [];
  late ChurchKind _kind;
  String? _parentChurchId;
  final _heroImageTest = _ImageUrlTestUiState();
  final _pastorsImageTest = _ImageUrlTestUiState();
  final _galleryImagesTest = _ImageUrlTestUiState();

  bool get _isOutreach => _kind == ChurchKind.outreach;

  @override
  bool get usesDefaultImageUrlField => false;

  @override
  double get formMaxWidth => ResponsiveLayout.tabletContentMaxWidth;

  @override
  bool get isEditing => widget.info != null;

  @override
  String get pageTitle {
    if (widget.info == null) {
      return _isOutreach ? 'Add Outreach' : 'Add Church Info';
    }
    return _isOutreach ? 'Edit Outreach' : 'Edit Church Info';
  }

  @override
  String get bodyPlaceholder => _isOutreach
      ? 'Tap here to write about the church planters — who they are, '
          'how they serve, or anything visitors should know…'
      : 'Tap here to write about the pastors — who they are, '
          'how they serve, or anything visitors should know…';

  @override
  String get primaryLabel => _isOutreach ? 'Outreach title' : 'Church title';

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
    final creatingOutreach =
        widget.info == null && (widget.parentChurchId ?? '').trim().isNotEmpty;
    _initialKind = widget.info?.kind ??
        (creatingOutreach ? ChurchKind.outreach : ChurchKind.church);
    _initialParentChurchId = widget.info?.parentChurchId.trim() ??
        (creatingOutreach ? widget.parentChurchId!.trim() : '');
    _kind = _initialKind;
    _parentChurchId =
        _initialParentChurchId.isEmpty ? null : _initialParentChurchId;
    _initialSummary = widget.info?.summary ?? '';
    _initialLocation = widget.info?.location.trim() ?? '';
    _initialMapLink = widget.info?.mapLink ?? '';
    _initialAddress = widget.info?.address ?? '';
    _initialPastorUserIds =
        List<String>.from(widget.info?.pastorUserIds ?? const []);
    _initialSocials = List<ChurchSocialLink>.from(
      widget.info?.socials ?? const <ChurchSocialLink>[],
    );
    _initialHeroImage = widget.info?.heroImageSrc ?? '';
    _initialPastorsImage = widget.info?.pastorsImageSrc ?? '';
    _initialGalleryImages =
        (widget.info?.galleryImageSources ?? const <String>[]).join('\n');
    _selectedLocation = _initialLocation.isEmpty ? null : _initialLocation;
    _pastorUserIds = List<String>.from(_initialPastorUserIds);
    _socials = List<ChurchSocialLink>.from(_initialSocials);
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
      title: _isOutreach
          ? l10n.churchEditorOutreachCardTitle
          : l10n.churchEditorChurchCardTitle,
      subtitle: _isOutreach
          ? l10n.churchEditorOutreachCardSubtitle
          : l10n.churchEditorChurchCardSubtitle,
      children: _buildIdentityFields(),
    );
    final statusCard = _editorCard(
      icon: Icons.account_tree_outlined,
      title: l10n.churchEditorStatusCardTitle,
      subtitle: l10n.churchEditorStatusCardSubtitle,
      children: _buildStatusFields(),
    );
    final visitCard = _editorCard(
      icon: Icons.place_outlined,
      title: l10n.churchEditorVisitCardTitle,
      subtitle: l10n.churchEditorVisitCardSubtitle,
      children: _buildChurchHubFields(),
    );
    final socialsCard = _editorCard(
      icon: Icons.share_outlined,
      title: l10n.churchEditorSocialsCardTitle,
      subtitle: l10n.churchEditorSocialsCardSubtitle,
      children: _buildSocialsFields(),
    );
    final pastorsCard = _editorCard(
      icon: Icons.groups_outlined,
      title: _isOutreach
          ? l10n.churchEditorPlantersCardTitle
          : l10n.churchEditorPastorsCardTitle,
      subtitle: _isOutreach
          ? l10n.churchEditorPlantersCardSubtitle
          : l10n.churchEditorPastorsCardSubtitle,
      children: _buildPastorFields(),
    );
    final mediaCard = _editorCard(
      icon: Icons.photo_library_outlined,
      title: l10n.churchEditorMediaCardTitle,
      subtitle: l10n.churchEditorMediaCardSubtitle,
      children: _buildMediaFields(),
    );

    final cards = <Widget>[
      churchCard,
      statusCard,
      visitCard,
      socialsCard,
      pastorsCard,
      mediaCard,
    ];
    final bool wide = ResponsiveLayout.isWideScreenOf(context);
    return [
      if (wide)
        TwoColumnMasonry(children: cards)
      else ...[
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          cards[i],
        ],
      ],
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
    if (_kind != _initialKind) return true;
    if ((_parentChurchId ?? '') != _initialParentChurchId) return true;
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
    if (!_sameSocials(_socials, _initialSocials)) {
      return true;
    }
    return false;
  }

  bool _sameSocials(
    final List<ChurchSocialLink> a,
    final List<ChurchSocialLink> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].platform != b[i].platform || a[i].url != b[i].url) {
        return false;
      }
    }
    return true;
  }

  List<Widget> _buildSocialsFields() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final used = _socials
        .map((s) => s.platform)
        .where((p) => p != ChurchSocialPlatform.other)
        .toSet();
    final canAddMore = ChurchSocialPlatform.editableOrder.any(
      (p) => p == ChurchSocialPlatform.other || !used.contains(p),
    );

    return [
      if (_socials.isEmpty)
        Text(
          l10n.churchEditorSocialsEmptyHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      for (var i = 0; i < _socials.length; i++) ...[
        if (i > 0) const SizedBox(height: 12),
        _buildSocialRow(index: i),
      ],
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: canAddMore ? _addSocialLink : null,
        icon: const Icon(Icons.add),
        label: Text(l10n.churchEditorAddSocial),
      ),
    ];
  }

  Widget _buildSocialRow({required int index}) {
    final l10n = AppLocalizations.of(context)!;
    final link = _socials[index];
    final usedElsewhere = _socials
        .asMap()
        .entries
        .where((e) => e.key != index)
        .map((e) => e.value.platform)
        .where((p) => p != ChurchSocialPlatform.other)
        .toSet();
    final platforms = ChurchSocialPlatform.editableOrder
        .where(
          (p) =>
              p == ChurchSocialPlatform.other ||
              p == link.platform ||
              !usedElsewhere.contains(p),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<ChurchSocialPlatform>(
                initialValue: platforms.contains(link.platform)
                    ? link.platform
                    : platforms.first,
                decoration: _filledDecoration(
                  label: l10n.churchEditorSocialPlatformLabel,
                  prefixIcon: ChurchSocialUi.iconFor(link.platform),
                ),
                items: platforms
                    .map(
                      (platform) => DropdownMenuItem(
                        value: platform,
                        child: Text(ChurchSocialUi.labelFor(l10n, platform)),
                      ),
                    )
                    .toList(),
                onChanged: (platform) {
                  if (platform == null) return;
                  setState(() {
                    _socials = List<ChurchSocialLink>.from(_socials);
                    _socials[index] = ChurchSocialLink(
                      platform: platform,
                      url: link.url,
                    );
                  });
                },
              ),
            ),
            IconButton(
              tooltip: l10n.churchEditorRemoveSocial,
              onPressed: () {
                setState(() {
                  _socials = List<ChurchSocialLink>.from(_socials)
                    ..removeAt(index);
                });
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: link.url,
          key: ValueKey('social-url-${link.platform}-$index'),
          decoration: _filledDecoration(
            label: l10n.churchEditorSocialUrlLabel,
            helperText: l10n.churchEditorSocialUrlHelper,
            prefixIcon: Icons.link,
          ),
          keyboardType: TextInputType.url,
          onChanged: (value) {
            _socials = List<ChurchSocialLink>.from(_socials);
            _socials[index] = ChurchSocialLink(
              platform: link.platform,
              url: value.trim(),
            );
          },
        ),
      ],
    );
  }

  void _addSocialLink() {
    final used = _socials
        .map((s) => s.platform)
        .where((p) => p != ChurchSocialPlatform.other)
        .toSet();
    final next = ChurchSocialPlatform.editableOrder.firstWhere(
      (p) => p == ChurchSocialPlatform.other || !used.contains(p),
      orElse: () => ChurchSocialPlatform.other,
    );
    setState(() {
      _socials = [
        ..._socials,
        ChurchSocialLink(platform: next, url: ''),
      ];
    });
  }

  List<Widget> _buildStatusFields() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final parents = ChurchHierarchy.eligibleParents(
      churches: _allChurches,
      excludingId: widget.info?.id,
    );

    return [
      Text(
        _isOutreach
            ? l10n.churchEditorKindOutreach
            : l10n.churchEditorKindChurch,
        style:
            theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 4),
      Text(
        _isOutreach
            ? l10n.churchEditorKindOutreachHint
            : l10n.churchEditorKindChurchHint,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      if (_isOutreach) ...[
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: parents.any((p) => p.id == _parentChurchId)
              ? _parentChurchId
              : null,
          decoration: _filledDecoration(
            label: l10n.churchEditorParentChurchLabel,
            helperText: l10n.churchEditorParentChurchHelper,
            prefixIcon: Icons.church_outlined,
          ),
          items: parents
              .map(
                (parent) => DropdownMenuItem<String>(
                  value: parent.id,
                  child: Text(parent.title),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _parentChurchId = value),
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Required' : null,
        ),
        if (isEditing) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _promoteToChurch,
            icon: const Icon(Icons.upgrade_outlined),
            label: Text(l10n.churchEditorPromoteToChurch),
          ),
        ],
      ] else if (isEditing) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _demoteToOutreach,
          icon: const Icon(Icons.subdirectory_arrow_right),
          label: Text(l10n.churchEditorDemoteToOutreach),
        ),
      ],
    ];
  }

  Future<void> _promoteToChurch() async {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.info;
    if (draft == null) return;
    final block = ChurchHierarchy.promoteBlockReason(draft);
    if (block != null) {
      await DialogManager.showAlertDialog(
        context: context,
        title: l10n.churchEditorPromoteBlockedTitle,
        content: block,
        isError: true,
      );
      return;
    }
    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: l10n.churchEditorPromoteConfirmTitle,
      content: l10n.churchEditorPromoteConfirmBody,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _kind = ChurchKind.church;
      _parentChurchId = null;
    });
  }

  Future<void> _demoteToOutreach() async {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.info;
    if (draft == null) return;
    final block = ChurchHierarchy.demoteBlockReason(
      church: draft,
      churches: _allChurches,
    );
    if (block != null) {
      await DialogManager.showAlertDialog(
        context: context,
        title: l10n.churchEditorDemoteBlockedTitle,
        content: block,
        isError: true,
      );
      return;
    }
    final parents = ChurchHierarchy.eligibleParents(
      churches: _allChurches,
      excludingId: draft.id,
    );
    if (parents.isEmpty) {
      await DialogManager.showAlertDialog(
        context: context,
        title: l10n.churchEditorDemoteBlockedTitle,
        content: l10n.churchEditorDemoteNoParent,
        isError: true,
      );
      return;
    }
    String? selectedParentId = parents.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.churchEditorDemoteConfirmTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.churchEditorDemoteConfirmBody),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedParentId,
                    decoration: InputDecoration(
                      labelText: l10n.churchEditorParentChurchLabel,
                    ),
                    items: parents
                        .map(
                          (parent) => DropdownMenuItem<String>(
                            value: parent.id,
                            child: Text(parent.title),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedParentId = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.churchEditorCancel),
                ),
                FilledButton(
                  onPressed: selectedParentId == null
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: Text(l10n.churchEditorDemoteToOutreach),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || selectedParentId == null || !mounted) return;
    setState(() {
      _kind = ChurchKind.outreach;
      _parentChurchId = selectedParentId;
      _selectedLocation = null;
    });
  }

  List<Widget> _buildPastorFields() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return [
      OutlinedButton.icon(
        onPressed: _pickPastors,
        icon: const Icon(Icons.person_add_alt),
        label: Text(
          _isOutreach
              ? l10n.churchEditorChoosePlanters
              : l10n.churchEditorChoosePastors,
        ),
      ),
      ..._pastorUserIds.map(_buildPastorTile),
      const SizedBox(height: 12),
      _buildSingleImageField(
        controller: _pastorsImageController,
        label: _isOutreach
            ? l10n.churchEditorPlantersImageLabel
            : l10n.churchEditorPastorsImageLabel,
        helperText: _isOutreach
            ? l10n.churchEditorPlantersImageHelper
            : l10n.churchEditorPastorsImageHelper,
        prefixIcon: Icons.photo_outlined,
        testState: _pastorsImageTest,
        onTest: _testPastorsImage,
      ),
      const SizedBox(height: 16),
      Text(
        _isOutreach
            ? l10n.churchEditorPlantersBodyLabel
            : l10n.churchEditorPastorsBodyLabel,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        _isOutreach
            ? l10n.churchEditorPlantersBodyHelper
            : l10n.churchEditorPastorsBodyHelper,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
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
    final l10n = AppLocalizations.of(context)!;
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: List<String>.from(_pastorUserIds),
          includeCurrentUser: true,
          title: _isOutreach
              ? l10n.churchEditorChoosePlanters
              : l10n.churchEditorChoosePastors,
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
    final l10n = AppLocalizations.of(context)!;
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
      if (!_isOutreach)
        DropdownButtonFormField<String>(
          initialValue:
              names.contains(_selectedLocation) ? _selectedLocation : null,
          decoration: _filledDecoration(
            label: l10n.churchEditorLocationLabel,
            helperText: l10n.churchEditorLocationHelper,
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
        )
      else
        Text(
          l10n.churchEditorOutreachLocationHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _addressController,
        decoration: _filledDecoration(
          label: l10n.churchEditorAddressLabel,
          helperText: l10n.churchEditorAddressHelper,
          prefixIcon: Icons.home_outlined,
        ),
        minLines: 1,
        maxLines: 2,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _mapLinkController,
        decoration: _filledDecoration(
          label: l10n.churchEditorMapsLabel,
          helperText: l10n.churchEditorMapsHelper,
          prefixIcon: Icons.map_outlined,
          suffixIcon: IconButton(
            onPressed: _onMapLinkHelpClick,
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.churchEditorMapsHelpTooltip,
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
    final l10n = AppLocalizations.of(context)!;
    final location = _isOutreach ? '' : (_selectedLocation ?? '').trim();
    var churches = _allChurches;
    if (churches.isEmpty) {
      churches = await infoRepository.fetchChurches();
      if (mounted) setState(() => _allChurches = churches);
    }
    if (!mounted) return false;

    final draft = ChurchInfo(
      id: widget.info?.id ?? 'draft',
      title: primaryController.text.trim(),
      analyticsTitle: primaryController.text.trim(),
      body: const [
        {'insert': '\n'}
      ],
      kind: _kind,
      parentChurchId: _isOutreach ? (_parentChurchId ?? '') : '',
      location: location,
    );
    final hierarchyError = ChurchHierarchy.validateForSave(
      draft: draft,
      churches: churches,
    );
    if (hierarchyError != null) {
      await DialogManager.showAlertDialog(
        context: context,
        title: l10n.churchEditorValidationTitle,
        content: hierarchyError,
        isError: true,
      );
      return false;
    }

    if (!_isOutreach) {
      final conflict = ChurchLocation.otherChurchUsingLocation(
        churches: churches,
        location: location,
        excludingId: widget.info?.id,
      );
      if (conflict != null) {
        await DialogManager.showAlertDialog(
          context: context,
          title: l10n.churchEditorLocationConflictTitle,
          content: l10n.churchEditorLocationConflictBody(
            location,
            conflict.title,
          ),
          isError: true,
        );
        return false;
      }
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
    final location = _isOutreach ? '' : (_selectedLocation ?? '').trim();
    final heroUrls = _readHeroImageSources();
    final pastorsUrls = _readPastorsImageSources();
    final church = ChurchInfo(
      id: existingChurch?.id ??
          generateDocumentId(primaryController.text, 'church'),
      title: primaryController.text.trim(),
      analyticsTitle: primaryController.text.trim(),
      body: body,
      kind: _kind,
      parentChurchId: _isOutreach ? (_parentChurchId ?? '') : '',
      heroImageSrc: heroUrls.isNotEmpty ? heroUrls.first : '',
      pastorsImageSrc: pastorsUrls.isNotEmpty ? pastorsUrls.first : '',
      galleryImageSources: _readGalleryImageSources(),
      summary: _summaryController.text.trim(),
      location: location,
      mapLink: _mapLinkController.text.trim(),
      address: _addressController.text.trim(),
      pastorUserIds: List<String>.from(_pastorUserIds),
      socials: _socials
          .map(
            (link) => ChurchSocialLink(
              platform: link.platform,
              url: ChurchSocialUi.normalizeUrl(link.platform, link.url),
            ),
          )
          .where((link) => link.isValid)
          .toList(),
      updatedBy: appContext.currentUser.id,
      updatedAt: now,
      displayOrder: displayOrder,
    );
    await infoRepository.saveChurchInfo(church);

    String log = existingChurch == null
        ? (_isOutreach
            ? UserActivityMessages.createdOutreachRecord
            : UserActivityMessages.createdChurchRecord)
        : UserActivityMessages.editedChurchRecord;
    if (existingChurch != null && _kind != _initialKind) {
      log = _isOutreach
          ? UserActivityMessages.demotedChurchToOutreach
          : UserActivityMessages.promotedOutreachToChurch;
    }
    await UserActivityRecorder().record(
      actorUserId: appContext.currentUser.id,
      log: log,
      documentId: church.id,
    );
  }

  @override
  Future<void> persistDelete(final AppContext appContext) async {
    final l10n = AppLocalizations.of(context)!;
    final id = widget.info!.id;
    if (ChurchHierarchy.hasOutreaches(_allChurches, id)) {
      throw Exception(l10n.churchEditorDeleteBlockedBody);
    }
    await infoRepository.deleteChurchInfo(id);
    await UserActivityRecorder().record(
      actorUserId: appContext.currentUser.id,
      log: UserActivityMessages.deletedChurchRecord,
      documentId: id,
    );
  }
}
