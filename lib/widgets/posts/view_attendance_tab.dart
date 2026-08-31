import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/messaging_manager.dart';
import '../../models/event/event_attendance.dart';
import '../../models/user.dart';
import '../../pages/personal/guest_registration_page.dart';
import '../../pages/personal/select_users_page.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/notifications/notification_topics.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../common/load_progress_body.dart';
import '../two_column_masonry.dart';
import '../user_avatar.dart';

/// People tab: interested (self-serve) + expected checklist + attendees (author/contributor).
class ViewAttendanceTab extends StatefulWidget {
  const ViewAttendanceTab({
    super.key,
    required this.eventContext,
    required this.onChanged,
  });

  final EventContext eventContext;
  final VoidCallback onChanged;

  @override
  State<ViewAttendanceTab> createState() => _ViewAttendanceTabState();
}

class _ViewAttendanceTabState extends State<ViewAttendanceTab>
    with AutomaticKeepAliveClientMixin {
  static final MessagingManager _messagingManager = MessagingManager();
  static final AuthManager _authManager = AuthManager();

  bool _loading = true;
  bool _busy = false;
  Object? _loadError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  /// Loads attendance once per post view. Tab switches remount this widget;
  /// reuse [EventContext] data so unsaved attendee edits are not wiped by a
  /// refetch with [forceReplace].
  Future<void> _loadAttendance({bool forceReload = false}) async {
    if (!_authManager.isSignedIn) {
      setState(() {
        _loading = false;
        _loadError = null;
      });
      return;
    }

    if (!forceReload && widget.eventContext.hasLoadedAttendance) {
      setState(() {
        _loading = false;
        _loadError = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final attendance =
          await EventSupplementalDBManager(widget.eventContext.id)
              .fetchAttendance();
      if (!mounted) return;
      widget.eventContext.setFetchedAttendance(
        attendance,
        forceReplace: !widget.eventContext.isAttendanceDirty,
      );
      setState(() => _loading = false);
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appContext = Provider.of<AppContext>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final head = widget.eventContext.head;

    if (!_authManager.isSignedIn) {
      return _buildGuestBody(
          theme, colorScheme, head.interestedCount, head.attendeeCount);
    }

    if (_loading || _loadError != null) {
      return LoadProgressBody(
        message: 'Loading attendance…',
        completedSteps: _loading ? 0 : 1,
        totalSteps: 1,
        error: _loadError,
        errorTitle: 'Could not load attendance',
        onRetry: () => _loadAttendance(forceReload: true),
      );
    }

    final attendance = widget.eventContext.attendance ?? EventAttendance();
    final canManage =
        widget.eventContext.isUserAdminOfPost(appContext.currentUser.id);
    final authId = _authManager.currentAuthUID;
    final isInterested = attendance.hasInterest(authId);
    final hasInterested = attendance.interested.isNotEmpty;
    final hasExpected = attendance.expectedUserIds.isNotEmpty;
    final hasAttendees = attendance.attendees.isNotEmpty;
    final attendeeLabel =
        widget.eventContext.head.isRecent ? 'Attended' : 'Attending';
    final hasLinkedCellGroups =
        widget.eventContext.head.cellGroupIDs.isNotEmpty;
    final isWide = ResponsiveLayout.isWideScreenOf(context);

    final interestedCard = hasInterested
        ? _buildSectionCard(
            theme,
            colorScheme,
            icon: Icons.favorite_outline,
            title: 'Interested (${attendance.interestedCount})',
            child: Column(
              children: [
                for (final entry in attendance.interested.values)
                  _buildInterestedTile(
                    theme,
                    colorScheme,
                    appContext,
                    entry,
                    canManage: canManage,
                    alreadyAttending: _isAlreadyAttending(attendance, entry),
                  ),
              ],
            ),
          )
        : null;

    final expectedCard = (canManage || hasExpected)
        ? _buildSectionCard(
            theme,
            colorScheme,
            icon: Icons.checklist,
            title: 'Expected (${attendance.expectedCount})',
            trailing: canManage
                ? IconButton(
                    tooltip: 'Manage expected',
                    onPressed: _busy ? null : _manageExpected,
                    icon: const Icon(Icons.edit_outlined),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!hasExpected)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No expected attendees yet. Add the usual people, or fill from a linked cell group.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final userId in attendance.expectedUserIds)
                    _buildExpectedTile(
                      theme,
                      colorScheme,
                      appContext,
                      userId,
                      checked: attendance.hasUserAttendee(userId),
                      canManage: canManage,
                    ),
                if (canManage) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _manageExpected,
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: Text(
                            hasExpected ? 'Edit expected' : 'Add expected'),
                      ),
                      if (hasLinkedCellGroups)
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _seedExpectedFromCellGroups,
                          icon: const Icon(Icons.groups_outlined, size: 18),
                          label: const Text('Fill from cell group'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          )
        : null;

    final attendeesCard = hasAttendees
        ? _buildSectionCard(
            theme,
            colorScheme,
            icon: Icons.groups_outlined,
            title: '$attendeeLabel (${attendance.attendeeCount})',
            trailing: canManage
                ? IconButton(
                    tooltip: 'Manage attendees',
                    onPressed: _busy ? null : _manageAttendees,
                    icon: const Icon(Icons.person_add_alt_1),
                  )
                : null,
            child: Column(
              children: [
                for (final entry in attendance.attendees)
                  _buildAttendeeTile(theme, colorScheme, appContext, entry,
                      canManage: canManage),
              ],
            ),
          )
        : null;

    final peopleCards = <Widget>[
      if (interestedCard != null) interestedCard,
      if (expectedCard != null) expectedCard,
      if (attendeesCard != null) attendeesCard,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildInterestToggle(theme, colorScheme, isInterested),
        if (peopleCards.isNotEmpty) ...[
          const SizedBox(height: 20),
          if (isWide && peopleCards.length > 1)
            TwoColumnMasonry(children: peopleCards)
          else ...[
            for (var i = 0; i < peopleCards.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              peopleCards[i],
            ],
          ],
        ],
        if (!hasAttendees && canManage) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _manageAttendees,
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Add attendees'),
          ),
        ],
      ],
    );
  }

  bool _isAlreadyAttending(EventAttendance attendance, InterestedEntry entry) {
    if (entry.userId != null) {
      return attendance.attendees
          .any((a) => a.isUser && a.userId == entry.userId);
    }
    return false;
  }

  Widget _buildGuestBody(
      ThemeData theme, ColorScheme colorScheme, int interested, int attending) {
    final attendeeWord =
        widget.eventContext.head.isRecent ? 'attended' : 'attending';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.lock_outline, size: 40, color: colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Sign in to see who is interested',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          interested == 0 && attending == 0
              ? 'Create an account or sign in to mark interest, follow updates, and see names.'
              : '$interested interested · $attending $attendeeWord.\n'
                  'Sign in to see names and mark your own interest.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const GuestRegistrationPage()));
          },
          child: const Text('Create account'),
        ),
        const SizedBox(height: 8),
        Text(
          'Already registered? Sign in from the Personal tab.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInterestToggle(
      ThemeData theme, ColorScheme colorScheme, bool isInterested) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        value: isInterested,
        onChanged: _busy ? null : (value) => _toggleInterest(value),
        title: Text(
          isInterested ? 'You are interested' : 'Mark interest',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isInterested
              ? 'You will get updates when this post changes.'
              : 'Show up publicly and follow updates for this post.',
        ),
        secondary: Icon(isInterested ? Icons.favorite : Icons.favorite_border,
            color: colorScheme.primary),
      ),
    );
  }

  Widget _buildSectionCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildExpectedTile(
    ThemeData theme,
    ColorScheme colorScheme,
    AppContext appContext,
    String userId, {
    required bool checked,
    required bool canManage,
  }) {
    final name = _displayNameForUserId(appContext, userId);
    return CheckboxListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      value: checked,
      onChanged: canManage && !_busy
          ? (value) => _toggleExpectedChecked(userId, value ?? false)
          : null,
      secondary: _avatarForUserId(
          appContext, userId, name, colorScheme.secondaryContainer),
      title: Text(name),
      subtitle: Text(
        checked
            ? (widget.eventContext.head.isRecent
                ? 'Marked attended'
                : 'Marked attending')
            : 'Expected',
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildInterestedTile(
    ThemeData theme,
    ColorScheme colorScheme,
    AppContext appContext,
    InterestedEntry entry, {
    required bool canManage,
    required bool alreadyAttending,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: _avatarForUserId(appContext, entry.userId, entry.displayName,
          colorScheme.secondaryContainer),
      title: Text(entry.displayName),
      subtitle: Text(
        alreadyAttending
            ? (widget.eventContext.head.isRecent
                ? 'Interested · also attended'
                : 'Interested · also attending')
            : 'Interested',
      ),
      trailing: canManage
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!alreadyAttending && _canPromote(entry, appContext))
                  IconButton(
                    tooltip: widget.eventContext.head.isRecent
                        ? 'Mark as attended'
                        : 'Mark as attending',
                    icon: const Icon(Icons.person_add_alt_1),
                    onPressed: _busy ? null : () => _promoteToAttendee(entry),
                  ),
                IconButton(
                  tooltip: 'Remove interest',
                  icon: const Icon(Icons.close),
                  onPressed: _busy ? null : () => _removeInterest(entry.authId),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildAttendeeTile(
    ThemeData theme,
    ColorScheme colorScheme,
    AppContext appContext,
    AttendeeEntry entry, {
    required bool canManage,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: entry.isUser
          ? _avatarForUserId(appContext, entry.userId, entry.displayName,
              colorScheme.tertiaryContainer)
          : CircleAvatar(
              backgroundColor: colorScheme.tertiaryContainer,
              child: const Icon(Icons.person_outline, size: 20),
            ),
      title: Text(entry.displayName),
      subtitle: Text(_attendeeSubtitle(appContext, entry)),
      trailing: canManage
          ? IconButton(
              tooltip: 'Remove attendee',
              icon: const Icon(Icons.close),
              onPressed: _busy ? null : () => _removeAttendee(entry.id),
            )
          : null,
    );
  }

  String _attendeeSubtitle(AppContext appContext, AttendeeEntry entry) {
    if (entry.isExternal) {
      return entry.note?.isNotEmpty == true
          ? entry.note!
          : 'Guest (legacy name-only)';
    }
    if (entry.userId != null) {
      final user = appContext.userById(entry.userId!);
      if (user != null && user.isPlaceholder) return 'Placeholder';
    }
    return 'Registered';
  }

  Widget _avatarForUserId(
    AppContext appContext,
    String? userId,
    String displayName,
    Color fallbackColor,
  ) {
    if (userId != null) {
      final user = appContext.userById(userId);
      if (user != null) {
        return MyUserAvatar(user, radius: 20);
      }
    }
    return CircleAvatar(
      backgroundColor: fallbackColor,
      child: Text(_initials(displayName)),
    );
  }

  String _displayNameForUserId(AppContext appContext, String userId) {
    return appContext.userById(userId)?.fullname ?? userId;
  }

  bool _canPromote(InterestedEntry entry, AppContext appContext) {
    return _resolveUserIdForInterest(entry, appContext) != null;
  }

  String? _resolveUserIdForInterest(
      InterestedEntry entry, AppContext appContext) {
    if (entry.userId != null && entry.userId!.isNotEmpty) return entry.userId;
    for (final user in appContext.allUsers) {
      if (user.authID == entry.authId) return user.id;
    }
    return null;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _resolveDisplayName(AppContext appContext) {
    if (!appContext.isCurrentUserGuest) {
      return appContext.currentUser.fullname;
    }
    final email = _authManager.currentEmailOrNull;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Signed-in user';
  }

  Future<void> _toggleInterest(bool interested) async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final authId = _authManager.currentAuthUID;
    final displayName = _resolveDisplayName(appContext);
    final userId =
        appContext.isCurrentUserGuest ? null : appContext.currentUser.id;
    final topic = NotificationTopics.postTopic(widget.eventContext.id);
    final webAuthId = kIsWeb ? authId : null;

    setState(() => _busy = true);
    final ok = await DialogManager.runWithSteppedProgressDialog(
      context: context,
      title: interested ? 'Marking interest' : 'Removing interest',
      initialMessage: interested ? 'Saving interest…' : 'Removing interest…',
      action: (onProgress) async {
        const total = 2;
        onProgress(
          completed: 0,
          total: total,
          message: interested ? 'Saving interest…' : 'Removing interest…',
        );
        final updated = await EventSupplementalDBManager(widget.eventContext.id)
            .setOwnInterest(
          authId: authId,
          displayName: displayName,
          userId: userId,
          interested: interested,
        );
        widget.eventContext.setFetchedAttendance(updated);
        await UserActivityRecorder().record(
          actorUserId: userId,
          log: UserActivityMessages.updatedPostInterest,
          documentId: widget.eventContext.id,
        );

        onProgress(
          completed: 1,
          total: total,
          message: interested
              ? 'Subscribing to updates…'
              : 'Unsubscribing from updates…',
        );
        if (interested) {
          appContext.sharedPref.addPostBookmark(widget.eventContext.id);
          await _messagingManager.subscribeToTopic(topic, authId: webAuthId);
        } else {
          appContext.sharedPref.removePostBookmark(widget.eventContext.id);
          await _messagingManager.unsubscribeFromTopic(topic,
              authId: webAuthId);
        }
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onChanged();
  }

  Future<void> _removeInterest(String authId) async {
    setState(() => _busy = true);
    final ok = await DialogManager.runWithProgressDialog(
      context: context,
      title: 'Removing…',
      action: () async {
        final actorId =
            Provider.of<AppContext>(context, listen: false).currentUser.id;
        final updated = await EventSupplementalDBManager(widget.eventContext.id)
            .removeInterestForAuthId(authId);
        widget.eventContext.setFetchedAttendance(updated);
        await UserActivityRecorder().record(
          actorUserId: actorId,
          log: UserActivityMessages.updatedPostInterest,
          documentId: widget.eventContext.id,
        );
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onChanged();
  }

  Future<void> _promoteToAttendee(InterestedEntry entry) async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final userId = _resolveUserIdForInterest(entry, appContext);
    if (userId == null) return;

    final attendance = widget.eventContext.attendance ?? EventAttendance();
    if (attendance.attendees.any((a) => a.isUser && a.userId == userId)) {
      return;
    }

    final user = appContext.userById(userId);

    final next = List<AttendeeEntry>.from(attendance.attendees)
      ..add(AttendeeEntry.user(
        userId: userId,
        displayName: user?.fullname ?? entry.displayName,
        addedBy: appContext.currentUser.id,
      ));
    _applyAttendeesLocally(next);
  }

  Future<void> _toggleExpectedChecked(String userId, bool checked) async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final attendance = widget.eventContext.attendance ?? EventAttendance();

    if (checked) {
      if (attendance.hasUserAttendee(userId)) return;
      final name = _displayNameForUserId(appContext, userId);
      final next = List<AttendeeEntry>.from(attendance.attendees)
        ..add(AttendeeEntry.user(
          userId: userId,
          displayName: name,
          addedBy: appContext.currentUser.id,
        ));
      _applyAttendeesLocally(next);
      return;
    }

    final next = attendance.attendees
        .where((e) => !(e.isUser && e.userId == userId))
        .toList();
    _applyAttendeesLocally(next);
  }

  Future<void> _removeAttendee(String id) async {
    final attendance = widget.eventContext.attendance ?? EventAttendance();
    final next = attendance.attendees.where((e) => e.id != id).toList();
    _applyAttendeesLocally(next);
  }

  void _applyAttendeesLocally(List<AttendeeEntry> attendees) {
    final current = widget.eventContext.attendance ?? EventAttendance();
    final updated = EventAttendance.fromMap({
      ...current.toMutableMap(),
      'attendees': attendees.map((e) => e.toJson()).toList(),
    });
    setState(() {
      widget.eventContext.applyStaffAttendanceEdit(updated);
    });
    widget.onChanged();
  }

  void _applyExpectedLocally(List<String> expectedUserIds) {
    final current = widget.eventContext.attendance ?? EventAttendance();
    final updated = EventAttendance.fromMap({
      ...current.toMutableMap(),
      'expectedUserIds': expectedUserIds,
    });
    setState(() {
      widget.eventContext.applyStaffAttendanceEdit(updated);
    });
    widget.onChanged();
  }

  Future<void> _manageExpected() async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final attendance = widget.eventContext.attendance ?? EventAttendance();
    final authorUid = widget.eventContext.metadata.authorUID;

    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: List<String>.from(attendance.expectedUserIds),
          title: 'Expected attendees',
          includePlaceholders: true,
          allowCreatePlaceholder: canCreatePlaceholderUser(
            actor: appContext.currentUser,
            postAuthorUid: authorUid,
          ),
          postIdForPlaceholderCreate: widget.eventContext.id,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final previous = attendance.expectedUserIds.toSet();
    final next = result.toSet();
    if (previous.length == next.length && previous.containsAll(next)) return;

    _applyExpectedLocally(result);
  }

  Future<void> _seedExpectedFromCellGroups() async {
    final cgIds = widget.eventContext.head.cellGroupIDs;
    if (cgIds.isEmpty) return;

    setState(() => _busy = true);
    List<String>? seededIds;
    final ok = await DialogManager.runWithProgressDialog(
      context: context,
      title: 'Filling from cell group…',
      action: () async {
        final ids = <String>{
          ...?(widget.eventContext.attendance?.expectedUserIds),
        };
        for (final cgId in cgIds) {
          final roster =
              await CellGroupSupplementalDBManager(cgId).fetchRoster();
          for (final member in roster.members) {
            if (member.isLinkedUser && member.isActive) {
              ids.add(member.userId);
            }
          }
        }
        seededIds = ids.toList();
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok && seededIds != null) {
      _applyExpectedLocally(seededIds!);
    }
  }

  Future<void> _manageAttendees() async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final attendance = widget.eventContext.attendance ?? EventAttendance();
    final selected = attendance.attendees
        .where((e) => e.isUser && e.userId != null)
        .map((e) => e.userId!)
        .toList();

    final authorUid = widget.eventContext.metadata.authorUID;
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: selected,
          title: 'Select attendees',
          includePlaceholders: true,
          allowCreatePlaceholder: canCreatePlaceholderUser(
            actor: appContext.currentUser,
            postAuthorUid: authorUid,
          ),
          postIdForPlaceholderCreate: widget.eventContext.id,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final byId = {
      for (final e
          in attendance.attendees.where((e) => e.isUser && e.userId != null))
        e.userId!: e,
    };
    // Preserve legacy free-text guests until removed individually.
    final externals = attendance.attendees.where((e) => e.isExternal).toList();
    final next = <AttendeeEntry>[...externals];

    for (final uid in result) {
      if (byId.containsKey(uid)) {
        next.add(byId[uid]!);
        continue;
      }
      final user = appContext.userById(uid);
      next.add(AttendeeEntry.user(
        userId: uid,
        displayName: user?.fullname ?? uid,
        addedBy: appContext.currentUser.id,
      ));
    }

    _applyAttendeesLocally(next);
  }
}
