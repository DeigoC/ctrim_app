"""Sync user supplemental role assignments from event program documents."""

from __future__ import annotations

from datetime import datetime
from typing import Any


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


def build_desired_roles(post_id: str, program_data: dict[str, Any] | None) -> dict[str, list[dict[str, Any]]]:
    """Build desired supplemental role entries grouped by user id."""
    if not program_data:
        return {}

    desired: dict[str, list[dict[str, Any]]] = {}
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
            desired.setdefault(uid_str, []).append(entry)

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
) -> set[str]:
    return extract_uids_from_program(before_program) | extract_uids_from_program(after_program)


def sync_post_program_roles(
    db: Any,
    post_id: str,
    *,
    cleared_uids: list[str] | None = None,
) -> dict[str, int]:
    """Read the current program doc and sync supplemental roles for [post_id]."""
    program_doc = (
        db.collection('events')
        .document(post_id)
        .collection('supplemental')
        .document('program')
        .get()
    )
    after_program = program_doc.to_dict() if program_doc.exists else None
    desired_by_uid = build_desired_roles(post_id, after_program)

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
    before_uids = extract_uids_from_program(before_program)
    desired_by_uid = build_desired_roles(post_id, after_program)
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
