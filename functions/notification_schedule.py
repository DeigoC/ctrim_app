"""Repeating reminders: one post tag at one location.

Clock rules use Europe/London (EU BST). Keep them in step with
`lib/utility/notifications/london_time.dart` and
`notification_schedule_planner.dart`.
"""

from __future__ import annotations

import re
from datetime import datetime, timedelta, timezone
from typing import Any, Callable

from firebase_admin import messaging

from fcm_payload import (
    fcm_image_url,
    is_valid_fcm_topic,
    location_umbrella,
    looks_like_image_error,
)
from topic_message import build_topic_message

DAY_BEFORE = 'day_before'
MORNING_OF = 'morning_of'
HOURS_BEFORE = 'hours_before'

_WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
_MONTHS = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
]
_CLOCK = re.compile(r'^(\d{1,2}):(\d{2})$')

LOOKBACK = timedelta(hours=1)
LOOKAHEAD = timedelta(days=3)


def last_sunday_of_month(year: int, month: int) -> int:
    if month == 12:
        last = datetime(year + 1, 1, 1) - timedelta(days=1)
    else:
        last = datetime(year, month + 1, 1) - timedelta(days=1)
    days_back = (last.weekday() + 1) % 7
    return last.day - days_back


def is_london_bst(instant: datetime) -> bool:
    utc = as_utc(instant)
    start = datetime(
        utc.year, 3, last_sunday_of_month(utc.year, 3), 1, tzinfo=timezone.utc
    )
    end = datetime(
        utc.year, 10, last_sunday_of_month(utc.year, 10), 1, tzinfo=timezone.utc
    )
    return start <= utc < end


def as_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def london_wall(instant: datetime) -> datetime:
    """Naive London wall-clock fields stored on a UTC datetime's calendar."""
    utc = as_utc(instant)
    assert utc is not None
    shifted = utc + (timedelta(hours=1) if is_london_bst(utc) else timedelta(0))
    return shifted.replace(tzinfo=None)


def london_wall_to_utc(
    year: int, month: int, day: int, hour: int, minute: int
) -> datetime | None:
    for offset in (0, 1):
        utc = datetime(year, month, day, hour, minute, tzinfo=timezone.utc) - timedelta(
            hours=offset
        )
        actual = 1 if is_london_bst(utc) else 0
        if actual == offset:
            return utc
    return None


def parse_clock(raw: str | None) -> tuple[int, int] | None:
    match = _CLOCK.fullmatch(str(raw or '').strip())
    if match is None:
        return None
    hour = int(match.group(1))
    minute = int(match.group(2))
    if hour < 0 or hour > 23 or minute < 0 or minute > 59:
        return None
    return hour, minute


def clamp_hours_before(raw: Any) -> int:
    try:
        hours = int(raw)
    except (TypeError, ValueError):
        return 2
    return min(48, max(1, hours))


def format_london(instant: datetime) -> str:
    wall = london_wall(instant)
    return (
        f'{_WEEKDAYS[wall.weekday()]}, {_MONTHS[wall.month - 1]} {wall.day}'
        f' · {wall.hour:02d}:{wall.minute:02d}'
    )


def coming_up_body(event_at: datetime) -> str:
    return f'Coming up · {format_london(event_at)}'


def reminder_body(event: dict) -> str:
    """Push body: the post subtitle, then when it starts. The time line alone when there is no subtitle."""
    event_at = as_utc(event.get('event_at'))
    when = coming_up_body(event_at) if event_at is not None else ''
    subtitle = str(event.get('subtitle') or '').strip()
    if subtitle and when:
        return f'{subtitle}\n{when}'
    return subtitle or when


def trigger_at(schedule: dict, event_at: datetime) -> datetime | None:
    kind = schedule.get('timing_kind')
    event_utc = as_utc(event_at)
    if event_utc is None:
        return None
    if kind == HOURS_BEFORE:
        return event_utc - timedelta(hours=clamp_hours_before(schedule.get('hours_before')))

    clock = parse_clock(schedule.get('clock_time'))
    if clock is None:
        return None
    hour, minute = clock
    wall = london_wall(event_utc)
    if kind == DAY_BEFORE:
        previous = datetime(wall.year, wall.month, wall.day) - timedelta(days=1)
        return london_wall_to_utc(previous.year, previous.month, previous.day, hour, minute)
    if kind == MORNING_OF:
        morning = london_wall_to_utc(wall.year, wall.month, wall.day, hour, minute)
        if morning is None or morning >= event_utc:
            return None
        return morning
    return None


def morning_of_after_start(schedule: dict, event_at: datetime) -> bool:
    if schedule.get('timing_kind') != MORNING_OF:
        return False
    if parse_clock(schedule.get('clock_time')) is None:
        return False
    return trigger_at(schedule, event_at) is None


def already_sent(schedule: dict, post_id: str, event_at: datetime) -> bool:
    if schedule.get('last_sent_post_id') != post_id:
        return False
    sent_at = as_utc(schedule.get('last_sent_event_at'))
    event_utc = as_utc(event_at)
    if sent_at is None or event_utc is None:
        return False
    return abs((sent_at - event_utc).total_seconds()) < 1


def _matches(schedule: dict, event: dict) -> bool:
    tag_id = str(schedule.get('post_tag_id') or '').strip()
    location = str(schedule.get('location') or '').strip()
    if not tag_id or not location:
        return False
    if event.get('is_period_parent'):
        return False
    if event.get('event_at') is None:
        return False
    if str(event.get('location') or '').strip() != location:
        return False
    return tag_id in (event.get('tag_ids') or [])


def due_event(schedule: dict, events: list[dict], now: datetime) -> dict | None:
    now_utc = as_utc(now)
    assert now_utc is not None
    best: dict | None = None
    for event in events:
        if not _matches(schedule, event):
            continue
        event_at = as_utc(event['event_at'])
        assert event_at is not None
        trigger = trigger_at(schedule, event_at)
        if trigger is None:
            continue
        if now_utc >= event_at or now_utc < trigger:
            continue
        if already_sent(schedule, event['id'], event_at):
            continue
        if best is None or event_at < as_utc(best['event_at']):
            best = event
    return best


def plan_dispatch(schedules: list[dict], events: list[dict], now: datetime) -> list[dict]:
    planned: list[dict] = []
    for schedule in schedules:
        if schedule.get('enabled') is not True:
            continue
        event = due_event(schedule, events, now)
        if event is None:
            continue
        title = str(event.get('title') or '').strip()
        if not title:
            continue
        event_at = as_utc(event['event_at'])
        assert event_at is not None
        topic = location_umbrella(schedule.get('location'))
        if not is_valid_fcm_topic(topic):
            continue
        planned.append({
            'schedule_id': schedule['id'],
            'post_id': event['id'],
            'event_at': event_at,
            'title': title,
            'body': reminder_body(event),
            'topic': topic,
            'image_url': str(event.get('image_url') or ''),
        })
    return planned


def cover_image_url(data: dict | None) -> str:
    raw = data or {}
    media = raw.get('Media') or []
    if isinstance(media, list):
        for entry in media:
            if isinstance(entry, dict) and entry.get('type') == 'img':
                src = str(entry.get('src') or '').strip()
                if src:
                    return src
    speaker = str(raw.get('LeadSpeakerImgSrc') or '').strip()
    return speaker


def normalize_event(doc_id: str, data: dict | None) -> dict:
    raw = data or {}
    tags = raw.get('TagIDs') or []
    tag_ids = [str(tag) for tag in tags if str(tag).strip()] if isinstance(tags, list) else []
    return {
        'id': doc_id,
        'title': str(raw.get('Title') or ''),
        'subtitle': str(raw.get('Subtitle') or ''),
        'location': str(raw.get('Location') or ''),
        'tag_ids': tag_ids,
        'event_at': as_utc(raw.get('EventDate')) if isinstance(raw.get('EventDate'), datetime) else None,
        'is_period_parent': raw.get('IsPeriodParent') is True,
        'image_url': cover_image_url(raw),
    }


def normalize_schedule(doc_id: str, data: dict | None) -> dict:
    raw = data or {}
    sent_event = raw.get('LastSentEventAt')
    return {
        'id': doc_id,
        'enabled': raw.get('Enabled') is True,
        'post_tag_id': str(raw.get('PostTagId') or '').strip(),
        'location': str(raw.get('Location') or '').strip(),
        'timing_kind': str(raw.get('TimingKind') or '').strip(),
        'clock_time': str(raw.get('ClockTime') or '').strip(),
        'hours_before': raw.get('HoursBefore'),
        'last_sent_post_id': str(raw.get('LastSentPostId') or '').strip(),
        'last_sent_event_at': as_utc(sent_event) if isinstance(sent_event, datetime) else None,
    }


def send_topic_notification(
    planned: dict,
    send: Callable[[messaging.Message], Any],
) -> None:
    data = {'PostID': planned['post_id']}
    image = fcm_image_url(planned.get('image_url'))

    def message(include_images: bool) -> messaging.Message:
        img = image if include_images else ''
        return build_topic_message(
            topic=planned['topic'],
            title=planned['title'],
            body=planned['body'],
            data=data,
            ios_image=img,
            android_image=img,
        )

    try:
        send(message(True))
    except Exception as exc:  # noqa: BLE001 — retry once without a bad image
        if image and looks_like_image_error(exc):
            send(message(False))
            return
        raise


def run_scheduled_notifications(db, now: datetime | None = None, send=None) -> None:
    """Load enabled rows and upcoming posts, then send whatever is due."""
    if send is None:
        send = messaging.send
    now_utc = as_utc(now) or datetime.now(timezone.utc)
    assert now_utc is not None
    start = now_utc - LOOKBACK
    end = now_utc + LOOKAHEAD

    schedules = [
        normalize_schedule(doc.id, doc.to_dict() or {})
        for doc in db.collection('notification_schedules')
        .where('Enabled', '==', True)
        .stream()
    ]
    events = [
        normalize_event(doc.id, doc.to_dict() or {})
        for doc in db.collection('events')
        .where('EventDate', '>=', start)
        .where('EventDate', '<', end)
        .stream()
    ]

    for planned in plan_dispatch(schedules, events, now_utc):
        ref = db.collection('notification_schedules').document(planned['schedule_id'])
        try:
            send_topic_notification(planned, send)
        except Exception as exc:  # noqa: BLE001 — retry on the next tick
            print(
                f'scheduled notification failed schedule={planned["schedule_id"]}: {exc}'
            )
            ref.update({'LastError': str(exc)[:500]})
            continue
        ref.update({
            'LastSentPostId': planned['post_id'],
            'LastSentEventAt': planned['event_at'],
            'LastSentAt': now_utc,
            'LastError': '',
        })
