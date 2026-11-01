"""Unit tests for merge_placeholder_user rewrite helpers."""

import sys
import types
import unittest
from unittest.mock import MagicMock

if 'firebase_admin' not in sys.modules:
    firebase_admin = types.ModuleType('firebase_admin')
    firestore_mod = types.ModuleType('firebase_admin.firestore')
    firestore_mod.transactional = lambda fn: fn
    firebase_admin.firestore = firestore_mod
    sys.modules['firebase_admin'] = firebase_admin
    sys.modules['firebase_admin.firestore'] = firestore_mod

if 'firebase_functions' not in sys.modules:
    firebase_functions = types.ModuleType('firebase_functions')
    https_fn = types.ModuleType('firebase_functions.https_fn')

    class _HttpsError(Exception):
        def __init__(self, code=None, message=''):
            super().__init__(message)
            self.code = code
            self.message = message

    class _FunctionsErrorCode:
        UNAUTHENTICATED = 'UNAUTHENTICATED'
        PERMISSION_DENIED = 'PERMISSION_DENIED'
        INVALID_ARGUMENT = 'INVALID_ARGUMENT'
        NOT_FOUND = 'NOT_FOUND'
        FAILED_PRECONDITION = 'FAILED_PRECONDITION'
        ALREADY_EXISTS = 'ALREADY_EXISTS'

    https_fn.HttpsError = _HttpsError
    https_fn.FunctionsErrorCode = _FunctionsErrorCode
    https_fn.CallableRequest = object
    firebase_functions.https_fn = https_fn
    sys.modules['firebase_functions'] = firebase_functions
    sys.modules['firebase_functions.https_fn'] = https_fn

from merge_placeholder_user import (  # noqa: E402
    _effective_is_placeholder,
    merge_activity_logs,
    merge_placeholder_into_user_impl,
    merge_post_lists,
    merge_role_lists,
    rewrite_attendance,
    rewrite_cell_group,
    rewrite_heads_by_location,
    rewrite_lead_speakers_head,
    rewrite_metadata,
    rewrite_program_roles,
    rewrite_roster,
    rewrite_template,
)


class RewriteHelperTests(unittest.TestCase):
    def test_effective_placeholder(self):
        self.assertTrue(
            _effective_is_placeholder({'IsPlaceholder': True, 'AuthID': ''})
        )
        self.assertFalse(
            _effective_is_placeholder(
                {'IsPlaceholder': True, 'AuthID': 'auth-1'}
            )
        )
        self.assertFalse(
            _effective_is_placeholder({'IsPlaceholder': False, 'AuthID': ''})
        )

    def test_rewrite_program_roles_dedupes(self):
        data = {
            'Roles': [
                {'id': 1, 'uids': ['9', '7', '9']},
                {'id': 2, 'uids': ['9']},
            ]
        }
        out, changed = rewrite_program_roles(data, '9', '7')
        self.assertTrue(changed)
        self.assertEqual(out['Roles'][0]['uids'], ['7'])
        self.assertEqual(out['Roles'][1]['uids'], ['7'])

    def test_rewrite_metadata(self):
        data = {
            'AuthorUID': '9',
            'ContributorUIDs': ['9', '3'],
            'LeadSpeakerUIDs': ['9'],
            'LastUID': '9',
        }
        out, changed = rewrite_metadata(data, '9', '7')
        self.assertTrue(changed)
        self.assertEqual(out['AuthorUID'], '7')
        self.assertEqual(out['ContributorUIDs'], ['7', '3'])
        self.assertEqual(out['LeadSpeakerUIDs'], ['7'])
        self.assertEqual(out['LastUID'], '7')

    def test_rewrite_lead_speakers_head(self):
        data = {
            'LeadSpeakerUID': '9',
            'LeadSpeakerName': 'Temp Person',
            'LeadSpeakers': [
                {'UID': '9', 'Name': 'Temp Person'},
                {'UID': '7', 'Name': 'Real One'},
            ],
        }
        out, changed = rewrite_lead_speakers_head(
            data,
            '9',
            '7',
            survivor_name='Real One',
            survivor_img='img.png',
        )
        self.assertTrue(changed)
        self.assertEqual(out['LeadSpeakerUID'], '7')
        self.assertEqual(out['LeadSpeakerName'], 'Real One')
        self.assertEqual(len(out['LeadSpeakers']), 1)
        self.assertEqual(out['LeadSpeakers'][0]['UID'], '7')

    def test_rewrite_attendance(self):
        data = {
            'expectedUserIds': ['9', '2'],
            'attendees': [
                {
                    'id': 'user_9',
                    'type': 'user',
                    'userId': '9',
                    'displayName': 'Temp',
                    'addedBy': '9',
                },
                {
                    'id': 'user_7',
                    'type': 'user',
                    'userId': '7',
                    'displayName': 'Real',
                    'addedBy': '1',
                },
            ],
            'interested': {
                'auth-x': {'userId': '9', 'displayName': 'Temp'},
            },
        }
        out, changed = rewrite_attendance(
            data, '9', '7', survivor_display_name='Real One'
        )
        self.assertTrue(changed)
        self.assertEqual(out['expectedUserIds'], ['7', '2'])
        self.assertEqual(len(out['attendees']), 1)
        self.assertEqual(out['attendees'][0]['userId'], '7')
        self.assertEqual(out['attendees'][0]['id'], 'user_7')
        self.assertEqual(out['interested']['auth-x']['userId'], '7')

    def test_rewrite_roster_and_cell_group(self):
        roster = {
            'Members': [
                {'UserId': '9', 'DisplayName': 'Temp', 'Status': 'active'},
                {'UserId': '7', 'DisplayName': 'Real', 'Status': 'active'},
            ]
        }
        out, changed = rewrite_roster(
            roster, '9', '7', survivor_display_name='Real One'
        )
        self.assertTrue(changed)
        self.assertEqual(len(out['Members']), 1)
        self.assertEqual(out['Members'][0]['UserId'], '7')
        self.assertEqual(out['Members'][0]['DisplayName'], 'Real One')

        cg = {
            'LeaderUserIds': ['9', '2'],
            'LeaderAuthIds': ['auth-other'],
            'CreatedByUserID': '9',
        }
        cg_out, cg_changed = rewrite_cell_group(
            cg, '9', '7', survivor_auth_id='auth-7'
        )
        self.assertTrue(cg_changed)
        self.assertEqual(cg_out['LeaderUserIds'], ['7', '2'])
        self.assertEqual(cg_out['CreatedByUserID'], '7')
        self.assertIn('auth-7', cg_out['LeaderAuthIds'])

    def test_rewrite_template_and_heads(self):
        template = {
            'Roles': [{'id': 1, 'uids': ['9']}],
            'ExpectedAttendeeUserIDs': ['9'],
            'Contributors': ['9'],
            'SchedulePresets': [{'roles': [{'id': 1, 'uids': ['9']}]}],
            'ExpectedAttendancePresets': [{'userIds': ['9', '2']}],
            'Logs': [{'uid': '9', 'log': 'x'}],
        }
        out, changed = rewrite_template(template, '9', '7')
        self.assertTrue(changed)
        self.assertEqual(out['Roles'][0]['uids'], ['7'])
        self.assertEqual(out['ExpectedAttendeeUserIDs'], ['7'])
        self.assertEqual(out['Contributors'], ['7'])
        self.assertEqual(out['SchedulePresets'][0]['roles'][0]['uids'], ['7'])
        self.assertEqual(out['ExpectedAttendancePresets'][0]['userIds'], ['7', '2'])
        self.assertEqual(out['Logs'][0]['uid'], '7')

        heads = {'HeadsByLocation': {'Belfast': ['9', '3'], 'Portadown': ['9']}}
        heads_out, heads_changed = rewrite_heads_by_location(heads, '9', '7')
        self.assertTrue(heads_changed)
        self.assertEqual(heads_out['HeadsByLocation']['Belfast'], ['7', '3'])
        self.assertEqual(heads_out['HeadsByLocation']['Portadown'], ['7'])

    def test_merge_lists(self):
        roles = merge_role_lists(
            [{'postID': '1', 'id': 1}],
            [{'postID': '1', 'id': 1}, {'postID': '2', 'id': 3}],
        )
        self.assertEqual(len(roles), 2)
        posts = merge_post_lists(
            [{'id': '1', 'ownership': 'author'}],
            [{'id': '1', 'ownership': 'contributor'}, {'id': '2'}],
        )
        self.assertEqual(len(posts), 2)
        logs = merge_activity_logs(
            [{'log': 'a', 'documentId': '1', 'ts': 1}],
            [{'log': 'a', 'documentId': '1', 'ts': 1}, {'log': 'b', 'documentId': '2', 'ts': 2}],
        )
        self.assertEqual(len(logs), 2)


class MergeImplGateTests(unittest.TestCase):
    def _req(self, **data):
        req = MagicMock()
        req.auth.uid = 'admin-auth'
        req.data = data
        return req

    def _user_doc(self, data, exists=True):
        snap = MagicMock()
        snap.exists = exists
        snap.to_dict.return_value = data
        snap.id = 'unused'
        return snap

    def test_requires_area_admin(self):
        db = MagicMock()
        everyone = MagicMock()
        everyone.get.return_value.exists = True
        everyone.get.return_value.to_dict.return_value = {'isUser': True}
        db.collection.return_value.document.return_value = everyone

        with self.assertRaises(Exception) as ctx:
            merge_placeholder_into_user_impl(
                db,
                self._req(PlaceholderUserID='9', SurvivorUserID='7'),
            )
        self.assertIn('Area admin', str(ctx.exception))

    def test_rejects_non_placeholder_source(self):
        db = MagicMock()

        def collection(name):
            col = MagicMock()
            if name == 'everyone':
                doc = MagicMock()
                doc.get.return_value.exists = True
                doc.get.return_value.to_dict.return_value = {
                    'isAreaAdmin': True
                }
                col.document.return_value = doc
                return col
            if name == 'users':
                def user_doc(uid):
                    ref = MagicMock()
                    if uid == '9':
                        ref.get.return_value = self._user_doc(
                            {
                                'Forename': 'Linked',
                                'Surname': 'Already',
                                'AuthID': 'auth-9',
                                'IsPlaceholder': False,
                            }
                        )
                    else:
                        ref.get.return_value = self._user_doc(
                            {
                                'Forename': 'Real',
                                'Surname': 'One',
                                'AuthID': 'auth-7',
                                'IsPlaceholder': False,
                            }
                        )
                    return ref

                col.document.side_effect = user_doc
                return col
            return MagicMock()

        db.collection.side_effect = collection

        with self.assertRaises(Exception) as ctx:
            merge_placeholder_into_user_impl(
                db,
                self._req(PlaceholderUserID='9', SurvivorUserID='7'),
            )
        self.assertIn('not a placeholder', str(ctx.exception))

    def test_rejects_placeholder_survivor(self):
        db = MagicMock()

        def collection(name):
            col = MagicMock()
            if name == 'everyone':
                doc = MagicMock()
                doc.get.return_value.exists = True
                doc.get.return_value.to_dict.return_value = {
                    'isAreaAdmin': True
                }
                col.document.return_value = doc
                return col
            if name == 'users':
                def user_doc(uid):
                    ref = MagicMock()
                    if uid == '9':
                        ref.get.return_value = self._user_doc(
                            {
                                'Forename': 'Temp',
                                'Surname': 'Person',
                                'AuthID': '',
                                'IsPlaceholder': True,
                            }
                        )
                    else:
                        ref.get.return_value = self._user_doc(
                            {
                                'Forename': 'Other',
                                'Surname': 'Temp',
                                'AuthID': '',
                                'IsPlaceholder': True,
                            }
                        )
                    return ref

                col.document.side_effect = user_doc
                return col
            return MagicMock()

        db.collection.side_effect = collection

        with self.assertRaises(Exception) as ctx:
            merge_placeholder_into_user_impl(
                db,
                self._req(PlaceholderUserID='9', SurvivorUserID='7'),
            )
        self.assertIn('non-placeholder', str(ctx.exception))


if __name__ == '__main__':
    unittest.main()
