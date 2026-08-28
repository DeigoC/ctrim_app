"""Sanitize FCM topic names and notification image URLs; web click deep links."""

from __future__ import annotations

import re

from urllib.parse import quote

# FCM topic names: [a-zA-Z0-9-_.~%]+
_FCM_TOPIC_PATTERN = re.compile(r'^[a-zA-Z0-9\-_.~%]+$')
_DRIVE_HOST_HINTS = (
    'drive.google.com',
    'drive.usercontent.google.com',
)
# Same origin as ShareWebAppPage.webAppLink — FCM web click fallback.
_WEB_APP_ORIGIN = 'https://ctrim.app'


def is_valid_fcm_topic(topic: str) -> bool:
    return bool(topic) and _FCM_TOPIC_PATTERN.fullmatch(topic) is not None


def fcm_image_url(url: str | None) -> str:
    """Return an HTTPS image URL FCM can fetch, or empty to omit the image.

    Google Drive share/uc links usually 403 or return HTML to FCM's crawler,
    which makes messaging.send fail for the whole notification.
    """
    if not url:
        return ''
    trimmed = str(url).strip()
    if not trimmed.lower().startswith('https://'):
        return ''
    lowered = trimmed.lower()
    if any(hint in lowered for hint in _DRIVE_HOST_HINTS):
        return ''
    return trimmed


def looks_like_image_error(exc: BaseException) -> bool:
    text = str(exc).lower()
    return 'image' in text or 'icon' in text


def web_click_link(data_dict: dict | None) -> str:
    """Absolute web URL FCM should open when the notification is tapped."""
    data = data_dict or {}
    post_id = str(data.get('PostID', '')).strip()
    if post_id:
        return f'{_WEB_APP_ORIGIN}/?postId={quote(post_id, safe="")}'
    info_page = str(data.get('InfoPage', '')).strip()
    if info_page:
        return f'{_WEB_APP_ORIGIN}/?infoPage={quote(info_page, safe="")}'
    return f'{_WEB_APP_ORIGIN}/'
