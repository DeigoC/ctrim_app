import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../pages/personal/select_users_page.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../widgets/my_avatar_stack.dart';
import '../../widgets/schedule_duration_picker.dart';
import '../../utility/responsive_layout.dart';

/// Add or edit a program role. Pass [programEntry] when editing an existing item.
class EventProgramPage extends StatefulWidget {
  const EventProgramPage({
    super.key,
    required this.eventContext,
    this.programEntry,
  });

  final EventContext eventContext;
  final Map<String, dynamic>? programEntry;

  bool get isEditing => programEntry != null;

  @override
  State<EventProgramPage> createState() => _EventProgramPageState();
}

class AddEventProgramPage extends EventProgramPage {
  const AddEventProgramPage({super.key, required super.eventContext});
}

class EditEventProgramPage extends EventProgramPage {
  const EditEventProgramPage({
    super.key,
    required super.eventContext,
    required Map<String, dynamic> programEntry,
  }) : super(programEntry: programEntry);
}

class _EventProgramPageState extends State<EventProgramPage> {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  late final TextEditingController _tecTitle;
  late final TextEditingController _tecDetail;
  late final AppContext _appContext;
  late final List<String> _selectedUsers;

  DateTime? _start;
  DateTime? _end;
  bool _canSave = false, _forGuests = true, _isSaved = false, _allowPop = false;

  bool get _isEditing => widget.isEditing;

  void _popRouteAfterAllowing() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void initState() {
    super.initState();
    _appContext = Provider.of<AppContext>(context, listen: false);
    final entry = widget.programEntry;
    if (entry != null) {
      _forGuests = entry['for_guests'];
      _start = entry['start'];
      _end = entry['end'];
      _tecDetail = TextEditingController(text: entry['detail']);
      _tecTitle = TextEditingController(text: entry['title']);
      _selectedUsers = List<String>.from(entry['uids']);
    } else {
      _tecTitle = TextEditingController();
      _tecDetail = TextEditingController();
      _selectedUsers = [];
    }
  }

  @override
  void dispose() {
    _tecTitle.dispose();
    _tecDetail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop || _isSaved,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowPop || _isSaved) return;
        final shouldPop = await DialogManager.discardChanges(context: context);
        if (shouldPop && mounted) {
          _popRouteAfterAllowing();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Program' : 'Add Schedule'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final double webHorizontalPadding = ResponsiveLayout.horizontalGutter(
        MediaQuery.sizeOf(context).width,
        narrowPadding: 16);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          vertical: 16.0, horizontal: webHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Schedule Time',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeSelector(
                          label: 'Start Time',
                          time: _start,
                          isRequired: !_isEditing,
                          onTap: _onStartTimeTap,
                          icon: Icons.play_arrow,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeSelector(
                          label: 'End Time',
                          time: _end,
                          isRequired: !_isEditing,
                          onTap: _start == null ? null : _onEndTimeTap,
                          icon: Icons.stop,
                          isEnabled: _start != null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Program Details',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tecTitle,
                    maxLength: 48,
                    decoration: InputDecoration(
                      label: const Text('Title*'),
                      hintText: 'What is this program about?',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.title),
                      suffixIcon: _isEditing
                          ? null
                          : (_tecTitle.text.trim().isEmpty
                              ? const Icon(Icons.warning_amber,
                                  color: Colors.amber)
                              : const Icon(Icons.check_circle,
                                  color: Colors.green)),
                    ),
                    onChanged: (_) => _onFieldsChanged(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tecDetail,
                    maxLines: 3,
                    maxLength: 128,
                    decoration: const InputDecoration(
                      label: Text('Additional Details'),
                      hintText:
                          'Provide more information about this program...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                    onChanged: _isEditing ? (_) => _onFieldsChanged() : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Team Assignment',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Column(
                      children: [
                        if (_selectedUsers.isEmpty)
                          Column(
                            children: [
                              Icon(Icons.person_add_alt_1,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              Text(
                                'No team members assigned',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6)),
                              ),
                            ],
                          )
                        else ...[
                          MyAvatarStack(
                            users: _appContext.allUsers
                                .where((e) => _selectedUsers.contains(e.id))
                                .toList(),
                            appDir: _appContext.appDir,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_selectedUsers.length} member${_selectedUsers.length == 1 ? '' : 's'} assigned',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _onManageMembersTap,
                          icon: const Icon(Icons.group),
                          label: Text(AppLocalizations.of(context)!
                              .selectUsersManageMembers),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Visibility Settings',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _forGuests,
                    onChanged: _onForGuestsChange,
                    title: const Text('Visible to Guests'),
                    subtitle:
                        const Text('Allow guests to see this program item'),
                    secondary: Icon(
                      _forGuests ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _canSave ? _onSaveClick : null,
            icon: const Icon(Icons.save),
            label: Text(_isEditing ? 'Update' : 'Save Program'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _onDeleteTap,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete Program',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required DateTime? time,
    required bool isRequired,
    required VoidCallback? onTap,
    required IconData icon,
    bool isEnabled = true,
  }) {
    final bool hasTime = time != null;
    final bool showWarning = isRequired && !hasTime;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: showWarning
                ? Colors.amber
                : isEnabled
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.5),
            width: showWarning ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isEnabled
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isEnabled
                      ? (showWarning
                          ? Colors.amber
                          : Theme.of(context).colorScheme.primary)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  label + (isRequired ? '*' : ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showWarning) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.warning_amber,
                      size: 14, color: Colors.amber),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasTime ? _timeFormat.format(time) : 'Tap to set',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isEnabled
                    ? (hasTime
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7))
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onManageMembersTap() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: List<String>.from(_selectedUsers),
          includeCurrentUser: true,
          allowTaskCheck: true,
          allowCreatePlaceholder: canCreatePlaceholderUser(
            actor: Provider.of<AppContext>(context, listen: false).currentUser,
            postAuthorUid: widget.eventContext.metadata.authorUID,
          ),
          postIdForPlaceholderCreate: widget.eventContext.id,
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (_isEditing) {
      if (_selectedUsers.toString() == result.toString()) return;
      setState(() {
        _selectedUsers
          ..clear()
          ..addAll(result);
      });
      _onFieldsChanged();
    } else {
      setState(() {
        _selectedUsers
          ..clear()
          ..addAll(result);
      });
    }
  }

  void _onForGuestsChange(final bool newState) {
    setState(() {
      _forGuests = newState;
    });
    if (_isEditing) _onFieldsChanged();
  }

  void _onFieldsChanged() {
    if (_isEditing) {
      _updateCanSaveForEdit();
    } else {
      _updateCanSaveForAdd();
    }
  }

  void _updateCanSaveForAdd() {
    if (_tecTitle.text.trim().isEmpty ||
        _start == null ||
        _end == null && _canSave) {
      setState(() {
        _canSave = false;
      });
    } else if (_tecTitle.text.trim().isNotEmpty &&
        _start != null &&
        _end != null &&
        !_canSave) {
      setState(() {
        _canSave = true;
      });
    }
  }

  void _updateCanSaveForEdit() {
    final entry = widget.programEntry!;
    if (_canSave &&
        (_areTimesTheSame() &&
            _tecDetail.text.trim().compareTo(entry['detail']) == 0 &&
            (_tecTitle.text.trim().compareTo(entry['title']) == 0 ||
                _tecTitle.text.trim().isEmpty)) &&
        _forGuests == entry['for_guests'] &&
        _selectedUsers
                .toString()
                .compareTo((entry['uids'] as List<String>).toString()) ==
            0) {
      setState(() {
        _canSave = false;
      });
    } else if (!_canSave) {
      setState(() {
        _canSave = true;
      });
    }
  }

  bool _areTimesTheSame() {
    final entry = widget.programEntry!;
    final originalStart = entry['start'] as DateTime;
    final originalEnd = entry['end'] as DateTime;
    return _start != null &&
        _end != null &&
        _start!.hour.compareTo(originalStart.hour) == 0 &&
        _start!.minute.compareTo(originalStart.minute) == 0 &&
        _end!.hour.compareTo(originalEnd.hour) == 0 &&
        _end!.minute.compareTo(originalEnd.minute) == 0;
  }

  void _onStartTimeTap() {
    showTimePicker(
            context: context,
            initialTime: _start != null
                ? TimeOfDay.fromDateTime(_start!)
                : widget.eventContext.head.startTimeOfEvent,
            helpText: 'When does the role start?')
        .then((selectedStartTime) async {
      if (selectedStartTime != null) {
        final DateTime newStart = DateTime(
            widget.eventContext.head.eventDate!.year,
            widget.eventContext.head.eventDate!.month,
            widget.eventContext.head.eventDate!.day,
            selectedStartTime.hour,
            selectedStartTime.minute);
        if (_end != null && _start != null) {
          final Duration duration = _end!.difference(_start!);
          setState(() {
            _start = newStart;
            _end = _start!.add(duration);
          });
          _onFieldsChanged();
        } else {
          setState(() {
            _start = newStart;
          });
          _onEndTimeTap();
        }
      }
    });
  }

  Future<void> _onEndTimeTap() async {
    final end = await showScheduleDurationPicker(
      context: context,
      start: _start!,
      initialEnd: _end,
    );
    if (end == null || !mounted) return;
    setState(() => _end = end);
    _onFieldsChanged();
  }

  Future<void> _onSaveClick() async {
    if (_isEditing) {
      await _saveEdit();
    } else {
      await _saveAdd();
    }
  }

  Future<void> _saveAdd() async {
    bool shiftFollowing = false;
    final int affectedCount =
        widget.eventContext.program.countRolesStartingAtOrAfter(_start!);
    if (affectedCount > 0) {
      final bool? choice = await DialogManager.askShiftFollowingScheduleItems(
        context: context,
        affectedCount: affectedCount,
      );
      if (choice == null || !mounted) return;
      shiftFollowing = choice;
    } else {
      final bool confirmed = await DialogManager.showConfirmationDialog(
        context: context,
        title: 'Save Program Details',
        content: 'Are you sure the details are correct?',
        confirmText: 'Save',
      );
      if (!confirmed || !mounted) return;
    }

    _addProgramRoleToEventContext(shiftFollowing: shiftFollowing);
    widget.eventContext.allowSavingOfTheEdit();
    _isSaved = true;
    _popRouteAfterAllowing();
  }

  void _addProgramRoleToEventContext({required bool shiftFollowing}) {
    final int id = DateTime.now().millisecondsSinceEpoch;
    debugPrint('sending the role addition to the following: $_selectedUsers');
    if (_selectedUsers.isNotEmpty) {
      widget.eventContext.addRoleAdditionNotification(_selectedUsers, id);
    }

    widget.eventContext.program.applyInsertShift(
      start: _start!,
      end: _end!,
      shiftFollowing: shiftFollowing,
    );
    widget.eventContext.program.addRole(
        uids: _selectedUsers,
        title: _tecTitle.text.trim(),
        detail: _tecDetail.text.trim(),
        start: _start,
        end: _end,
        forGuests: _forGuests,
        priority: 1,
        id: id);
    widget.eventContext.program.orderProgramsByStartTime();
  }

  Future<void> _saveEdit() async {
    final entry = widget.programEntry!;
    bool shiftFollowing = false;
    if (!_areTimesTheSame()) {
      final DateTime oldEnd = entry['end'] as DateTime;
      final int affectedCount = widget.eventContext.program
          .countRolesStartingAtOrAfter(oldEnd,
              excludeRoleId: entry['id'] as int);
      if (affectedCount > 0) {
        final bool? choice = await DialogManager.askShiftFollowingScheduleItems(
          context: context,
          affectedCount: affectedCount,
        );
        if (choice == null || !mounted) return;
        shiftFollowing = choice;
      } else {
        final bool confirmed = await DialogManager.showConfirmationDialog(
          context: context,
          title: 'Save Program Details',
          content: 'Are you sure the details are correct?',
          confirmText: 'Save',
        );
        if (!confirmed || !mounted) return;
      }
    } else {
      final bool confirmed = await DialogManager.showConfirmationDialog(
        context: context,
        title: 'Save Program Details',
        content: 'Are you sure the details are correct?',
        confirmText: 'Save',
      );
      if (!confirmed || !mounted) return;
    }

    _saveAllChanges(shiftFollowing: shiftFollowing);
    widget.eventContext.allowSavingOfTheEdit();
    _isSaved = true;
    _popRouteAfterAllowing();
  }

  void _saveAllChanges({required bool shiftFollowing}) {
    final entry = widget.programEntry!;
    _sortNotifications();
    entry['uids'] = _selectedUsers;
    entry['detail'] = _tecDetail.text.trim();
    entry['title'] = _tecTitle.text.trim();
    entry['for_guests'] = _forGuests;
    entry['priority'] = 1;
    widget.eventContext.program.updateRoleTiming(
      roleId: entry['id'] as int,
      newStart: _start!,
      newEnd: _end!,
      shiftFollowing: shiftFollowing,
    );
  }

  void _sortNotifications() {
    final entry = widget.programEntry!;
    final List<String> originalList = List<String>.from(entry['uids']);

    final removedMembers =
        originalList.where((e) => !_selectedUsers.contains(e));
    debugPrint('Sending role removal to the following: $removedMembers');
    if (removedMembers.isNotEmpty) {
      widget.eventContext
          .addRoleRemovalNotification(removedMembers, entry['id']);
    }

    final newMembers = _selectedUsers.where((e) => !originalList.contains(e));
    debugPrint('Sending role addition to the following: $newMembers');
    if (newMembers.isNotEmpty) {
      widget.eventContext.addRoleAdditionNotification(newMembers, entry['id']);
    }
    debugPrint(
        '--------role addition now looks like: ${widget.eventContext.roleAdditions}');
  }

  Future<void> _onDeleteTap() async {
    final entry = widget.programEntry!;
    final confirmation = await DialogManager.showConfirmationDialog(
        context: context,
        title: 'Delete Schedule Item',
        content: 'Are you sure you want to delete this item?');
    if (!confirmation || !mounted) return;

    widget.eventContext.removeRoleAdditionNotification(entry['id']);
    widget.eventContext.addRoleRemovalNotification(entry['uids'], entry['id']);
    widget.eventContext.addRoleDeletionTitle(entry['id'], entry['title']);

    widget.eventContext.program.removeRole(entry['id']);
    widget.eventContext.allowSavingOfTheEdit();

    _isSaved = true;
    _popRouteAfterAllowing();
  }
}
