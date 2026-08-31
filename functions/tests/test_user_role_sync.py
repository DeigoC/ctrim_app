import unittest
from datetime import datetime, timezone

from user_role_sync import (
    EXPECTED_ATTENDEE_ROLE_ID,
    EXPECTED_ATTENDEE_TITLE,
    build_desired_roles,
    build_expected_attendee_entry,
    extract_uids_from_expected,
    extract_uids_from_program,
    merge_roles_for_post,
    resolve_event_window,
    timestamp_to_millis,
    uids_to_sync,
)


class UserRoleSyncTests(unittest.TestCase):
    def test_timestamp_to_millis_from_datetime(self):
        value = datetime(2024, 6, 15, 10, 30, tzinfo=timezone.utc)
        self.assertEqual(timestamp_to_millis(value), int(value.timestamp() * 1000))

    def test_build_desired_roles_groups_by_uid(self):
        program = {
            'Roles': [
                {
                    'uids': ['7', '8'],
                    'title': 'Setup',
                    'start': datetime(2024, 6, 15, 10, 0, tzinfo=timezone.utc),
                    'end': datetime(2024, 6, 15, 11, 0, tzinfo=timezone.utc),
                    'id': 1000,
                }
            ]
        }

        desired = build_desired_roles('post-1', program)

        self.assertEqual(set(desired.keys()), {'7', '8'})
        self.assertEqual(desired['7'][0]['postID'], 'post-1')
        self.assertEqual(desired['7'][0]['id'], 1000)
        self.assertEqual(desired['7'][0]['title'], 'Setup')
        self.assertEqual(
            desired['7'][0]['startMil'],
            int(datetime(2024, 6, 15, 10, 0, tzinfo=timezone.utc).timestamp() * 1000),
        )

    def test_build_desired_roles_adds_expected_attendees_without_program_role(self):
        event_date = datetime(2024, 6, 15, 19, 30, tzinfo=timezone.utc)
        finish = datetime(2024, 6, 15, 21, 0, tzinfo=timezone.utc)
        head = {'EventDate': event_date}
        program = {'FinishTime': finish, 'Roles': []}
        attendance = {'expectedUserIds': ['u1', 'u2']}

        desired = build_desired_roles(
            'post-1',
            program,
            attendance_data=attendance,
            head_data=head,
        )

        self.assertEqual(set(desired.keys()), {'u1', 'u2'})
        entry = desired['u1'][0]
        self.assertEqual(entry['id'], EXPECTED_ATTENDEE_ROLE_ID)
        self.assertEqual(entry['title'], EXPECTED_ATTENDEE_TITLE)
        self.assertEqual(entry['startMil'], timestamp_to_millis(event_date))
        self.assertEqual(entry['endMil'], timestamp_to_millis(finish))

    def test_build_desired_roles_skips_expected_when_user_has_program_role(self):
        event_date = datetime(2024, 6, 15, 19, 30, tzinfo=timezone.utc)
        head = {'EventDate': event_date}
        program = {
            'Roles': [
                {
                    'uids': ['u1'],
                    'title': 'Host',
                    'start': datetime(2024, 6, 15, 19, 0, tzinfo=timezone.utc),
                    'end': datetime(2024, 6, 15, 20, 0, tzinfo=timezone.utc),
                    'id': 2000,
                }
            ]
        }
        attendance = {'expectedUserIds': ['u1', 'u2']}

        desired = build_desired_roles(
            'post-1',
            program,
            attendance_data=attendance,
            head_data=head,
        )

        self.assertEqual(len(desired['u1']), 1)
        self.assertEqual(desired['u1'][0]['title'], 'Host')
        self.assertEqual(len(desired['u2']), 1)
        self.assertEqual(desired['u2'][0]['title'], EXPECTED_ATTENDEE_TITLE)

    def test_build_desired_roles_skips_expected_without_event_date(self):
        attendance = {'expectedUserIds': ['u1']}
        desired = build_desired_roles(
            'post-1',
            {'Roles': []},
            attendance_data=attendance,
            head_data={'Title': 'Weekly meeting'},
        )
        self.assertEqual(desired, {})

    def test_resolve_event_window_defaults_end_when_finish_missing(self):
        event_date = datetime(2024, 6, 15, 19, 30, tzinfo=timezone.utc)
        start_mil, end_mil = resolve_event_window({'EventDate': event_date}, {})
        self.assertEqual(start_mil, timestamp_to_millis(event_date))
        self.assertEqual(end_mil, start_mil + 3_600_000)

    def test_merge_roles_for_post_replaces_only_matching_post(self):
        existing = [
            {'postID': 'post-1', 'id': 1, 'title': 'Old'},
            {'postID': 'post-2', 'id': 2, 'title': 'Keep'},
        ]
        updated = [
            {'postID': 'post-1', 'id': 3, 'title': 'New'},
        ]

        merged = merge_roles_for_post(existing, 'post-1', updated)
        by_post = {role['postID']: role for role in merged}

        self.assertEqual(len(merged), 2)
        self.assertEqual(by_post['post-1']['title'], 'New')
        self.assertEqual(by_post['post-2']['title'], 'Keep')

    def test_uids_to_sync_includes_removed_assignees(self):
        before = {'Roles': [{'uids': ['1', '2'], 'title': 'A', 'start': 1, 'end': 2, 'id': 1}]}
        after = {'Roles': [{'uids': ['2'], 'title': 'A', 'start': 1, 'end': 2, 'id': 1}]}

        self.assertEqual(uids_to_sync(before, after), {'1', '2'})

    def test_uids_to_sync_includes_expected_attendee_changes(self):
        before_attendance = {'expectedUserIds': ['1', '2']}
        after_attendance = {'expectedUserIds': ['2', '3']}

        self.assertEqual(
            uids_to_sync(None, None, before_attendance=before_attendance, after_attendance=after_attendance),
            {'1', '2', '3'},
        )

    def test_extract_uids_from_program_skips_empty(self):
        program = {'Roles': [{'uids': ['', '9'], 'title': 'A', 'start': 1, 'end': 2, 'id': 1}]}
        self.assertEqual(extract_uids_from_program(program), {'9'})

    def test_extract_uids_from_expected_reads_legacy_field(self):
        attendance = {'ExpectedAttendeeUserIDs': ['a', 'b']}
        self.assertEqual(extract_uids_from_expected(attendance), {'a', 'b'})

    def test_build_expected_attendee_entry(self):
        event_date = datetime(2024, 6, 15, 19, 30, tzinfo=timezone.utc)
        entry = build_expected_attendee_entry(
            'post-9',
            {'EventDate': event_date},
            {'FinishTime': datetime(2024, 6, 15, 21, 0, tzinfo=timezone.utc)},
        )
        self.assertIsNotNone(entry)
        assert entry is not None
        self.assertEqual(entry['postID'], 'post-9')
        self.assertEqual(entry['id'], EXPECTED_ATTENDEE_ROLE_ID)


if __name__ == '__main__':
    unittest.main()
