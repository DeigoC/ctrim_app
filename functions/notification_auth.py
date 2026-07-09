"""Authorization helpers for notification Cloud Functions."""

from firebase_admin import firestore
from firebase_functions import https_fn


def can_send_notifications(uid: str, claims: dict | None) -> bool:
    """Return True when the caller may invoke notification send callables."""
    if not uid:
        return False

    if claims:
        if claims.get('isLeader') or claims.get('isAreaAdmin') or claims.get('isAdmin'):
            return True

    doc = firestore.client().collection('everyone').document(uid).get()
    if not doc.exists:
        return False

    data = doc.to_dict() or {}
    return (
        data.get('isUser') is True
        or data.get('isLeader') is True
        or data.get('isAdmin') is True
        or data.get('isAreaAdmin') is True
    )


def require_notification_sender(req: https_fn.CallableRequest) -> str:
    """Ensure the caller is authenticated and allowed to send notifications."""
    if not req.auth or not req.auth.uid:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message='Authentication required',
        )

    uid = req.auth.uid
    if not can_send_notifications(uid, req.auth.token):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message='Not authorized to send notifications',
        )

    return uid
