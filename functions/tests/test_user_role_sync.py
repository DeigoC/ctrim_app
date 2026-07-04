import unittest
from datetime import datetime, timezone

from user_role_sync import (
    build_desired_roles,
    extract_uids_from_program,
    merge_roles_for_post,
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

    def test_extract_uids_from_program_skips_empty(self):
        program = {'Roles': [{'uids': ['', '9'], 'title': 'A', 'start': 1, 'end': 2, 'id': 1}]}
        self.assertEqual(extract_uids_from_program(program), {'9'})


if __name__ == '__main__':
    unittest.main()
