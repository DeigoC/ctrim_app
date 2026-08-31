import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/info/church_info.dart';
import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/church_location.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../widgets/user_avatar.dart';
import '../personal/select_users_page.dart';
import 'edit_info_body_shared.dart';

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
  late final String _initialSummary;
  late final String _initialLocation;
  late final String _initialMapLink;
  late final String _initialAddress;
  late final List<String> _initialPastorUserIds;
  String? _selectedLocation;
  List<String> _pastorUserIds = const [];
  List<ChurchInfo> _allChurches = const [];

  @override
  bool get isEditing => widget.info != null;

  @override
  String get pageTitle =>
      widget.info == null ? 'Add Church Info' : 'Edit Church Info';

  @override
  String get bodyPlaceholder =>
      'Tap here to write about this church — history, location, '
      'meeting times, or anything visitors should know…';

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
  String get initialImagesValue =>
      (widget.info?.imageSources ?? const <String>[]).join('\n');

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
    _selectedLocation = _initialLocation.isEmpty ? null : _initialLocation;
    _pastorUserIds = List<String>.from(_initialPastorUserIds);
    _summaryController = TextEditingController(text: _initialSummary);
    _mapLinkController = TextEditingController(text: _initialMapLink);
    _addressController = TextEditingController(text: _initialAddress);
  }

  @override
  void disposeSectionControllers() {
    _summaryController.dispose();
    _mapLinkController.dispose();
    _addressController.dispose();
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
      ..._buildChurchHubFields(      ),
      ..._buildPastorFields(),
    ];
  }

  List<Widget> _buildPastorFields() {
    final theme = Theme.of(context);
    return [
      const SizedBox(height: 16),
      Text(
        'Pastors',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'People listed as pastors for this church.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _pickPastors,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Choose pastors'),
      ),
      ..._pastorUserIds.map(_buildPastorTile),
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
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue:
            names.contains(_selectedLocation) ? _selectedLocation : null,
        decoration: const InputDecoration(
          labelText: 'Location',
          helperText:
              'Each church must use a unique location from the catalogue.',
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
        decoration: const InputDecoration(
          labelText: 'Address',
          helperText: 'Optional street address shown on the church page.',
        ),
        minLines: 1,
        maxLines: 2,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _mapLinkController,
        decoration: InputDecoration(
          labelText: 'Maps URL',
          helperText: 'Optional Google Maps (or similar) link.',
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
    final church = ChurchInfo(
      id: existingChurch?.id ??
          generateDocumentId(primaryController.text, 'church'),
      title: primaryController.text.trim(),
      analyticsTitle: primaryController.text.trim(),
      body: body,
      imageSources: imageSources,
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
