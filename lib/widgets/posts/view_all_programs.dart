import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/user.dart';
import '../../pages/events/edit_event_date_location_page.dart';
import '../../pages/events/edit_program_role_page.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import 'program_tile.dart';

class ViewAllPrograms extends StatefulWidget {
  const ViewAllPrograms({
    super.key,
    required this.eventContext,
    required this.onProgramChanged,
    this.isAddingPost = false,
    this.timeOnlySchedule = false,
  });
  final EventContext eventContext;
  final Function onProgramChanged;
  final bool isAddingPost;

  /// Post templates: show typical time only; calendar date is set when creating posts.
  final bool timeOnlySchedule;

  @override
  State<ViewAllPrograms> createState() => _ViewAllProgramsPageState();
}

class _ViewAllProgramsPageState extends State<ViewAllPrograms> {
  static final DateFormat _startFormat = DateFormat('EEEE d MMM yyyy');
  static final DateFormat _startFormatAllDay = DateFormat('EEEE d MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  late final AppContext _appContext;
  int? _selectedIndex;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget.eventContext.program.orderProgramsByStartTime();
    if (widget.eventContext.head.eventDate != null) {
      return _buildBodyWithEventDate();
    }
    return SingleChildScrollView(child: _buildEventDateSelector());
  }

  Widget _buildBodyWithEventDate() {
    final List<Map<String, dynamic>> programRoles =
        List<Map<String, dynamic>>.from(_appContext.isCurrentUserGuest
            ? widget.eventContext.program.roles.where((e) => e['for_guests'])
            : widget.eventContext.program.roles);

    final List<Widget> children = [
      Expanded(
          child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildEventDateSelector()),
        SliverList.separated(
          itemCount: programRoles.length,
          itemBuilder: (_, index) {
            final DateTime roleStart = programRoles[index]['start'];
            final bool canEdit =
                (widget.eventContext.isUserAuthor(_appContext.currentUser.id) ||
                        widget.eventContext
                            .isUserContributor(_appContext.currentUser.id)) &&
                    DateTime.now().isBefore(roleStart);
            final bool editable = _canEditPostProgram() ? true : canEdit;

            return ProgramTile(
              programEntry: programRoles[index],
              onTap: (tapContext) => _programTap(tapContext, index),
              selected: _selectedIndex == index,
              assignedUsers: (programRoles[index]["uids"] as List<String>)
                  .map((e) => _appContext.userById(e))
                  .whereType<User>()
                  .toList(),
              canEdit: editable,
              onEditClick: () => _openEditProgramPage(programRoles[index]),
              canMoveUp: editable && index > 0,
              canMoveDown: editable && index < programRoles.length - 1,
              onMoveUp: () => _moveRole(programRoles[index]['id'] as int, -1),
              onMoveDown: () => _moveRole(programRoles[index]['id'] as int, 1),
            );
          },
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
        )
      ]))
    ];

    return SafeArea(top: false, child: Column(children: children));
  }

  Widget _buildEventDateSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String dateStr =
        widget.timeOnlySchedule ? 'No start time set' : 'No Date Selected';
    String timeStr = '';
    if (widget.eventContext.head.eventDate != null) {
      if (widget.timeOnlySchedule) {
        if (widget.eventContext.program.allDay) {
          dateStr = 'All day';
          timeStr = 'Calendar date is chosen when creating a post';
        } else {
          dateStr = 'Typical time';
          final finish = widget.eventContext.program.finishTime;
          timeStr = finish == null
              ? _timeFormat.format(widget.eventContext.head.eventDate!)
              : 'From ${_timeFormat.format(widget.eventContext.head.eventDate!)} to ${_timeFormat.format(finish)}';
        }
      } else if (widget.eventContext.program.allDay) {
        dateStr =
            "${_startFormatAllDay.format(widget.eventContext.head.eventDate!)} (All Day)";
      } else {
        dateStr = _startFormat.format(widget.eventContext.head.eventDate!);
        timeStr =
            'From ${_timeFormat.format(widget.eventContext.head.eventDate!)} to ${_timeFormat.format(widget.eventContext.program.finishTime!)}';
      }
    } else if (widget.timeOnlySchedule) {
      timeStr = 'Tap to set typical time & location';
    }

    final List<Widget> children = [
      Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            ListTile(
                title: Text(dateStr,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: timeStr.isNotEmpty ? Text(timeStr) : null,
                leading: Icon(
                  widget.timeOnlySchedule
                      ? Icons.schedule
                      : Icons.calendar_month,
                  color: colorScheme.primary,
                )),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
                title: Text(widget.eventContext.head.location,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  widget.eventContext.program.address,
                  maxLines: null,
                ),
                trailing: _buildLocationTrailingIcon(),
                leading: Icon(Icons.map, color: colorScheme.primary)),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ];

    children.add(const SizedBox(height: 8));
    children.add(const Divider(thickness: 1));

    return InkWell(
        onTap: _canEditPostProgram() ? _onEditPostProgram : null,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children));
  }

  void _programTap(final Map<String, dynamic> programEntry, final int index) {
    setState(() {
      if (_selectedIndex != index) {
        _selectedIndex = index;
      } else {
        _selectedIndex = null;
      }
    });
  }

  void _moveRole(final int roleId, final int direction) {
    final bool moved =
        widget.eventContext.program.moveRoleInOrder(roleId, direction);
    if (!moved) return;

    widget.eventContext.allowSavingOfTheEdit();
    final int newIndex = widget.eventContext.program.indexOfRole(roleId);
    setState(() {
      _selectedIndex = newIndex >= 0 ? newIndex : null;
    });
    widget.onProgramChanged();
  }

  Widget? _buildLocationTrailingIcon() {
    if (!widget.eventContext.program.hasLocationLaunchUrl) {
      return null;
    }
    if (widget.eventContext.program.online) {
      return FilledButton.tonal(
        onPressed: _onClickLocationTrailingIcon,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam, size: 16),
            SizedBox(width: 4),
            Text('Join'),
          ],
        ),
      );
    }
    return FilledButton.tonal(
      onPressed: _onClickLocationTrailingIcon,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map, size: 16),
          SizedBox(width: 4),
          Text('Maps'),
        ],
      ),
    );
  }

  // * LOGIC
  bool _canEditPostProgram() {
    if (widget.isAddingPost ||
        widget.eventContext.isUserAuthor(_appContext.currentUser.id) ||
        widget.eventContext.isUserContributor(_appContext.currentUser.id)) {
      return true;
    }
    return DateTime.now().isBefore(widget.eventContext.head.eventDate ??
            DateTime.now().subtract(const Duration(days: 1))) &&
        (widget.eventContext.isUserAuthor(_appContext.currentUser.id) ||
            widget.eventContext.isUserContributor(_appContext.currentUser.id));
  }

  void _openEditProgramPage(final Map<String, dynamic> programEntry) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EditEventProgramPage(
                  eventContext: widget.eventContext,
                  programEntry: programEntry,
                ))).then((_) {
      setState(() {
        // rebuild in case of update
      });
      if (widget.eventContext.canSaveTheEditing) {
        widget.onProgramChanged();
      }
    });
  }

  void _onClickLocationTrailingIcon() {
    final String link = widget.eventContext.program.locationLaunchUrl.trim();
    if (link.isEmpty) return;
    launchUrlString(link, mode: LaunchMode.externalApplication)
        .onError((error, stackTrace) async {
      debugPrint('error with link: $link');
      if (!mounted) return false;
      DialogManager.showAlertDialog(
          context: context,
          title: 'Error!',
          content:
              'Attempted to open the following link:\n\n$link. \n\nError message: $error');
      return false; // ???
    }).then((success) {
      if (!success && mounted) {
        DialogManager.showAlertDialog(
            context: context,
            title: 'Error!',
            content: 'Attempted to open the following link:\n\n$link');
      }
    });
  }

  void _onEditPostProgram() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditEventDateLocationPage(
          eventContext: widget.eventContext,
          timeOnly: widget.timeOnlySchedule,
        ),
      ),
    ).then((_) {
      widget.eventContext.program.orderProgramsByStartTime();
      setState(() {});
      if (widget.eventContext.canSaveTheEditing) {
        widget.onProgramChanged();
      }
    });
  }
}
