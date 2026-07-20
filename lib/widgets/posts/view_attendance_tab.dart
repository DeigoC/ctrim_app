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

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load attendance.\n$_loadError', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadAttendance, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final attendance = widget.eventContext.attendance ?? EventAttendance();
    final canManage = widget.eventContext.isUserAdminOfPost(appContext.currentUser.id);
    final authId = _authManager.currentAuthUID;
    final isInterested = attendance.hasInterest(authId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _buildInterestToggle(theme, colorScheme, isInterested),
        const SizedBox(height: 24),
        _buildSectionHeader(
          theme,
          colorScheme,
          icon: Icons.favorite_outline,
          title: 'Interested (${attendance.interestedCount})',
        ),
        const SizedBox(height: 8),
        if (attendance.interested.isEmpty)
          _buildEmptyLine(theme, colorScheme, 'No one has marked interest yet.')
        else
          ...attendance.interested.values.map(
            (entry) => _buildInterestedTile(theme, colorScheme, entry, canManage: canManage),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildSectionHeader(
                theme,
                colorScheme,
                icon: Icons.groups_outlined,
                title: 'Attending (${attendance.attendeeCount})',
              ),
            ),
            if (canManage)
              IconButton(
                tooltip: 'Manage attendees',
                onPressed: _busy ? null : _showManageAttendeesSheet,
                icon: const Icon(Icons.person_add_alt_1),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (attendance.attendees.isEmpty)
          _buildEmptyLine(
            theme,
            colorScheme,
            canManage ? 'Add people who are attending this event.' : 'No attendees listed yet.',
          )
        else
          ...attendance.attendees.map(
            (entry) => _buildAttendeeTile(theme, colorScheme, entry, canManage: canManage),
          ),
      ],
    );
  }

  Widget _buildGuestBody(ThemeData theme, ColorScheme colorScheme, int interested, int attending) {
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
              : '$interested interested · $attending attending.\n'
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

  Widget _buildSectionHeader(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyLine(ThemeData theme, ColorScheme colorScheme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
    );
  }

  Widget _buildInterestedTile(
    ThemeData theme,
    ColorScheme colorScheme,
    InterestedEntry entry, {
    required bool canManage,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colorScheme.secondaryContainer,
        child: Text(_initials(entry.displayName)),
      ),
      title: Text(entry.displayName),
      subtitle: const Text('Interested'),
      trailing: canManage
          ? IconButton(
              tooltip: 'Remove interest',
              icon: const Icon(Icons.close),
              onPressed: _busy ? null : () => _removeInterest(entry.authId),
            )
          : null,
    );
  }

  Widget _buildAttendeeTile(
    ThemeData theme,
    ColorScheme colorScheme,
    AttendeeEntry entry, {
    required bool canManage,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colorScheme.tertiaryContainer,
        child: Icon(entry.isExternal ? Icons.person_outline : Icons.person, size: 20),
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
    final ok = await DialogManager.runWithProgressDialog(
      context: context,
      title: interested ? 'Marking interest…' : 'Removing interest…',
      action: () async {
        final updated = await EventSupplementalDBManager(widget.eventContext.id).setOwnInterest(
          authId: authId,
          displayName: displayName,
          userId: userId,
          interested: interested,
        );
        widget.eventContext.setFetchedAttendance(updated);

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
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_search),
                title: const Text('Add registered users'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addRegisteredUsers();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Add guest by name'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addExternalGuest();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
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
