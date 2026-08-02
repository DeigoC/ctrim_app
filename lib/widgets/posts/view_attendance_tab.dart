import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/messaging_manager.dart';
import '../../models/event/event_attendance.dart';
import '../../models/user.dart';
import '../../pages/personal/guest_registration_page.dart';
import '../../pages/personal/select_users_page.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/notification_topics.dart';
import '../action_sheet.dart';
import '../load_progress_body.dart';
import '../user_avatar.dart';

/// People tab: interested (self-serve) + attendees (author/contributor managed).
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

class _ViewAttendanceTabState extends State<ViewAttendanceTab> {
  static final MessagingManager _messagingManager = MessagingManager();
  static final AuthManager _authManager = AuthManager();

  bool _loading = true;
  bool _busy = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    if (!_authManager.isSignedIn) {
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
      final attendance = await EventSupplementalDBManager(widget.eventContext.id).fetchAttendance();
      if (!mounted) return;
      widget.eventContext.setFetchedAttendance(attendance);
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
    final appContext = Provider.of<AppContext>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final head = widget.eventContext.head;

    if (!_authManager.isSignedIn) {
      return _buildGuestBody(theme, colorScheme, head.interestedCount, head.attendeeCount);
    }

    if (_loading || _loadError != null) {
      return LoadProgressBody(
        message: 'Loading attendance…',
        completedSteps: _loading ? 0 : 1,
        totalSteps: 1,
        error: _loadError,
        errorTitle: 'Could not load attendance',
        onRetry: _loadAttendance,
      );
    }

    final attendance = widget.eventContext.attendance ?? EventAttendance();
    final canManage = widget.eventContext.isUserAdminOfPost(appContext.currentUser.id);
    final authId = _authManager.currentAuthUID;
    final isInterested = attendance.hasInterest(authId);
    final hasInterested = attendance.interested.isNotEmpty;
    final hasAttendees = attendance.attendees.isNotEmpty;
    final attendeeLabel = widget.eventContext.head.isRecent ? 'Attended' : 'Attending';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildInterestToggle(theme, colorScheme, isInterested),
        if (hasInterested) ...[
          const SizedBox(height: 20),
          _buildSectionCard(
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
          ),
        ],
        if (hasAttendees) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            theme,
            colorScheme,
            icon: Icons.groups_outlined,
            title: '$attendeeLabel (${attendance.attendeeCount})',
            trailing: canManage
                ? IconButton(
                    tooltip: 'Manage attendees',
                    onPressed: _busy ? null : _showManageAttendeesSheet,
                    icon: const Icon(Icons.person_add_alt_1),
                  )
                : null,
            child: Column(
              children: [
                for (final entry in attendance.attendees)
                  _buildAttendeeTile(theme, colorScheme, appContext, entry, canManage: canManage),
              ],
            ),
          ),
        ] else if (canManage) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _showManageAttendeesSheet,
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Add attendees'),
          ),
        ],
      ],
    );
  }

  bool _isAlreadyAttending(EventAttendance attendance, InterestedEntry entry) {
    if (entry.userId != null) {
      return attendance.attendees.any((a) => a.isUser && a.userId == entry.userId);
    }
    return false;
  }

  Widget _buildGuestBody(ThemeData theme, ColorScheme colorScheme, int interested, int attending) {
    final attendeeWord = widget.eventContext.head.isRecent ? 'attended' : 'attending';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.lock_outline, size: 40, color: colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Sign in to see who is interested',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          interested == 0 && attending == 0
              ? 'Create an account or sign in to mark interest, follow updates, and see names.'
              : '$interested interested · $attending $attendeeWord.\n'
                  'Sign in to see names and mark your own interest.',
          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GuestRegistrationPage()));
          },
          child: const Text('Create account'),
        ),
        const SizedBox(height: 8),
        Text(
          'Already registered? Sign in from the Personal tab.',
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInterestToggle(ThemeData theme, ColorScheme colorScheme, bool isInterested) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        value: isInterested,
        onChanged: _busy ? null : (value) => _toggleInterest(value),
        title: Text(
          isInterested ? 'You are interested' : 'Mark interest',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isInterested
              ? 'You will get updates when this post changes.'
              : 'Show up publicly and follow updates for this post.',
        ),
        secondary: Icon(isInterested ? Icons.favorite : Icons.favorite_border, color: colorScheme.primary),
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
                  child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
      leading: _avatarForUserId(appContext, entry.userId, entry.displayName, colorScheme.secondaryContainer),
      title: Text(entry.displayName),
      subtitle: Text(
        alreadyAttending
            ? (widget.eventContext.head.isRecent ? 'Interested · also attended' : 'Interested · also attending')
            : 'Interested',
      ),
      trailing: canManage
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!alreadyAttending && _canPromote(entry, appContext))
                  IconButton(
                    tooltip: widget.eventContext.head.isRecent ? 'Mark as attended' : 'Mark as attending',
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
          ? _avatarForUserId(appContext, entry.userId, entry.displayName, colorScheme.tertiaryContainer)
          : CircleAvatar(
              backgroundColor: colorScheme.tertiaryContainer,
              child: const Icon(Icons.person_outline, size: 20),
            ),
      title: Text(entry.displayName),
      subtitle: Text(entry.isExternal
          ? (entry.note?.isNotEmpty == true ? entry.note! : 'Guest (not registered)')
          : 'Registered'),
      trailing: canManage
          ? IconButton(
              tooltip: 'Remove attendee',
              icon: const Icon(Icons.close),
              onPressed: _busy ? null : () => _removeAttendee(entry.id),
            )
          : null,
    );
  }

  Widget _avatarForUserId(
    AppContext appContext,
    String? userId,
    String displayName,
    Color fallbackColor,
  ) {
    if (userId != null) {
      try {
        final user = appContext.getUserFromID(userId);
        return MyUserAvatar(user, radius: 20);
      } catch (_) {
        // fall through
      }
    }
    return CircleAvatar(
      backgroundColor: fallbackColor,
      child: Text(_initials(displayName)),
    );
  }

  bool _canPromote(InterestedEntry entry, AppContext appContext) {
    return _resolveUserIdForInterest(entry, appContext) != null;
  }

  String? _resolveUserIdForInterest(InterestedEntry entry, AppContext appContext) {
    if (entry.userId != null && entry.userId!.isNotEmpty) return entry.userId;
    try {
      return appContext.allUsers.firstWhere((u) => u.authID == entry.authId).id;
    } catch (_) {
      return null;
    }
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
    final userId = appContext.isCurrentUserGuest ? null : appContext.currentUser.id;
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
        final updated = await EventSupplementalDBManager(widget.eventContext.id).setOwnInterest(
          authId: authId,
          displayName: displayName,
          userId: userId,
          interested: interested,
        );
        widget.eventContext.setFetchedAttendance(updated);

        onProgress(
          completed: 1,
          total: total,
          message: interested ? 'Subscribing to updates…' : 'Unsubscribing from updates…',
        );
        if (interested) {
          appContext.sharedPref.addPostBookmark(widget.eventContext.id);
          await _messagingManager.subscribeToTopic(topic, authId: webAuthId);
        } else {
          appContext.sharedPref.removePostBookmark(widget.eventContext.id);
          await _messagingManager.unsubscribeFromTopic(topic, authId: webAuthId);
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
        final updated = await EventSupplementalDBManager(widget.eventContext.id).removeInterestForAuthId(authId);
        widget.eventContext.setFetchedAttendance(updated);
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

    User? user;
    try {
      user = appContext.getUserFromID(userId);
    } catch (_) {
      user = null;
    }

    final next = List<AttendeeEntry>.from(attendance.attendees)
      ..add(AttendeeEntry.user(
        userId: userId,
        displayName: user?.fullname ?? entry.displayName,
        addedBy: appContext.currentUser.id,
      ));
    await _persistAttendees(next);
  }

  Future<void> _removeAttendee(String id) async {
    final attendance = widget.eventContext.attendance ?? EventAttendance();
    final next = attendance.attendees.where((e) => e.id != id).toList();
    await _persistAttendees(next);
  }

  Future<void> _persistAttendees(List<AttendeeEntry> attendees) async {
    setState(() => _busy = true);
    final ok = await DialogManager.runWithProgressDialog(
      context: context,
      title: 'Updating attendees…',
      action: () async {
        final updated = await EventSupplementalDBManager(widget.eventContext.id).saveAttendees(attendees);
        widget.eventContext.setFetchedAttendance(updated);
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onChanged();
  }

  void _showManageAttendeesSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return ActionSheetShell(
          icon: Icons.groups_outlined,
          title: 'Manage attendees',
          subtitle: 'Add registered users or guests by name',
          children: [
            ActionSheetOptionGrid(
              children: [
                ActionSheetOption(
                  icon: Icons.person_search,
                  color: Colors.blue,
                  title: 'Add registered users',
                  subtitle: 'Pick from people already in the app',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _addRegisteredUsers();
                  },
                ),
                ActionSheetOption(
                  icon: Icons.person_outline,
                  color: Colors.teal,
                  title: 'Add guest by name',
                  subtitle: 'Someone who is not registered yet',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _addExternalGuest();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _addRegisteredUsers() async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final attendance = widget.eventContext.attendance ?? EventAttendance();
    final selected = attendance.attendees.where((e) => e.isUser && e.userId != null).map((e) => e.userId!).toList();

    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: selected,
          title: 'Select attendees',
        ),
      ),
    );
    if (result == null || !mounted) return;

    final byId = {
      for (final e in attendance.attendees.where((e) => e.isUser && e.userId != null)) e.userId!: e,
    };
    final externals = attendance.attendees.where((e) => e.isExternal).toList();
    final next = <AttendeeEntry>[...externals];

    for (final uid in result) {
      if (byId.containsKey(uid)) {
        next.add(byId[uid]!);
        continue;
      }
      User? user;
      try {
        user = appContext.allUsers.firstWhere((u) => u.id == uid);
      } catch (_) {
        user = null;
      }
      next.add(AttendeeEntry.user(
        userId: uid,
        displayName: user?.fullname ?? uid,
        addedBy: appContext.currentUser.id,
      ));
    }

    await _persistAttendees(next);
  }

  Future<void> _addExternalGuest() async {
    final nameController = TextEditingController();
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add guest'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Add')),
          ],
        );
      },
    );

    final name = nameController.text.trim();
    nameController.dispose();
    final note = noteController.text.trim();
    noteController.dispose();

    if (confirmed != true || name.isEmpty || !mounted) return;

    final appContext = Provider.of<AppContext>(context, listen: false);
    final attendance = widget.eventContext.attendance ?? EventAttendance();
    final next = List<AttendeeEntry>.from(attendance.attendees)
      ..add(AttendeeEntry.external(
        name: name,
        note: note.isEmpty ? null : note,
        addedBy: appContext.currentUser.id,
      ));
    await _persistAttendees(next);
  }
}
