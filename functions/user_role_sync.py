"""Sync user supplemental role assignments from event program and attendance."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

# Sentinel role id for expected-attendee schedule rows (program roles use ms timestamps).
EXPECTED_ATTENDEE_ROLE_ID = 0
EXPECTED_ATTENDEE_TITLE = 'Expected attendee'
_DEFAULT_EVENT_DURATION = timedelta(hours=1)


def timestamp_to_millis(value: Any) -> int:
    """Convert Firestore Timestamp/datetime/int values to epoch milliseconds."""
    if value is None:
        raise ValueError('timestamp value is required')

    if hasattr(value, 'timestamp'):
        return int(value.timestamp() * 1000)

    if isinstance(value, datetime):
        return int(value.timestamp() * 1000)

    if isinstance(value, (int, float)):
        # Already millis when large enough; otherwise treat as seconds.
        numeric = int(value)
        if numeric > 1_000_000_000_000:
            return numeric
        return numeric * 1000

    raise TypeError(f'Unsupported timestamp type: {type(value)!r}')


def extract_uids_from_program(program_data: dict[str, Any] | None) -> set[str]:
    if not program_data:
        return set()

    uids: set[str] = set()
    for role in program_data.get('Roles') or []:
        for uid in role.get('uids') or []:
            uid_str = str(uid).strip()
            if uid_str:
                uids.add(uid_str)
    return uids


def extract_uids_from_expected(attendance_data: dict[str, Any] | None) -> set[str]:
    if not attendance_data:
        return set()

    raw = attendance_data.get('expectedUserIds')
    if raw is None:
        raw = attendance_data.get('ExpectedAttendeeUserIDs')

    uids: set[str] = set()
    for uid in raw or []:
        uid_str = str(uid).strip()
        if uid_str:
            uids.add(uid_str)
    return uids


def resolve_event_window(
    head_data: dict[str, Any] | None,
    program_data: dict[str, Any] | None,
) -> tuple[int, int] | None:
    """Return (startMil, endMil) for the post event, or None when undated."""
    if not head_data:
        return None

    event_date = head_data.get('EventDate')
    if event_date is None:
        return None

    start_mil = timestamp_to_millis(event_date)
    finish = program_data.get('FinishTime') if program_data else None
    if finish is not None:
        end_mil = timestamp_to_millis(finish)
    else:
        end_mil = start_mil + int(_DEFAULT_EVENT_DURATION.total_seconds() * 1000)

    if end_mil <= start_mil:
        end_mil = start_mil + int(_DEFAULT_EVENT_DURATION.total_seconds() * 1000)

    return start_mil, end_mil


def build_expected_attendee_entry(
    post_id: str,
    head_data: dict[str, Any] | None,
    program_data: dict[str, Any] | None,
) -> dict[str, Any] | None:
    window = resolve_event_window(head_data, program_data)
    if window is None:
        return None

    start_mil, end_mil = window
    return {
        'postID': post_id,
        'id': EXPECTED_ATTENDEE_ROLE_ID,
        'startMil': start_mil,
        'endMil': end_mil,
        'title': EXPECTED_ATTENDEE_TITLE,
    }


def build_desired_roles(
    post_id: str,
    program_data: dict[str, Any] | None,
    *,
    attendance_data: dict[str, Any] | None = None,
    head_data: dict[str, Any] | None = None,
) -> dict[str, list[dict[str, Any]]]:
    """Build desired supplemental role entries grouped by user id."""
    desired: dict[str, list[dict[str, Any]]] = {}
    program_uids: set[str] = set()

    if program_data:
        for role in program_data.get('Roles') or []:
            start = role.get('start')
            end = role.get('end')
            role_id = role.get('id')
            if start is None or end is None or role_id is None:
                continue

            entry = {
                'postID': post_id,
                'id': int(role_id),
                'startMil': timestamp_to_millis(start),
                'endMil': timestamp_to_millis(end),
                'title': str(role.get('title') or ''),
            }

            for uid in role.get('uids') or []:
                uid_str = str(uid).strip()
                if not uid_str:
                    continue
                program_uids.add(uid_str)
                desired.setdefault(uid_str, []).append(entry)

    expected_entry = build_expected_attendee_entry(post_id, head_data, program_data)
    if expected_entry is not None:
        for uid in extract_uids_from_expected(attendance_data):
            if uid in program_uids:
                continue
            desired.setdefault(uid, []).append(expected_entry)

    for uid, entries in desired.items():
        entries.sort(key=lambda item: (item['startMil'], item['id']))
        desired[uid] = entries

    return desired


def merge_roles_for_post(
    existing_roles: list[dict[str, Any]],
    post_id: str,
    post_entries: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Replace all role rows for [post_id] while preserving other posts."""
    retained = [role for role in existing_roles if role.get('postID') != post_id]
    retained.extend(post_entries)
    return retained


def uids_to_sync(
    before_program: dict[str, Any] | None,
    after_program: dict[str, Any] | None,
    *,
    before_attendance: dict[str, Any] | None = None,
    after_attendance: dict[str, Any] | None = None,
) -> set[str]:
    return (
        extract_uids_from_program(before_program)
        | extract_uids_from_program(after_program)
        | extract_uids_from_expected(before_attendance)
        | extract_uids_from_expected(after_attendance)
    )


def _load_head_program_attendance(
    db: Any,
    post_id: str,
) -> tuple[dict[str, Any] | None, dict[str, Any] | None, dict[str, Any] | None]:
    head_doc = db.collection('events').document(post_id).get()
    head_data = head_doc.to_dict() if head_doc.exists else None

    supplemental = db.collection('events').document(post_id).collection('supplemental')
    program_doc = supplemental.document('program').get()
    attendance_doc = supplemental.document('attendance').get()

    program_data = program_doc.to_dict() if program_doc.exists else None
    attendance_data = attendance_doc.to_dict() if attendance_doc.exists else None
    return head_data, program_data, attendance_data


def sync_post_program_roles(
    db: Any,
    post_id: str,
    *,
    cleared_uids: list[str] | None = None,
) -> dict[str, int]:
    """Read current post docs and sync supplemental roles for [post_id]."""
    head_data, program_data, attendance_data = _load_head_program_attendance(db, post_id)
    desired_by_uid = build_desired_roles(
        post_id,
        program_data,
        attendance_data=attendance_data,
        head_data=head_data,
    )

    uids_to_update = set(desired_by_uid.keys())
    if cleared_uids:
        uids_to_update |= {uid for uid in cleared_uids if uid}

    updated_count = 0
    for uid in uids_to_update:
        if sync_user_roles_for_post(
            db,
            uid=uid,
            post_id=post_id,
            post_entries=desired_by_uid.get(uid, []),
        ):
            updated_count += 1

    return {'uids': len(uids_to_update), 'updated': updated_count}


def sync_program_roles_from_change(
    db: Any,
    post_id: str,
    before_program: dict[str, Any] | None,
    after_program: dict[str, Any] | None,
) -> dict[str, int]:
    """Sync using explicit before/after program snapshots (Firestore trigger path)."""
    head_data, _, attendance_data = _load_head_program_attendance(db, post_id)
    before_uids = extract_uids_from_program(before_program)
    desired_by_uid = build_desired_roles(
        post_id,
        after_program,
        attendance_data=attendance_data,
        head_data=head_data,
    )
    uids_to_update = before_uids | set(desired_by_uid.keys())

    updated_count = 0
    for uid in uids_to_update:
        if sync_user_roles_for_post(
            db,
            uid=uid,
            post_id=post_id,
            post_entries=desired_by_uid.get(uid, []),
        ):
            updated_count += 1

    return {'uids': len(uids_to_update), 'updated': updated_count}


def sync_attendance_roles_from_change(
    db: Any,
    post_id: str,
    before_attendance: dict[str, Any] | None,
    after_attendance: dict[str, Any] | None,
) -> dict[str, int]:
    """Sync using explicit before/after attendance snapshots (Firestore trigger path)."""
    head_data, program_data, _ = _load_head_program_attendance(db, post_id)
    before_uids = extract_uids_from_expected(before_attendance)
    desired_by_uid = build_desired_roles(
        post_id,
        program_data,
        attendance_data=after_attendance,
        head_data=head_data,
    )
    uids_to_update = before_uids | set(desired_by_uid.keys())

    updated_count = 0
    for uid in uids_to_update:
        if sync_user_roles_for_post(
            db,
            uid=uid,
            post_id=post_id,
            post_entries=desired_by_uid.get(uid, []),
        ):
            updated_count += 1

    return {'uids': len(uids_to_update), 'updated': updated_count}


def sync_user_roles_for_post(
    db: Any,
    *,
    uid: str,
    post_id: str,
    post_entries: list[dict[str, Any]],
) -> bool:
    """Write merged supplemental roles for one user/post. Returns True when updated."""
    user_ref = db.collection('users').document(uid)
    if not user_ref.get().exists:
        return False

    roles_ref = user_ref.collection('supplemental').document('roles')
    roles_doc = roles_ref.get()
    existing_roles: list[dict[str, Any]] = []
    if roles_doc.exists:
        existing_roles = list(roles_doc.to_dict().get('roles') or [])

    merged_roles = merge_roles_for_post(existing_roles, post_id, post_entries)
    if merged_roles == existing_roles:
        return False

    roles_ref.set({'roles': merged_roles}, merge=True)
    return True
