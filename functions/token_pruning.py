"""Prune invalid FCM tokens from Firestore after send failures."""

from firebase_admin import firestore


_INVALID_TOKEN_MARKERS = (
    'registration-token-not-registered',
    'invalid-registration-token',
    'requested entity was not found',
    'not-found',
    'unregistered',
)


def is_invalid_token_error(exc) -> bool:
    if exc is None:
        return False
    code = str(getattr(exc, 'code', '') or '').lower()
    message = str(exc).lower()
    combined = f'{code} {message}'
    return any(marker in combined for marker in _INVALID_TOKEN_MARKERS)


def prune_invalid_tokens(db, tokens: list[str]) -> int:
    """Remove dead tokens from web_tokens, web_topics, and device_tokens when possible.

    Returns the number of tokens for which at least one cleanup write was attempted.
    """
    unique = [t for t in dict.fromkeys(tokens) if t]
    if not unique:
        return 0

    pruned = 0
    for token in unique:
        if _prune_one_token(db, token):
            pruned += 1
    return pruned


def _prune_one_token(db, token: str) -> bool:
    did_work = False
    auth_id = None

    web_tokens_ref = db.collection('notification_tokens').document('web_tokens')
    web_tokens_doc = web_tokens_ref.get()
    if web_tokens_doc.exists:
        data = web_tokens_doc.to_dict() or {}
        entries = data.get('entries') or {}
        if token in entries:
            entry = entries.get(token) or {}
            if isinstance(entry, dict):
                auth_id = entry.get('authId')
            web_tokens_ref.set(
                {'entries': {token: firestore.DELETE_FIELD}},
                merge=True,
            )
            did_work = True

    web_topics_ref = db.collection('notification_tokens').document('web_topics')
    web_topics_doc = web_topics_ref.get()
    if web_topics_doc.exists:
        updates = {}
        for topic, value in (web_topics_doc.to_dict() or {}).items():
            if isinstance(value, list) and token in value:
                updates[topic] = firestore.ArrayRemove([token])
        if updates:
            web_topics_ref.update(updates)
            did_work = True

    if auth_id:
        device_ref = (
            db.collection('everyone')
            .document(auth_id)
            .collection('supplemental')
            .document('device_tokens')
        )
        device_doc = device_ref.get()
        if device_doc.exists:
            device_data = device_doc.to_dict() or {}
            device_tokens = dict(device_data.get('device_tokens') or {})
            if token in device_tokens:
                device_tokens.pop(token)
                device_ref.update({'device_tokens': device_tokens})
                did_work = True

    return did_work
