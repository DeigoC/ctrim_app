"""Placeholder user create / Auth link Cloud Functions."""

from __future__ import annotations

from firebase_admin import firestore
from firebase_functions import https_fn


def _everyone_flags(db, auth_uid: str) -> dict:
    doc = db.collection('everyone').document(auth_uid).get()
    if not doc.exists:
        return {}
    return doc.to_dict() or {}


def _is_area_or_global_admin(flags: dict) -> bool:
    return flags.get('isAreaAdmin') is True or flags.get('isAdmin') is True


def _find_volunteer_by_auth(db, auth_uid: str) -> tuple[str | None, dict | None]:
    results = (
        db.collection('users')
        .where('AuthID', '==', auth_uid)
        .limit(1)
        .get()
    )
    if not results:
        return None, None
    snap = results[0]
    return snap.id, snap.to_dict() or {}


def _require_auth(req: https_fn.CallableRequest) -> str:
    if not req.auth or not req.auth.uid:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message='Authentication required',
        )
    return req.auth.uid


def _caller_may_create_placeholder(
    db,
    *,
    auth_uid: str,
    caller_volunteer_id: str | None,
    post_id: str,
    cell_group_id: str = '',
) -> bool:
    flags = _everyone_flags(db, auth_uid)
    if _is_area_or_global_admin(flags):
        return True

    if not caller_volunteer_id:
        return False

    if cell_group_id:
        cg = db.collection('cell_groups').document(cell_group_id).get()
        if cg.exists:
            leaders = (cg.to_dict() or {}).get('LeaderUserIds') or []
            if caller_volunteer_id in [str(x) for x in leaders]:
                return True

    if not post_id:
        return False

    meta = (
        db.collection('events')
        .document(post_id)
        .collection('supplemental')
        .document('metadata')
        .get()
    )
    if not meta.exists:
        return False
    author = str((meta.to_dict() or {}).get('AuthorUID', '')).strip()
    return author == caller_volunteer_id


def _allocate_user_id(db) -> str:
    tracker_ref = db.collection('id_tracker').document('users')
    transaction = db.transaction()

    @firestore.transactional
    def _bump(txn, ref):
        snap = ref.get(transaction=txn)
        if not snap.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message='User id tracker missing',
            )
        current = str((snap.to_dict() or {}).get('id', '')).strip()
        if not current:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message='User id tracker empty',
            )
        next_id = str(int(current) + 1)
        txn.set(ref, {'id': next_id})
        return current

    return _bump(transaction, tracker_ref)


def create_placeholder_user_impl(db, req: https_fn.CallableRequest) -> dict:
    auth_uid = _require_auth(req)
    data = req.data or {}

    forename = str(data.get('Forename', '')).strip()
    surname = str(data.get('Surname', '')).strip()
    location = str(data.get('Location', 'Belfast')).strip() or 'Belfast'
    post_id = str(data.get('PostID', '')).strip()
    cell_group_id = str(data.get('CellGroupID', '')).strip()

    if not forename or not surname:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message='Forename and Surname are required',
        )

    caller_volunteer_id, _ = _find_volunteer_by_auth(db, auth_uid)
    if not _caller_may_create_placeholder(
        db,
        auth_uid=auth_uid,
        caller_volunteer_id=caller_volunteer_id,
        post_id=post_id,
        cell_group_id=cell_group_id,
    ):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message='Not authorized to create placeholder users',
        )

    if not caller_volunteer_id:
        # Area admins should normally have a volunteer profile; still allow create
        # with empty CreatedByUserID only for area/global admin (rules: admin-only link).
        flags = _everyone_flags(db, auth_uid)
        if not _is_area_or_global_admin(flags):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message='Caller has no volunteer profile',
            )
        created_by = ''
    else:
        created_by = caller_volunteer_id

    new_id = _allocate_user_id(db)
    user_payload = {
        'Forename': forename,
        'Surname': surname,
        'Location': location,
        'IsAreaAdmin': False,
        'IsLeader': False,
        'ImgSrc': '',
        'AuthID': '',
        'Tags': [],
        'CreatedByUserID': created_by,
        'IsPlaceholder': True,
    }

    user_ref = db.collection('users').document(new_id)
    user_ref.set(user_payload)
    user_ref.collection('supplemental').document('roles').set({'roles': []})
    user_ref.collection('supplemental').document('posts').set({'posts': []})

    return {'Id': new_id, **user_payload}


def _caller_may_link_auth(
    db,
    *,
    auth_uid: str,
    flags: dict,
    target: dict,
    target_had_auth: bool,
) -> bool:
    if _is_area_or_global_admin(flags):
        return True

    # Post-link freeze: only area/global admin may reassign after Auth is set.
    if target_had_auth or target.get('IsPlaceholder') is not True:
        return False

    created_by = str(target.get('CreatedByUserID', '')).strip()
    if not created_by:
        return False

    creator = db.collection('users').document(created_by).get()
    if not creator.exists:
        return False
    return str((creator.to_dict() or {}).get('AuthID', '')).strip() == auth_uid


def link_user_auth_impl(db, req: https_fn.CallableRequest) -> dict:
    auth_uid = _require_auth(req)
    data = req.data or {}

    user_id = str(data.get('UserID', '')).strip()
    new_auth_id = str(data.get('AuthID', '')).strip()
    is_leader = data.get('IsLeader') is True
    is_area_admin = data.get('IsAreaAdmin') is True

    if not user_id or not new_auth_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message='UserID and AuthID are required',
        )

    flags = _everyone_flags(db, auth_uid)
    user_ref = db.collection('users').document(user_id)
    user_snap = user_ref.get()
    if not user_snap.exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message='User not found',
        )

    target = user_snap.to_dict() or {}
    old_auth = str(target.get('AuthID', '')).strip()
    if not _caller_may_link_auth(
        db,
        auth_uid=auth_uid,
        flags=flags,
        target=target,
        target_had_auth=old_auth != '',
    ):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message='Not authorized to link Auth for this user',
        )

    # Non-admins cannot grant leader / area admin via link.
    if not _is_area_or_global_admin(flags):
        is_leader = False
        is_area_admin = False
    else:
        # Prefer request flags; fall back to existing users doc so promote-then-link
        # keeps area admin on everyone/{authID} without a second Save.
        if data.get('IsAreaAdmin') is None:
            is_area_admin = target.get('IsAreaAdmin') is True
        if data.get('IsLeader') is None:
            is_leader = target.get('IsLeader') is True

    conflict = (
        db.collection('users')
        .where('AuthID', '==', new_auth_id)
        .limit(1)
        .get()
    )
    if conflict and conflict[0].id != user_id:
        other = conflict[0].to_dict() or {}
        name = f"{other.get('Forename', '')} {other.get('Surname', '')}".strip()
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
            message=f'That account is already linked to {name or conflict[0].id}.',
        )

    everyone_ref = db.collection('everyone').document(new_auth_id)
    if not everyone_ref.get().exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message='No account found for that Auth ID.',
        )

    updates = {
        'AuthID': new_auth_id,
        'IsPlaceholder': False,
    }
    if _is_area_or_global_admin(flags):
        updates['IsLeader'] = is_leader
        updates['IsAreaAdmin'] = is_area_admin
    user_ref.update(updates)

    everyone_payload = {'isUser': True}
    if _is_area_or_global_admin(flags):
        everyone_payload['isLeader'] = is_leader
        everyone_payload['isAreaAdmin'] = is_area_admin
    everyone_ref.set(everyone_payload, merge=True)

    if old_auth and old_auth != new_auth_id:
        db.collection('everyone').document(old_auth).set(
            {'isUser': False, 'isLeader': False, 'isAreaAdmin': False},
            merge=True,
        )

    merged = {**target, **updates}
    return {'Id': user_id, **merged}


def backfill_placeholder_flags_impl(db, req: https_fn.CallableRequest) -> dict:
    auth_uid = _require_auth(req)
    flags = _everyone_flags(db, auth_uid)
    if not _is_area_or_global_admin(flags):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message='Area admin required',
        )

    updated = 0
    for snap in db.collection('users').stream():
        data = snap.to_dict() or {}
        auth = str(data.get('AuthID', '')).strip()
        if auth:
            continue
        if data.get('IsPlaceholder') is True:
            continue
        snap.reference.update({'IsPlaceholder': True})
        updated += 1

    return {'updated': updated}
