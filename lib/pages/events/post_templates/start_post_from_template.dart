import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/post_template.dart';
import '../../../utility/app_context.dart';
import '../../../utility/bulk_post_dates.dart';
import '../../../utility/cell_group_meeting_setup.dart';
import '../../../utility/post_template_mapper.dart';
import '../../../widgets/posts/schedule_preset_picker.dart';
import '../add_event_page.dart';

/// Date (when the template is dated), optional schedule preset, then [AddEventPage].
///
/// Returns true when the new-post page was opened. [parentID] is the new post's
/// parent. [ensureCellGroupIDs] are merged onto the template's cell groups so a
/// meeting started from a group page still appears in that group's trail.
/// [popParentRouteOnSave] closes the route under the new-post page after save
/// (the template picker). Direct opens pass false.
Future<bool> startPostFromTemplate({
  required BuildContext context,
  required PostTemplate template,
  String? parentID,
  Iterable<String> ensureCellGroupIDs = const [],
  bool popParentRouteOnSave = true,
}) async {
  final appContext = Provider.of<AppContext>(context, listen: false);

  final shouldPickDate = template.startTime != null ||
      template.defaultDayOfWeek != null ||
      template.schedulePresets.any((preset) => preset.startTime != null);
  DateTime? selectedDate;
  if (shouldPickDate) {
    selectedDate = await _selectDate(
      context,
      preferredDayOfWeek: template.defaultDayOfWeek,
    );
    if (selectedDate == null || !context.mounted) return false;
  }

  SchedulePreset? schedulePreset;
  if (template.schedulePresets.length > 1) {
    schedulePreset = await showSchedulePresetPicker(
      context: context,
      presets: template.schedulePresets,
      title: 'Schedule preset',
      subtitle: 'Choose the running order for this post',
    );
    if (schedulePreset == null || !context.mounted) return false;
  }

  final eventContext = PostTemplateMapper.mapTemplateToEventContext(
    template: template,
    currentUserID: appContext.currentUser.id,
    parentID: parentID,
    allUsers: appContext.allUsers,
    schedulePreset: schedulePreset,
  );
  eventContext.applyCellGroupIDs(
    CellGroupMeetingSetup.cellGroupIdsForNewMeeting(
      templateCellGroupIDs: eventContext.head.cellGroupIDs,
      extraCellGroupIDs: ensureCellGroupIDs,
    ),
  );

  if (selectedDate != null) {
    PostTemplateMapper.adjustEventProgramToDate(eventContext, selectedDate);
  }
  if (!context.mounted) return false;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AddEventPage(
        eventContext: eventContext,
        popParentRouteOnSave: popParentRouteOnSave,
      ),
    ),
  );
  return true;
}

Future<DateTime?> _selectDate(
  final BuildContext context, {
  final int? preferredDayOfWeek,
}) async {
  final now = DateTime.now();
  final firstDate = now.subtract(const Duration(days: 30));
  final lastDate = now.add(const Duration(days: 60));
  var initialDate = preferredDayOfWeek != null
      ? nextDateForDayOfWeek(dayOfWeek: preferredDayOfWeek, now: now)
      : now;
  if (initialDate.isBefore(firstDate)) initialDate = firstDate;
  if (initialDate.isAfter(lastDate)) initialDate = lastDate;
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}
