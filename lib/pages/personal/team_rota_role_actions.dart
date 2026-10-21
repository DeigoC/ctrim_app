import 'package:flutter/material.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/functions_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/event/event_program.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_heads_repository.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../utility/team_rota.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../widgets/posts/schedule_role_detail_sheet.dart';
import 'select_users_page.dart';

/// Claim, release, and assign people on a ministry-schedule slot.
///
/// Both the list and the event schedule page use this. Time, ministry, and
/// order stay on the post.
class TeamRotaRoleActions {
  TeamRotaRoleActions({
    required this.context,
    required this.appContext,
    required this.onProgramUpdated,
  });

  final BuildContext context;
  final AppContext appContext;

  /// Called with the programme returned after a successful assignee write.
  final void Function(String postId, EventProgram program) onProgramUpdated;

  Future<void> openRole({
    required EventHead head,
    required Map<String, dynamic> role,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final actor = appContext.currentUser;
    final canAssign = TeamRotaQuery.canAssignRole(
      actor: actor,
      role: role,
      eventDate: head.eventDate,
      locationId: VolunteerLocations.idForName(
        locations: appContext.allLocations,
        name: head.location,
      ),
      allTags: appContext.allTags,
      now: now,
    );
    final canClaim = TeamRotaQuery.canClaimRole(
      actor: actor,
      role: role,
      eventDate: head.eventDate,
      now: now,
    );
    final onIt = TeamRotaQuery.isAssignedTo(role, actor.id);
    if (!context.mounted) return;
    await showScheduleRoleDetailSheet(
      context: context,
      role: role,
      assignedUsers: _assignedUsers(role),
      canEdit: canAssign,
      editLabel: l10n.teamRotaAssignPeople,
      onEdit: () {
        Navigator.of(context).pop();
        _assignPeople(head, role);
      },
      claimLabel:
          canClaim ? (onIt ? l10n.teamRotaRelease : l10n.teamRotaClaim) : null,
      onClaim: canClaim
          ? () {
              Navigator.of(context).pop();
              _claimOrRelease(head, role, release: onIt);
            }
          : null,
    );
  }

  Future<bool> _confirmSharedSlot(
    Map<String, dynamic> role,
    String confirmText,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final tagIds = EventProgram.tagIDsOf(role);
    if (tagIds.length <= 1) return true;
    final names = UserTagHelpers.resolveTags(
      tagIDs: tagIds,
      allTags: appContext.allTags,
    ).map((tag) => tag.name).join(', ');
    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: l10n.teamRotaSharedSlotTitle,
      content: names.isEmpty
          ? l10n.teamRotaSharedSlotBodyGeneric
          : l10n.teamRotaSharedSlotBody(names),
      confirmText: confirmText,
    );
    return confirmed && context.mounted;
  }

  Future<void> _assignPeople(
    EventHead head,
    Map<String, dynamic> role,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _confirmSharedSlot(role, l10n.teamRotaAssignPeople)) return;
    if (!context.mounted) return;

    final location = VolunteerLocations.normalizePostLocation(head.location);
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: TeamRotaQuery.uidsOf(role),
          includeCurrentUser: true,
          title: l10n.teamRotaAssignPeople,
          allowCreatePlaceholder: canCreatePlaceholderUser(
            actor: appContext.currentUser,
          ),
          initialLocation: location.isEmpty ? null : location,
          initialTagIDs: EventProgram.tagIDsOf(role),
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    await _saveRoleAssignees(head, role, result);
  }

  Future<void> _claimOrRelease(
    EventHead head,
    Map<String, dynamic> role, {
    required bool release,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = release ? l10n.teamRotaRelease : l10n.teamRotaClaim;
    if (!await _confirmSharedSlot(role, confirm)) return;
    if (!context.mounted) return;

    final uid = appContext.currentUser.id;
    final next = List<String>.from(TeamRotaQuery.uidsOf(role));
    if (release) {
      next.remove(uid);
    } else if (!next.contains(uid)) {
      next.add(uid);
    }
    await _saveRoleAssignees(head, role, next);
  }

  Future<void> _saveRoleAssignees(
    EventHead head,
    Map<String, dynamic> role,
    List<String> uids,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (TeamRotaQuery.sameAssigneeIds(TeamRotaQuery.uidsOf(role), uids)) {
      return;
    }
    final roleId = role['id'];
    if (roleId is! int) return;

    await DialogManager.runWithProgressDialog(
      context: context,
      title: l10n.teamRotaSavingAssignees,
      errorTitle: l10n.teamRotaCouldNotSave,
      action: () async {
        final editorUid = appContext.currentUser.id;
        final now = DateTime.now();
        final written =
            await EventSupplementalDBManager(head.id).updateRoleAssignees(
          roleId: roleId,
          uids: uids,
          editorUid: editorUid,
          now: now,
        );
        if (written == null) {
          throw Exception(l10n.teamRotaRoleMissing);
        }
        onProgramUpdated(head.id, written.program);
        final log = written.log;
        if (log == null) return;
        await _afterAssigneesSaved(
          head: head,
          log: log,
          editorUid: editorUid,
          now: now,
          removedUids: written.removedUids,
        );
      },
    );
  }

  /// Follow-ups the post editor also runs after a save. All fail soft: the
  /// lineup is already written.
  Future<void> _afterAssigneesSaved({
    required EventHead head,
    required String log,
    required String editorUid,
    required DateTime now,
    required List<String> removedUids,
  }) async {
    head.setRecentDate(now);
    if (appContext.headById(head.id) != null) {
      appContext.addOrUpdatePostHead(head);
      try {
        await persistEventHeadsLocalCache(List.of(appContext.eventHeads));
      } catch (e) {
        debugPrint('Could not persist event heads after rota save: $e');
      }
    }
    await Future.wait([
      UserActivityRecorder().record(
        actorUserId: editorUid,
        log: UserActivityMessages.updatedMinistrySchedule,
        documentId: head.id,
        title: head.title,
        note: log,
      ),
      if (head.eventDate != null)
        CloudFunctionManager().syncUserRolesForPost(
          postId: head.id,
          removedUserIds: removedUids,
        ),
    ]);
  }

  List<User> _assignedUsers(Map<String, dynamic> role) {
    final users = <User>[];
    for (final id in TeamRotaQuery.uidsOf(role)) {
      final user = appContext.userById(id);
      if (user != null) users.add(user);
    }
    return users;
  }
}
