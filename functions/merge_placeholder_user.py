"""Merge a placeholder volunteer profile into an existing non-placeholder user.

Area/global admins only. Rewrites stored volunteer document IDs across
events, templates, cell groups, church info, ministry heads, and user
indexes so posts and rosters keep working without hand-editing each record.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from firebase_functions import https_fn

from placeholder_users import (
    _everyone_flags,
    _is_area_or_global_admin,
    _require_auth,
)
from user_role_sync import sync_post_program_roles


def _effective_is_placeholder(data: dict) -> bool:
    auth = str(data.get('AuthID', '')).strip()
    if auth:
        return False
    return data.get('IsPlaceholder') is True


def _replace_uid_in_list(values: Any, old: str, new: str) -> list[str]:
    result: list[str] = []
    seen: set[str] = set()
    for raw in values or []:
        uid = str(raw).strip()
        if not uid:
            continue
        if uid == old:
            uid = new
        if uid in seen:
            continue
        seen.add(uid)
        result.append(uid)
    return result


def _replace_uid_string(value: Any, old: str, new: str) -> str:
    uid = str(value or '').strip()
    if uid == old:
        return new
    return uid


def _roles_key(data: dict) -> str | None:
    if isinstance(data.get('Roles'), list):
        return 'Roles'
    if isinstance(data.get('roles'), list):
        return 'roles'
    return None


def rewrite_program_roles(data: dict, old: str, new: str) -> tuple[dict, bool]:
    key = _roles_key(data)
    if key is None:
        return data, False
    roles = data.get(key) or []
    changed = False
    next_roles = []
    for role in roles:
        if not isinstance(role, dict):
            next_roles.append(role)
            continue
        uids = role.get('uids')
        if not isinstance(uids, list):
            next_roles.append(role)
            continue
        rewritten = _replace_uid_in_list(uids, old, new)
        if rewritten != [str(x).strip() for x in uids if str(x).strip()]:
            changed = True
            next_roles.append({**role, 'uids': rewritten})
        else:
            next_roles.append(role)
    if not changed:
        return data, False
    return {**data, key: next_roles}, True


def rewrite_metadata(data: dict, old: str, new: str) -> tuple[dict, bool]:
    out = dict(data)
    changed = False

    for key in ('AuthorUID', 'LastUID', 'LeadSpeakerUID'):
        if key not in out:
            continue
        rewritten = _replace_uid_string(out.get(key), old, new)
        if rewritten != str(out.get(key) or '').strip():
            out[key] = rewritten
            changed = True

    for key in ('ContributorUIDs', 'LeadSpeakerUIDs'):
        if key not in out:
            continue
        original = out.get(key) or []
        rewritten = _replace_uid_in_list(original, old, new)
        if rewritten != [str(x).strip() for x in original if str(x).strip()]:
            out[key] = rewritten
            changed = True

    return out, changed


def rewrite_lead_speakers_head(
    data: dict,
    old: str,
    new: str,
    *,
    survivor_name: str = '',
    survivor_img: str = '',
) -> tuple[dict, bool]:
    out = dict(data)
    changed = False

    if 'LeadSpeakerUID' in out:
        rewritten = _replace_uid_string(out.get('LeadSpeakerUID'), old, new)
        if rewritten != str(out.get('LeadSpeakerUID') or '').strip():
            out['LeadSpeakerUID'] = rewritten
            if rewritten == new and survivor_name:
                out['LeadSpeakerName'] = survivor_name
            if rewritten == new and survivor_img:
                out['LeadSpeakerImgSrc'] = survivor_img
            changed = True

    speakers = out.get('LeadSpeakers')
    if isinstance(speakers, list):
        remapped = []
        speakers_changed = False
        for speaker in speakers:
            if not isinstance(speaker, dict):
                remapped.append(speaker)
                continue
            uid = str(speaker.get('UID', '')).strip()
            if uid != old:
                remapped.append(speaker)
                continue
            speakers_changed = True
            updated = {**speaker, 'UID': new}
            if survivor_name:
                updated['Name'] = survivor_name
            if survivor_img:
                updated['ImgSrc'] = survivor_img
            remapped.append(updated)

        next_speakers = []
        seen_uids: set[str] = set()
        for speaker in remapped:
            if not isinstance(speaker, dict):
                next_speakers.append(speaker)
                continue
            uid = str(speaker.get('UID', '')).strip()
            if uid and uid in seen_uids:
                speakers_changed = True
                continue
            if uid:
                seen_uids.add(uid)
            next_speakers.append(speaker)

        if speakers_changed:
            out['LeadSpeakers'] = next_speakers
            changed = True

    return out, changed


def rewrite_attendance(
    data: dict,
    old: str,
    new: str,
    *,
    survivor_display_name: str = '',
) -> tuple[dict, bool]:
    out = dict(data)
    changed = False

    for key in ('expectedUserIds', 'ExpectedAttendeeUserIDs'):
        if key not in out:
            continue
        original = out.get(key) or []
        rewritten = _replace_uid_in_list(original, old, new)
        if rewritten != [str(x).strip() for x in original if str(x).strip()]:
            out[key] = rewritten
            changed = True

    attendees = out.get('attendees')
    if isinstance(attendees, list):
        next_attendees = []
        attendees_changed = False
        seen_user_ids: set[str] = set()
        for attendee in attendees:
            if not isinstance(attendee, dict):
                next_attendees.append(attendee)
                continue
            updated = dict(attendee)
            row_changed = False

            user_id = str(updated.get('userId', '')).strip()
            if user_id == old:
                updated['userId'] = new
                updated['id'] = f'user_{new}'
                if survivor_display_name:
                    updated['displayName'] = survivor_display_name
                row_changed = True
                user_id = new

            added_by = str(updated.get('addedBy', '')).strip()
            if added_by == old:
                updated['addedBy'] = new
                row_changed = True

            attendee_id = str(updated.get('id', '')).strip()
            if attendee_id == f'user_{old}':
                updated['id'] = f'user_{new}'
                row_changed = True

            if user_id and updated.get('type') == 'user':
                if user_id in seen_user_ids:
                    attendees_changed = True
                    continue
                seen_user_ids.add(user_id)

            if row_changed:
                attendees_changed = True
            next_attendees.append(updated)

        if attendees_changed:
            out['attendees'] = next_attendees
            changed = True

    interested = out.get('interested')
    if isinstance(interested, dict):
        next_interested = {}
        interested_changed = False
        for key, entry in interested.items():
            if not isinstance(entry, dict):
                next_interested[key] = entry
                continue
            updated = dict(entry)
            if str(updated.get('userId', '')).strip() == old:
                updated['userId'] = new
                if survivor_display_name:
                    updated['displayName'] = survivor_display_name
                interested_changed = True
            next_interested[key] = updated
        if interested_changed:
            out['interested'] = next_interested
            changed = True

    return out, changed


def rewrite_event_logs(data: dict, old: str, new: str) -> tuple[dict, bool]:
    logs = data.get('Logs')
    if not isinstance(logs, list):
        return data, False
    changed = False
    next_logs = []
    for log in logs:
        if not isinstance(log, dict):
            next_logs.append(log)
            continue
        uid = str(log.get('uid', '')).strip()
        if uid != old:
            next_logs.append(log)
            continue
        changed = True
        next_logs.append({**log, 'uid': new})
    if not changed:
        return data, False
    return {**data, 'Logs': next_logs}, True


def rewrite_template(data: dict, old: str, new: str) -> tuple[dict, bool]:
    out = dict(data)
    changed = False

    roles_data, roles_changed = rewrite_program_roles(out, old, new)
    if roles_changed:
        out = roles_data
        changed = True

    for key in ('ExpectedAttendeeUserIDs', 'Contributors', 'LeadSpeakerUIDs'):
        if key not in out:
            continue
        original = out.get(key) or []
        rewritten = _replace_uid_in_list(original, old, new)
        if rewritten != [str(x).strip() for x in original if str(x).strip()]:
            out[key] = rewritten
            changed = True

    if 'LeadSpeakerUID' in out:
        rewritten = _replace_uid_string(out.get('LeadSpeakerUID'), old, new)
        if rewritten != str(out.get('LeadSpeakerUID') or '').strip():
            out['LeadSpeakerUID'] = rewritten
            changed = True

    presets = out.get('SchedulePresets')
    if isinstance(presets, list):
        next_presets = []
        presets_changed = False
        for preset in presets:
            if not isinstance(preset, dict):
                next_presets.append(preset)
                continue
            rewritten_preset, preset_changed = rewrite_program_roles(preset, old, new)
            if preset_changed:
                presets_changed = True
                next_presets.append(rewritten_preset)
            else:
                next_presets.append(preset)
        if presets_changed:
            out['SchedulePresets'] = next_presets
            changed = True

    expected_presets = out.get('ExpectedAttendancePresets')
    if isinstance(expected_presets, list):
        next_expected = []
        expected_changed = False
        for preset in expected_presets:
            if not isinstance(preset, dict):
                next_expected.append(preset)
                continue
            original = preset.get('userIds') or []
            rewritten = _replace_uid_in_list(original, old, new)
            if rewritten != [str(x).strip() for x in original if str(x).strip()]:
                expected_changed = True
                next_expected.append({**preset, 'userIds': rewritten})
            else:
                next_expected.append(preset)
        if expected_changed:
            out['ExpectedAttendancePresets'] = next_expected
            changed = True

    logs_data, logs_changed = rewrite_event_logs(out, old, new)
    if logs_changed:
        out = logs_data
        changed = True

    return out, changed


def rewrite_cell_group(
    data: dict,
    old: str,
    new: str,
    *,
    survivor_auth_id: str = '',
) -> tuple[dict, bool]:
    out = dict(data)
    changed = False

    if 'CreatedByUserID' in out:
        rewritten = _replace_uid_string(out.get('CreatedByUserID'), old, new)
        if rewritten != str(out.get('CreatedByUserID') or '').strip():
            out['CreatedByUserID'] = rewritten
            changed = True

    if 'LeaderUserIds' in out:
        original = out.get('LeaderUserIds') or []
        rewritten = _replace_uid_in_list(original, old, new)
        if rewritten != [str(x).strip() for x in original if str(x).strip()]:
            out['LeaderUserIds'] = rewritten
            changed = True
            # Rebuild auth ids from known survivor auth when placeholder was a leader.
            auth_ids = [
                str(x).strip()
                for x in (out.get('LeaderAuthIds') or [])
                if str(x).strip()
            ]
            # Keep existing auth ids; ensure survivor auth is present if they lead.
            if survivor_auth_id and new in rewritten and survivor_auth_id not in auth_ids:
                auth_ids.append(survivor_auth_id)
                out['LeaderAuthIds'] = auth_ids

    return out, changed


def rewrite_roster(
    data: dict,
    old: str,
    new: str,
    *,
    survivor_display_name: str = '',
) -> tuple[dict, bool]:
    members = data.get('Members')
    if not isinstance(members, list):
        return data, False

    next_members = []
    changed = False
    seen: set[str] = set()
    for member in members:
        if not isinstance(member, dict):
            next_members.append(member)
            continue
        uid = str(member.get('UserId', '')).strip()
        if uid == old:
            uid = new
            changed = True
            member = {**member, 'UserId': new}
            if survivor_display_name:
                member = {**member, 'DisplayName': survivor_display_name}
        if uid and uid in seen:
            changed = True
            continue
        if uid:
            seen.add(uid)
        next_members.append(member)

    if not changed:
        return data, False
    return {**data, 'Members': next_members}, True


def rewrite_heads_by_location(data: dict, old: str, new: str) -> tuple[dict, bool]:
    heads = data.get('HeadsByLocation')
    if not isinstance(heads, dict):
        return data, False
    next_heads = {}
    changed = False
    for location, ids in heads.items():
        rewritten = _replace_uid_in_list(ids, old, new)
        original = [str(x).strip() for x in (ids or []) if str(x).strip()]
        if rewritten != original:
            changed = True
        next_heads[location] = rewritten
    if not changed:
        return data, False
    return {**data, 'HeadsByLocation': next_heads}, True


def merge_role_lists(existing: list, incoming: list) -> list:
    """Union role rows by (postID, id). Prefer existing when both present."""
    result = list(existing or [])
    seen = {
        (str(row.get('postID', '')), row.get('id'))
        for row in result
        if isinstance(row, dict)
    }
    for row in incoming or []:
        if not isinstance(row, dict):
            continue
        key = (str(row.get('postID', '')), row.get('id'))
        if key in seen:
            continue
        seen.add(key)
        result.append(row)
    return result


def merge_post_lists(existing: list, incoming: list) -> list:
    result = list(existing or [])
    seen = {
        str(row.get('id', '')).strip()
        for row in result
        if isinstance(row, dict) and str(row.get('id', '')).strip()
    }
    for row in incoming or []:
        if not isinstance(row, dict):
            continue
        post_id = str(row.get('id', '')).strip()
        if not post_id or post_id in seen:
            continue
        seen.add(post_id)
        result.append(row)
    return result


def merge_activity_logs(existing: list, incoming: list) -> list:
    result = list(existing or [])
    seen = set()
    for row in result:
        if not isinstance(row, dict):
            continue
        seen.add(
            (
                str(row.get('log', '')),
                str(row.get('documentId', '')),
                str(row.get('ts', '')),
            )
        )
    for row in incoming or []:
        if not isinstance(row, dict):
            continue
        key = (
            str(row.get('log', '')),
            str(row.get('documentId', '')),
            str(row.get('ts', '')),
        )
        if key in seen:
            continue
        seen.add(key)
        result.append(row)
    return result


def rewrite_activity_document_ids(data: dict, old: str, new: str) -> tuple[dict, bool]:
    logs = data.get('Logs')
    if not isinstance(logs, list):
        return data, False
    changed = False
    next_logs = []
    for log in logs:
        if not isinstance(log, dict):
            next_logs.append(log)
            continue
        doc_id = str(log.get('documentId', '')).strip()
        if doc_id != old:
            next_logs.append(log)
            continue
        changed = True
        next_logs.append({**log, 'documentId': new})
    if not changed:
        return data, False
    return {**data, 'Logs': next_logs}, True


def _touch_tracker(db, doc_id: str) -> None:
    now_ms = int(datetime.now(timezone.utc).timestamp() * 1000)
    db.collection('id_tracker').document(doc_id).set(
        {'lastUpdate': now_ms},
        merge=True,
    )


def _delete_user_tree(db, user_id: str) -> None:
    user_ref = db.collection('users').document(user_id)
    for snap in user_ref.collection('supplemental').stream():
        snap.reference.delete()
    user_ref.delete()


def merge_placeholder_into_user_impl(db, req: https_fn.CallableRequest) -> dict:
    auth_uid = _require_auth(req)
    flags = _everyone_flags(db, auth_uid)
    if not _is_area_or_global_admin(flags):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message='Area admin required',
        )

    data = req.data or {}
    placeholder_id = str(data.get('PlaceholderUserID', '')).strip()
    survivor_id = str(data.get('SurvivorUserID', '')).strip()
    dry_run = data.get('DryRun') is True

    if not placeholder_id or not survivor_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message='PlaceholderUserID and SurvivorUserID are required',
        )
    if placeholder_id == survivor_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message='Placeholder and survivor must be different people',
        )

    placeholder_ref = db.collection('users').document(placeholder_id)
    survivor_ref = db.collection('users').document(survivor_id)
    placeholder_snap = placeholder_ref.get()
    survivor_snap = survivor_ref.get()

    if not placeholder_snap.exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message='Placeholder user not found',
        )
    if not survivor_snap.exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message='Target user not found',
        )

    placeholder = placeholder_snap.to_dict() or {}
    survivor = survivor_snap.to_dict() or {}

    if not _effective_is_placeholder(placeholder):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message='Source profile is not a placeholder',
        )
    if _effective_is_placeholder(survivor):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message='Target must be an existing non-placeholder profile',
        )

    survivor_name = (
        f"{survivor.get('Forename', '')} {survivor.get('Surname', '')}".strip()
    )
    survivor_img = str(survivor.get('ImgSrc', '') or '')
    survivor_auth = str(survivor.get('AuthID', '') or '').strip()

    updated = {
        'events_program_roles': 0,
        'events_metadata': 0,
        'events_head_lead_speakers': 0,
        'events_attendance': 0,
        'events_logs': 0,
        'users_created_by': 0,
        'users_activity_document_ids': 0,
        'users_supplemental_merged': False,
        'cell_groups': 0,
        'cell_group_rosters': 0,
        'post_templates': 0,
        'church_pastor_user_ids': 0,
        'church_updated_by': 0,
        'user_tags_heads': 0,
    }
    touched_post_ids: set[str] = set()

    # --- Events ---
    for event_snap in db.collection('events').stream():
        post_id = event_snap.id
        head = event_snap.to_dict() or {}
        head_out, head_changed = rewrite_lead_speakers_head(
            head,
            placeholder_id,
            survivor_id,
            survivor_name=survivor_name,
            survivor_img=survivor_img,
        )
        if head_changed:
            updated['events_head_lead_speakers'] += 1
            touched_post_ids.add(post_id)
            if not dry_run:
                event_snap.reference.set(head_out, merge=True)

        supplemental = event_snap.reference.collection('supplemental')

        program_snap = supplemental.document('program').get()
        if program_snap.exists:
            program = program_snap.to_dict() or {}
            program_out, program_changed = rewrite_program_roles(
                program, placeholder_id, survivor_id
            )
            if program_changed:
                updated['events_program_roles'] += 1
                touched_post_ids.add(post_id)
                if not dry_run:
                    program_snap.reference.set(program_out, merge=True)

        meta_snap = supplemental.document('metadata').get()
        if meta_snap.exists:
            meta = meta_snap.to_dict() or {}
            meta_out, meta_changed = rewrite_metadata(
                meta, placeholder_id, survivor_id
            )
            if meta_changed:
                updated['events_metadata'] += 1
                touched_post_ids.add(post_id)
                if not dry_run:
                    meta_snap.reference.set(meta_out, merge=True)

        attendance_snap = supplemental.document('attendance').get()
        if attendance_snap.exists:
            attendance = attendance_snap.to_dict() or {}
            attendance_out, attendance_changed = rewrite_attendance(
                attendance,
                placeholder_id,
                survivor_id,
                survivor_display_name=survivor_name,
            )
            if attendance_changed:
                updated['events_attendance'] += 1
                touched_post_ids.add(post_id)
                if not dry_run:
                    attendance_snap.reference.set(attendance_out, merge=True)

        logs_snap = supplemental.document('logs').get()
        if logs_snap.exists:
            logs = logs_snap.to_dict() or {}
            logs_out, logs_changed = rewrite_event_logs(
                logs, placeholder_id, survivor_id
            )
            if logs_changed:
                updated['events_logs'] += 1
                if not dry_run:
                    logs_snap.reference.set(logs_out, merge=True)

    # --- Templates ---
    for template_snap in db.collection('post_templates').stream():
        template = template_snap.to_dict() or {}
        template_out, template_changed = rewrite_template(
            template, placeholder_id, survivor_id
        )
        if template_changed:
            updated['post_templates'] += 1
            if not dry_run:
                template_snap.reference.set(template_out, merge=True)

    # --- Cell groups ---
    for cg_snap in db.collection('cell_groups').stream():
        cg = cg_snap.to_dict() or {}
        cg_out, cg_changed = rewrite_cell_group(
            cg,
            placeholder_id,
            survivor_id,
            survivor_auth_id=survivor_auth,
        )
        if cg_changed:
            updated['cell_groups'] += 1
            if not dry_run:
                cg_snap.reference.set(cg_out, merge=True)

        roster_snap = (
            cg_snap.reference.collection('supplemental').document('roster').get()
        )
        if roster_snap.exists:
            roster = roster_snap.to_dict() or {}
            roster_out, roster_changed = rewrite_roster(
                roster,
                placeholder_id,
                survivor_id,
                survivor_display_name=survivor_name,
            )
            if roster_changed:
                updated['cell_group_rosters'] += 1
                if not dry_run:
                    roster_snap.reference.set(roster_out, merge=True)

    # --- Ministry heads ---
    for tag_snap in db.collection('user_tags').stream():
        tag = tag_snap.to_dict() or {}
        tag_out, tag_changed = rewrite_heads_by_location(
            tag, placeholder_id, survivor_id
        )
        if tag_changed:
            updated['user_tags_heads'] += 1
            if not dry_run:
                tag_snap.reference.set(tag_out, merge=True)

    # --- Church pastors / updatedBy ---
    churches = db.collection('information').document('churches').collection('items')
    for church_snap in churches.stream():
        church = church_snap.to_dict() or {}
        church_changed = False
        church_out = dict(church)

        if 'pastorUserIds' in church_out:
            original = church_out.get('pastorUserIds') or []
            rewritten = _replace_uid_in_list(original, placeholder_id, survivor_id)
            if rewritten != [str(x).strip() for x in original if str(x).strip()]:
                church_out['pastorUserIds'] = rewritten
                church_changed = True
                updated['church_pastor_user_ids'] += 1

        if str(church_out.get('updatedBy', '')).strip() == placeholder_id:
            church_out['updatedBy'] = survivor_id
            church_changed = True
            updated['church_updated_by'] += 1

        if church_changed and not dry_run:
            church_snap.reference.set(church_out, merge=True)

        for page_snap in church_snap.reference.collection('pages').stream():
            page = page_snap.to_dict() or {}
            if str(page.get('updatedBy', '')).strip() != placeholder_id:
                continue
            updated['church_updated_by'] += 1
            if not dry_run:
                page_snap.reference.set({'updatedBy': survivor_id}, merge=True)

    # --- Other users: CreatedByUserID + activity documentId ---
    for user_snap in db.collection('users').stream():
        if user_snap.id == placeholder_id:
            continue
        user = user_snap.to_dict() or {}
        if str(user.get('CreatedByUserID', '')).strip() == placeholder_id:
            updated['users_created_by'] += 1
            if not dry_run:
                user_snap.reference.set(
                    {'CreatedByUserID': survivor_id},
                    merge=True,
                )

        activity_snap = (
            user_snap.reference.collection('supplemental').document('activity').get()
        )
        if activity_snap.exists:
            activity = activity_snap.to_dict() or {}
            activity_out, activity_changed = rewrite_activity_document_ids(
                activity, placeholder_id, survivor_id
            )
            if activity_changed:
                updated['users_activity_document_ids'] += 1
                if not dry_run:
                    activity_snap.reference.set(activity_out, merge=True)

    # --- Merge supplemental indexes from placeholder into survivor ---
    placeholder_roles = (
        placeholder_ref.collection('supplemental').document('roles').get()
    )
    placeholder_posts = (
        placeholder_ref.collection('supplemental').document('posts').get()
    )
    placeholder_activity = (
        placeholder_ref.collection('supplemental').document('activity').get()
    )

    has_supplemental = (
        placeholder_roles.exists
        or placeholder_posts.exists
        or placeholder_activity.exists
    )
    if has_supplemental:
        updated['users_supplemental_merged'] = True
        if not dry_run:
            survivor_roles_ref = survivor_ref.collection('supplemental').document(
                'roles'
            )
            survivor_posts_ref = survivor_ref.collection('supplemental').document(
                'posts'
            )
            survivor_activity_ref = survivor_ref.collection('supplemental').document(
                'activity'
            )

            survivor_roles_snap = survivor_roles_ref.get()
            existing_roles = []
            if survivor_roles_snap.exists:
                existing_roles = list(
                    (survivor_roles_snap.to_dict() or {}).get('roles') or []
                )
            incoming_roles = []
            if placeholder_roles.exists:
                incoming_roles = list(
                    (placeholder_roles.to_dict() or {}).get('roles') or []
                )
            survivor_roles_ref.set(
                {'roles': merge_role_lists(existing_roles, incoming_roles)},
                merge=True,
            )

            survivor_posts_snap = survivor_posts_ref.get()
            existing_posts = []
            if survivor_posts_snap.exists:
                existing_posts = list(
                    (survivor_posts_snap.to_dict() or {}).get('posts') or []
                )
            incoming_posts = []
            if placeholder_posts.exists:
                incoming_posts = list(
                    (placeholder_posts.to_dict() or {}).get('posts') or []
                )
            survivor_posts_ref.set(
                {'posts': merge_post_lists(existing_posts, incoming_posts)},
                merge=True,
            )

            survivor_activity_snap = survivor_activity_ref.get()
            existing_activity = []
            if survivor_activity_snap.exists:
                existing_activity = list(
                    (survivor_activity_snap.to_dict() or {}).get('Logs') or []
                )
            incoming_activity = []
            if placeholder_activity.exists:
                incoming_activity = list(
                    (placeholder_activity.to_dict() or {}).get('Logs') or []
                )
            survivor_activity_ref.set(
                {
                    'Logs': merge_activity_logs(
                        existing_activity, incoming_activity
                    )
                },
                merge=True,
            )

    placeholder_deleted = False
    if not dry_run:
        for post_id in touched_post_ids:
            sync_post_program_roles(
                db,
                post_id,
                cleared_uids=[placeholder_id],
            )

        _delete_user_tree(db, placeholder_id)
        placeholder_deleted = True
        _touch_tracker(db, 'users')
        if updated['events_program_roles'] or updated['events_attendance'] or updated[
            'events_metadata'
        ] or updated['events_head_lead_speakers']:
            _touch_tracker(db, 'events')
        if updated['cell_groups'] or updated['cell_group_rosters']:
            _touch_tracker(db, 'cell_groups')

    return {
        'placeholderUserId': placeholder_id,
        'survivorUserId': survivor_id,
        'dryRun': dry_run,
        'updated': updated,
        'touchedPostIds': sorted(touched_post_ids),
        'placeholderDeleted': placeholder_deleted,
    }
