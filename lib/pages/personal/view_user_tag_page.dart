import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/db_managers/user_tag_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/event/event_program.dart';
import '../../models/user.dart';
import '../../models/user_location.dart';
import '../../models/user_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/app_links.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/team_rota.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../utility/user_tag_schedule.dart';
import '../../widgets/catalog/colored_chip.dart';
import '../../widgets/catalog/user_tag_chip.dart';
import '../../widgets/catalog/user_tag_graphic.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/information/info_section_card.dart';
import '../../widgets/media/cached_image_widget.dart';
import '../../widgets/my_avatar_stack.dart';
import '../../widgets/paired_row_list.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/user_avatar.dart';
import '../events/add_media_file_page.dart';
import '../information/church_pastors_page.dart';
import 'select_users_page.dart';

/// Public detail for one team tag.
///
/// Heads, photos, members, and schedule roles follow the selected church
/// location. The main graphic and short description stay on the tag itself.
class ViewUserTagPage extends StatefulWidget {
  const ViewUserTagPage({
    super.key,
    required this.tagId,
    this.onEdit,
  });

  final String tagId;

  /// Area-admin edit of the catalogue fields. Omitted for guests and other readers.
  final VoidCallback? onEdit;

  @override
  State<ViewUserTagPage> createState() => _ViewUserTagPageState();
}

class _ViewUserTagPageState extends State<ViewUserTagPage> {
  static const int _horizonMonths = UserTagScheduleQuery.horizonMonths;
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  late final AppContext _appContext;
  final EventHeadDBManager _headsDb = EventHeadDBManager();
  final UserTagDBManager _tagDb = UserTagDBManager();

  String? _locationId;
  List<EventHead> _rangeHeads = [];
  final Map<String, EventProgram?> _programs = {};

  bool _scheduleLoading = true;
  bool _programsLoading = false;
  bool _saving = false;
  Object? _scheduleError;
  String _statusMessage = '';
  int _completedSteps = 0;
  int _totalSteps = 2;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _appContext = Provider.of<AppContext>(context, listen: false);
    _locationId = _defaultLocationId(_appContext);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSchedule();
    });
  }

  String? _defaultLocationId(AppContext appContext) {
    final active = _activeLocations(appContext);
    if (active.isEmpty) return null;
    final name = VolunteerLocations.defaultFilterForUser(
      appContext.currentUser.location,
      active.map((location) => location.name).toList(),
    );
    for (final location in active) {
      if (location.name == name) return location.id;
    }
    return active.first.id;
  }

  List<UserLocation> _activeLocations(AppContext appContext) {
    return appContext.allLocations
        .where((location) => location.isActive)
        .toList();
  }

  UserLocation? _selectedLocation(List<UserLocation> active) {
    for (final location in active) {
      if (location.id == _locationId) return location;
    }
    return active.isEmpty ? null : active.first;
  }

  Future<void> _loadSchedule() async {
    final generation = ++_loadGeneration;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _scheduleLoading = true;
      _programsLoading = false;
      _scheduleError = null;
      _completedSteps = 0;
      _totalSteps = 2;
      _statusMessage = l10n.userTagDetailScheduleLoading;
    });

    try {
      final now = DateTime.now();
      final heads = await _headsDb.fetchHeadsWithEventDateInRange(
        startInclusive: UserTagScheduleQuery.rangeStartInclusive(now),
        endExclusive: UserTagScheduleQuery.rangeEndExclusive(now),
      );
      if (!mounted || generation != _loadGeneration) return;

      setState(() {
        _rangeHeads = heads;
        _programs.clear();
        _completedSteps = 1;
        _statusMessage = l10n.userTagDetailScheduleLoadingProgrammes;
      });

      await _ensureProgramsForLocation();
      if (!mounted || generation != _loadGeneration) return;
      // The chip can change while the first batch is in flight.
      await _ensureProgramsForLocation();
      if (!mounted || generation != _loadGeneration) return;

      setState(() {
        _scheduleLoading = false;
        _completedSteps = 2;
      });
    } catch (e, st) {
      debugPrint('Could not load team tag schedule: $e\n$st');
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _scheduleLoading = false;
        _scheduleError = e;
      });
    }
  }

  Future<void> _ensureProgramsForLocation() async {
    final locationName = _selectedLocation(_activeLocations(_appContext))?.name;
    if (locationName == null) return;

    final needed = _rangeHeads.where((head) {
      if (!TeamRotaQuery.headMatchesLocation(
        head: head,
        locationFilter: locationName,
      )) {
        return false;
      }
      return !_programs.containsKey(head.id);
    }).toList();
    if (needed.isEmpty) return;

    final fetched = await Future.wait(
      needed.map(
        (head) => EventSupplementalDBManager(head.id).fetchProgramIfExists(),
      ),
    );
    for (var i = 0; i < needed.length; i++) {
      _programs[needed[i].id] = fetched[i];
    }
  }

  Future<void> _onLocationSelected(UserLocation location) async {
    if (_locationId == location.id) return;
    setState(() => _locationId = location.id);
    if (_scheduleLoading) return;

    setState(() => _programsLoading = true);
    try {
      await _ensureProgramsForLocation();
      if (!mounted) return;
      setState(() => _programsLoading = false);
    } catch (e, st) {
      debugPrint('Could not load programmes for ${location.name}: $e\n$st');
      if (!mounted) return;
      setState(() {
        _programsLoading = false;
        _scheduleError = e;
      });
    }
  }

  ({List<TeamRotaPost> upcoming, List<TeamRotaPost> past}) _scheduleFor(
    UserTag tag,
    String locationName,
    bool guestsOnly,
  ) {
    final posts = <({EventHead head, EventProgram program})>[];
    for (final head in _rangeHeads) {
      final program = _programs[head.id];
      if (program == null) continue;
      posts.add((head: head, program: program));
    }
    return UserTagScheduleQuery.split(
      posts: posts,
      tagId: tag.id,
      locationName: locationName,
      now: DateTime.now(),
      guestsOnly: guestsOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.select((AppContext c) => (c.catalogsEpoch, c.usersEpoch));
    final appContext = Provider.of<AppContext>(context, listen: false);
    final tag = appContext.tagById(widget.tagId);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final active = _activeLocations(appContext);
    final location = _selectedLocation(active);

    return Scaffold(
      appBar: AppBar(
        title: Text(tag?.name ?? l10n.manageUserTagsMenuTitle),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          if (tag != null && widget.onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.manageUserTagsEdit,
              onPressed: _saving ? null : widget.onEdit,
            ),
        ],
      ),
      body: ResponsiveContent(
        narrowPadding: 16,
        child: tag == null
            ? _missing(theme, l10n)
            : _detail(
                theme,
                colorScheme,
                l10n,
                appContext,
                tag,
                active,
                location,
              ),
      ),
    );
  }

  Widget _missing(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          l10n.userTagsUnavailable,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _detail(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    AppContext appContext,
    UserTag tag,
    List<UserLocation> activeLocations,
    UserLocation? location,
  ) {
    final description = tag.description;
    final canManage = appContext.currentUser.canManageVolunteers;
    final guestsOnly = appContext.isCurrentUserGuest;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        if (tag.imageUrl != null) ...[
          UserTagGraphic(imageUrl: tag.imageUrl, height: 200),
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: UserTagChip(tag: tag),
        ),
        const SizedBox(height: 16),
        Text(
          tag.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description ?? l10n.userTagsDetailEmpty,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: description == null
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.userTagDetailLocation,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (activeLocations.isEmpty)
          Text(
            l10n.userTagDetailNoLocations,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else if (location != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final site in activeLocations)
                ColoredChip(
                  label: site.name,
                  selected: site.id == location.id,
                  onTap: _saving ? null : () => _onLocationSelected(site),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _headsSection(l10n, appContext, tag, location, canManage),
          const SizedBox(height: 16),
          _membersSection(l10n, appContext, tag, location),
          if (canManage || tag.galleryForLocation(location.id).isNotEmpty) ...[
            const SizedBox(height: 16),
            _gallerySection(l10n, tag, location, canManage),
          ],
          const SizedBox(height: 16),
          _scheduleBlock(l10n, tag, location, guestsOnly),
        ],
      ],
    );
  }

  Widget _headsSection(
    AppLocalizations l10n,
    AppContext appContext,
    UserTag tag,
    UserLocation location,
    bool canManage,
  ) {
    final heads = UserTagHelpers.visibleHeadsAtLocation(
      tag: tag,
      locationId: location.id,
      users: appContext.allUsers,
    );

    return InfoSectionCard(
      icon: Icons.supervisor_account_outlined,
      title: l10n.userTagDetailHeads,
      subtitle: l10n.userTagDetailHeadsSubtitle(location.name),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (heads.isEmpty)
            _sectionEmpty(l10n.userTagDetailHeadsEmpty(location.name))
          else
            ChurchPastorUserList(
              pastorUserIds: heads.map((user) => user.id).toList(),
              onUserTap: (user) => AppLinks.openPerson(
                context,
                id: user.id,
                extra: user,
              ),
            ),
          if (canManage) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: _saving ? null : () => _chooseHeads(tag, location),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(l10n.userTagDetailChooseHeads),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _membersSection(
    AppLocalizations l10n,
    AppContext appContext,
    UserTag tag,
    UserLocation location,
  ) {
    final members = UserTagHelpers.membersAtLocation(
      tagId: tag.id,
      locationName: location.name,
      users: appContext.allUsers,
    );
    final isWide = ResponsiveLayout.isWideScreenOf(context);

    return InfoSectionCard(
      icon: Icons.groups_outlined,
      title: l10n.userTagDetailMembers,
      subtitle: l10n.userTagDetailMembersSubtitle(location.name),
      content: members.isEmpty
          ? _sectionEmpty(l10n.userTagDetailMembersEmpty(location.name))
          : isWide
              ? PairedRowList(
                  itemCount: members.length,
                  runSpacing: 12,
                  itemBuilder: (_, index) => _memberCard(members[index]),
                )
              : Column(
                  children: [
                    for (var i = 0; i < members.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _memberCard(members[i]),
                    ],
                  ],
                ),
    );
  }

  Widget _memberCard(User user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => AppLinks.openPerson(context, id: user.id, extra: user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Hero(
                tag: 'user_avatar_${user.id}',
                child: MyUserAvatar(user),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.fullname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gallerySection(
    AppLocalizations l10n,
    UserTag tag,
    UserLocation location,
    bool canManage,
  ) {
    final photos = tag.galleryForLocation(location.id);
    final atCap = photos.length >= UserTag.maxGalleryImages;

    return InfoSectionCard(
      icon: Icons.photo_library_outlined,
      title: l10n.userTagDetailGallery,
      subtitle: l10n.userTagDetailGallerySubtitle(location.name),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photos.isEmpty)
            _sectionEmpty(l10n.userTagDetailGalleryEmpty(location.name))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final src in photos)
                  _photoTile(tag, location, src, canManage),
              ],
            ),
          if (canManage) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed:
                    _saving || atCap ? null : () => _addPhoto(tag, location),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(l10n.userTagDetailAddPhoto),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _photoTile(
    UserTag tag,
    UserLocation location,
    String src,
    bool canManage,
  ) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openPhoto(tag.id, src),
                borderRadius: BorderRadius.circular(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedImageWidget(
                    imageUrl: src,
                    fit: BoxFit.cover,
                    heroTag: '${tag.id}-$src',
                  ),
                ),
              ),
            ),
          ),
          if (canManage)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                tooltip: AppLocalizations.of(context)!.userTagDetailRemovePhoto,
                onPressed:
                    _saving ? null : () => _removePhoto(tag, location, src),
                icon: const Icon(Icons.close, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  void _openPhoto(String tagId, String src) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: PhotoView(
            imageProvider: NetworkImage(NetworkImageHelper.getImageUrl(src)),
            heroAttributes: PhotoViewHeroAttributes(tag: '$tagId-$src'),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.5,
          ),
        ),
      ),
    );
  }

  Widget _scheduleBlock(
    AppLocalizations l10n,
    UserTag tag,
    UserLocation location,
    bool guestsOnly,
  ) {
    if (_scheduleLoading || _programsLoading || _scheduleError != null) {
      return SizedBox(
        height: 220,
        child: LoadProgressBody(
          message: _statusMessage,
          completedSteps: _completedSteps,
          totalSteps: _totalSteps,
          error: _scheduleError,
          errorTitle: l10n.userTagDetailScheduleCouldNotLoad,
          onRetry: _loadSchedule,
        ),
      );
    }

    final split = _scheduleFor(tag, location.name, guestsOnly);
    final isWide = ResponsiveLayout.isWideScreenOf(context);
    return Column(
      children: [
        _scheduleSection(
          icon: Icons.event_outlined,
          title: l10n.userTagDetailUpcoming,
          subtitle: l10n.userTagDetailUpcomingSubtitle(
            _horizonMonths,
            location.name,
          ),
          posts: split.upcoming,
          empty: l10n.userTagDetailScheduleEmptyUpcoming(location.name),
          isWide: isWide,
          l10n: l10n,
        ),
        const SizedBox(height: 16),
        _scheduleSection(
          icon: Icons.history,
          title: l10n.userTagDetailPast,
          subtitle: l10n.userTagDetailPastSubtitle(
            _horizonMonths,
            location.name,
          ),
          posts: split.past,
          empty: l10n.userTagDetailScheduleEmptyPast(location.name),
          isWide: isWide,
          l10n: l10n,
        ),
      ],
    );
  }

  Widget _scheduleSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<TeamRotaPost> posts,
    required String empty,
    required bool isWide,
    required AppLocalizations l10n,
  }) {
    final groups = TeamRotaQuery.groupByMonth(posts);
    return InfoSectionCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      content: posts.isEmpty
          ? _sectionEmpty(empty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < groups.length; i++) ...[
                  if (i > 0) const SizedBox(height: 20),
                  _monthHeader(groups[i]),
                  const SizedBox(height: 8),
                  if (isWide)
                    PairedRowList(
                      itemCount: groups[i].posts.length,
                      runSpacing: 12,
                      itemBuilder: (_, index) =>
                          _postCard(groups[i].posts[index], l10n),
                    )
                  else
                    for (var p = 0; p < groups[i].posts.length; p++) ...[
                      if (p > 0) const SizedBox(height: 12),
                      _postCard(groups[i].posts[p], l10n),
                    ],
                ],
              ],
            ),
    );
  }

  Widget _monthHeader(TeamRotaMonthGroup group) {
    final locale = Localizations.localeOf(context).toString();
    final label = DateFormat.yMMMM(locale).format(group.monthDate);
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _postCard(TeamRotaPost post, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = post.head.eventDate != null
        ? _eventDateFormat.format(post.head.eventDate!)
        : l10n.personalScheduleDateTbc;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            AppLinks.openPost(context, id: post.head.id, extra: post.head),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post.head.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                ),
                for (var i = 0; i < post.roles.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _roleRow(post.roles[i], l10n, theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleRow(
    Map<String, dynamic> role,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final start = role['start'] as DateTime?;
    final end = role['end'] as DateTime?;
    final timeLabel = start != null && end != null
        ? '${_timeFormat.format(start)} – ${_timeFormat.format(end)}'
        : null;
    final assigned = _assignedUsers(role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                role['title'] as String? ?? '',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (timeLabel != null) ...[
              const SizedBox(width: 12),
              Text(
                timeLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (assigned.isNotEmpty)
          MyAvatarStack(
            users: assigned,
            height: 28,
            width: (28.0 * assigned.length.clamp(1, 4)).clamp(28, 88),
            borderWidth: 1.2,
          )
        else
          Text(
            l10n.teamRotaUnassigned,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  List<User> _assignedUsers(Map<String, dynamic> role) {
    final users = <User>[];
    for (final id in TeamRotaQuery.uidsOf(role)) {
      final user = _appContext.userById(id);
      if (user != null) users.add(user);
    }
    return users;
  }

  Widget _sectionEmpty(String message) {
    final theme = Theme.of(context);
    return Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Future<void> _chooseHeads(UserTag tag, UserLocation location) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: tag.headsForLocation(location.id),
          includeCurrentUser: true,
          includePlaceholders: false,
          preferServing: true,
          lockedLocation: location.name,
          title: l10n.userTagDetailChooseHeads,
        ),
      ),
    );
    if (result == null || !mounted) return;
    tag.setHeadsForLocation(location.id, result);
    await _saveTag(tag);
  }

  Future<void> _addPhoto(UserTag tag, UserLocation location) async {
    final l10n = AppLocalizations.of(context)!;
    final existing = tag.galleryForLocation(location.id);
    if (existing.length >= UserTag.maxGalleryImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(l10n.userTagDetailGalleryFull(UserTag.maxGalleryImages)),
        ),
      );
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMediaFilePage(
          eventContext: EventContext.adding(
            currentUserID: _appContext.currentUser.id,
          ),
          returnResultOnly: true,
        ),
      ),
    );
    if (!mounted || result == null) return;

    final type = (result['type'] as String?) ?? 'img';
    if (type != 'img') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userTagDetailPhotosImagesOnly)),
      );
      return;
    }

    final src = (result['src'] as String?)?.trim() ?? '';
    if (src.isEmpty || existing.contains(src)) return;
    tag.setGalleryForLocation(location.id, [...existing, src]);
    await _saveTag(tag);
  }

  Future<void> _removePhoto(
    UserTag tag,
    UserLocation location,
    String src,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: l10n.userTagDetailRemovePhoto,
      content: l10n.userTagDetailRemovePhotoConfirm(location.name),
      confirmText: l10n.userTagDetailRemovePhoto,
      cancelText: l10n.cancel,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final next =
        tag.galleryForLocation(location.id).where((url) => url != src).toList();
    tag.setGalleryForLocation(location.id, next);
    await _saveTag(tag);
  }

  Future<void> _saveTag(UserTag tag) async {
    setState(() => _saving = true);
    try {
      await _tagDb.updateTag(tag);
      if (!mounted) return;
      final appContext = Provider.of<AppContext>(context, listen: false);
      appContext.addOrUpdateTag(tag);
      await UserActivityRecorder().record(
        actorUserId: appContext.currentUser.id,
        log: UserActivityMessages.editedUserTag,
        documentId: tag.id,
      );
    } catch (e, st) {
      debugPrint('Could not save team tag ${tag.id}: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.userTagDetailCouldNotSave),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
