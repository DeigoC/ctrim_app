import unittest
from datetime import datetime, timedelta, timezone

from fcm_payload import location_umbrella
from notification_schedule import (
    coming_up_body,
    due_event,
    plan_dispatch,
    run_scheduled_notifications,
    send_topic_notification,
    trigger_at,
)


def _utc(*parts) -> datetime:
    return datetime(*parts, tzinfo=timezone.utc)


SUNDAY = _utc(2026, 10, 4, 9, 30)
DAY_BEFORE = _utc(2026, 10, 3, 17)
MORNING = _utc(2026, 10, 4, 8)
TWO_HOURS = _utc(2026, 10, 4, 7, 30)


def _schedule(**overrides) -> dict:
    row = {
        'id': 's1',
        'enabled': True,
        'post_tag_id': 'tag-sun',
        'location': 'Belfast',
        'timing_kind': 'day_before',
        'clock_time': '18:00',
        'hours_before': 2,
        'last_sent_post_id': '',
        'last_sent_event_at': None,
    }
    row.update(overrides)
    return row


def _event(**overrides) -> dict:
    row = {
        'id': 'post-1',
        'title': 'Sunday Worship',
        'location': 'Belfast',
        'tag_ids': ['tag-sun'],
        'event_at': SUNDAY,
        'is_period_parent': False,
        'image_url': '',
    }
    row.update(overrides)
    return row


class NotificationScheduleTests(unittest.TestCase):
    def test_location_umbrella_slugs(self):
        self.assertEqual(location_umbrella('Belfast'), 'Belfast')
        self.assertEqual(location_umbrella('Belfast (Online)'), 'Belfast')
        self.assertEqual(location_umbrella('Portadown'), 'Portadown')
        self.assertEqual(location_umbrella('North Coast'), 'north-coast')
        self.assertEqual(location_umbrella(''), 'Belfast')

    def test_day_before_during_bst_and_winter(self):
        self.assertEqual(trigger_at(_schedule(), SUNDAY), DAY_BEFORE)
        self.assertEqual(coming_up_body(SUNDAY), 'Coming up · Sun, Oct 4 · 10:30')

        winter = _utc(2026, 11, 1, 10, 30)
        self.assertEqual(trigger_at(_schedule(), winter), _utc(2026, 10, 31, 18))
        self.assertEqual(coming_up_body(winter), 'Coming up · Sun, Nov 1 · 10:30')

    def test_morning_of_and_hours_before(self):
        morning = _schedule(timing_kind='morning_of', clock_time='09:00')
        self.assertEqual(trigger_at(morning, SUNDAY), MORNING)
        late = _schedule(timing_kind='morning_of', clock_time='11:00')
        self.assertIsNone(trigger_at(late, SUNDAY))
        self.assertIsNone(
            due_event(late, [_event()], _utc(2026, 10, 4, 10))
        )

        hours = _schedule(timing_kind='hours_before', hours_before=2)
        self.assertEqual(trigger_at(hours, SUNDAY), TWO_HOURS)

    def test_missed_tick_sends_until_the_event_starts(self):
        row = _schedule()
        post = _event()
        self.assertEqual(due_event(row, [post], DAY_BEFORE)['id'], 'post-1')
        self.assertIsNone(
            due_event(row, [post], DAY_BEFORE - timedelta(minutes=1))
        )
        self.assertEqual(
            due_event(row, [post], SUNDAY - timedelta(minutes=1))['id'],
            'post-1',
        )
        self.assertIsNone(due_event(row, [post], SUNDAY))

    def test_already_sent_and_period_parent_are_skipped(self):
        sent = _schedule(
            last_sent_post_id='post-1',
            last_sent_event_at=SUNDAY,
        )
        self.assertIsNone(due_event(sent, [_event()], DAY_BEFORE))
        self.assertIsNone(
            due_event(
                _schedule(),
                [_event(id='parent', is_period_parent=True)],
                DAY_BEFORE,
            )
        )
        self.assertIsNone(
            due_event(
                _schedule(),
                [_event(id='elsewhere', location='Portadown')],
                DAY_BEFORE,
            )
        )

    def test_soonest_due_post_then_the_next(self):
        earlier = _event(id='early')
        later = _event(
            id='later',
            title='Evening',
            event_at=SUNDAY + timedelta(hours=1),
        )
        row = _schedule(timing_kind='hours_before', hours_before=2)
        self.assertEqual(
            due_event(row, [later, earlier], TWO_HOURS)['id'],
            'early',
        )
        sent = _schedule(
            timing_kind='hours_before',
            hours_before=2,
            last_sent_post_id='early',
            last_sent_event_at=SUNDAY,
        )
        self.assertEqual(
            due_event(sent, [later, earlier], TWO_HOURS + timedelta(hours=1))['id'],
            'later',
        )

    def test_plan_dispatch_uses_the_location_topic(self):
        planned = plan_dispatch(
            [_schedule(location='North Coast')],
            [_event(location='North Coast', image_url='https://example.com/a.png')],
            DAY_BEFORE,
        )
        self.assertEqual(len(planned), 1)
        self.assertEqual(planned[0]['topic'], 'north-coast')
        self.assertEqual(planned[0]['body'], 'Coming up · Sun, Oct 4 · 10:30')
        self.assertEqual(planned[0]['post_id'], 'post-1')

        with_subtitle = plan_dispatch(
            [_schedule()],
            [_event(subtitle='  Gather at the hall  ')],
            DAY_BEFORE,
        )
        self.assertEqual(with_subtitle[0]['title'], 'Sunday Worship')
        self.assertEqual(
            with_subtitle[0]['body'],
            'Gather at the hall\nComing up · Sun, Oct 4 · 10:30',
        )

        self.assertEqual(
            plan_dispatch([_schedule(enabled=False)], [_event()], DAY_BEFORE),
            [],
        )
        self.assertEqual(
            plan_dispatch(
                [_schedule()],
                [_event(title='  ')],
                DAY_BEFORE,
            ),
            [],
        )

    def test_send_retries_without_a_bad_image(self):
        planned = {
            'topic': 'Belfast',
            'title': 'Sunday Worship',
            'body': 'Coming up · Sun, Oct 4 · 10:30',
            'post_id': 'post-1',
            'image_url': 'https://example.com/cover.png',
        }
        calls = []

        def send(message):
            calls.append(message)
            if len(calls) == 1:
                raise RuntimeError('notification image could not be fetched')

        send_topic_notification(planned, send)
        self.assertEqual(len(calls), 2)
        self.assertEqual(calls[0].data['PostID'], 'post-1')
        self.assertEqual(
            calls[0].webpush.fcm_options.link,
            'https://ctrim.app/post/post-1',
        )
        self.assertEqual(calls[0].android.notification.image, 'https://example.com/cover.png')
        self.assertIsNone(calls[1].android.notification)


class _Doc:
    def __init__(self, doc_id, data):
        self.id = doc_id
        self._data = data

    def to_dict(self):
        return dict(self._data)


class _Query:
    def __init__(self, docs):
        self._docs = docs

    def where(self, *_args, **_kwargs):
        return self

    def stream(self):
        return iter(self._docs)


class _Ref:
    def __init__(self, store, doc_id):
        self._store = store
        self.id = doc_id

    def update(self, fields):
        self._store.updates.append((self.id, fields))


class _Collection:
    def __init__(self, docs):
        self._docs = docs
        self.updates = []

    def where(self, *_args, **_kwargs):
        return _Query(self._docs)

    def document(self, doc_id):
        return _Ref(self, doc_id)

    def stream(self):
        return iter(self._docs)


class _Db:
    def __init__(self, schedules, events):
        self.schedules = _Collection(schedules)
        self.events = _Collection(events)

    def collection(self, name):
        if name == 'notification_schedules':
            return self.schedules
        if name == 'events':
            return self.events
        raise KeyError(name)


class RunScheduledNotificationTests(unittest.TestCase):
    def test_records_a_successful_send(self):
        db = _Db(
            schedules=[
                _Doc('s1', {
                    'Enabled': True,
                    'PostTagId': 'tag-sun',
                    'Location': 'Belfast',
                    'TimingKind': 'day_before',
                    'ClockTime': '18:00',
                    'HoursBefore': 2,
                }),
            ],
            events=[
                _Doc('post-1', {
                    'Title': 'Sunday Worship',
                    'Subtitle': 'Gather at the hall',
                    'Location': 'Belfast',
                    'TagIDs': ['tag-sun'],
                    'EventDate': SUNDAY,
                    'IsPeriodParent': False,
                    'Media': [{'type': 'img', 'src': 'https://example.com/a.png'}],
                }),
            ],
        )
        sent = []
        run_scheduled_notifications(db, now=DAY_BEFORE, send=sent.append)
        self.assertEqual(len(sent), 1)
        self.assertEqual(sent[0].topic, 'Belfast')
        self.assertEqual(sent[0].notification.title, 'Sunday Worship')
        self.assertEqual(
            sent[0].notification.body,
            'Gather at the hall\nComing up · Sun, Oct 4 · 10:30',
        )
        self.assertEqual(db.schedules.updates[0][0], 's1')
        fields = db.schedules.updates[0][1]
        self.assertEqual(fields['LastSentPostId'], 'post-1')
        self.assertEqual(fields['LastError'], '')
        self.assertEqual(fields['LastSentEventAt'], SUNDAY)

    def test_records_an_error_without_marking_sent(self):
        db = _Db(
            schedules=[
                _Doc('s1', {
                    'Enabled': True,
                    'PostTagId': 'tag-sun',
                    'Location': 'Belfast',
                    'TimingKind': 'day_before',
                    'ClockTime': '18:00',
                }),
            ],
            events=[
                _Doc('post-1', {
                    'Title': 'Sunday Worship',
                    'Location': 'Belfast',
                    'TagIDs': ['tag-sun'],
                    'EventDate': SUNDAY,
                }),
            ],
        )

        def fail(_message):
            raise RuntimeError('fcm down')

        run_scheduled_notifications(db, now=DAY_BEFORE, send=fail)
        fields = db.schedules.updates[0][1]
        self.assertEqual(fields, {'LastError': 'fcm down'})


if __name__ == '__main__':
    unittest.main()
