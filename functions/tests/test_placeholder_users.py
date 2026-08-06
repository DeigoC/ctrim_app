"""Unit tests for placeholder user helpers (no Firestore).

Permission helpers are exercised via lightweight stubs — firebase_admin is
mocked so tests run without the Functions runtime installed.
"""

import sys
import types
import unittest
from unittest.mock import MagicMock

# Soft-stub firebase deps so unit tests import without the CF venv.
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

from placeholder_users import (  # noqa: E402
    _caller_may_create_placeholder,
    _caller_may_link_auth,
    _is_area_or_global_admin,
    link_user_auth_impl,
)


class PlaceholderPermissionTests(unittest.TestCase):
    def test_is_area_or_global_admin(self):
        self.assertTrue(_is_area_or_global_admin({'isAreaAdmin': True}))
        self.assertTrue(_is_area_or_global_admin({'isAdmin': True}))
        self.assertFalse(_is_area_or_global_admin({'isUser': True}))

    def test_create_allows_area_admin(self):
        db = MagicMock()
        everyone = MagicMock()
        everyone.get.return_value.exists = True
        everyone.get.return_value.to_dict.return_value = {'isAreaAdmin': True}
        db.collection.return_value.document.return_value = everyone

        self.assertTrue(
            _caller_may_create_placeholder(
                db,
                auth_uid='auth-a',
                caller_volunteer_id='1',
                post_id='',
            )
        )

    def test_create_allows_post_author(self):
        db = MagicMock()

        everyone_doc = MagicMock()
        everyone_doc.exists = True
        everyone_doc.to_dict.return_value = {'isUser': True}

        meta_doc = MagicMock()
        meta_doc.exists = True
        meta_doc.to_dict.return_value = {'AuthorUID': '7'}

        def collection(name):
            col = MagicMock()
            if name == 'everyone':
                col.document.return_value.get.return_value = everyone_doc
            elif name == 'events':
                supplemental = MagicMock()
                supplemental.document.return_value.get.return_value = meta_doc
                col.document.return_value.collection.return_value = supplemental
            return col

        db.collection.side_effect = collection

        self.assertTrue(
            _caller_may_create_placeholder(
                db,
                auth_uid='auth-b',
                caller_volunteer_id='7',
                post_id='post-1',
            )
        )

    def test_create_denies_non_author(self):
        db = MagicMock()

        everyone_doc = MagicMock()
        everyone_doc.exists = True
        everyone_doc.to_dict.return_value = {'isUser': True}

        meta_doc = MagicMock()
        meta_doc.exists = True
        meta_doc.to_dict.return_value = {'AuthorUID': '7'}

        def collection(name):
            col = MagicMock()
            if name == 'everyone':
                col.document.return_value.get.return_value = everyone_doc
            elif name == 'events':
                supplemental = MagicMock()
                supplemental.document.return_value.get.return_value = meta_doc
                col.document.return_value.collection.return_value = supplemental
            return col

        db.collection.side_effect = collection

        self.assertFalse(
            _caller_may_create_placeholder(
                db,
                auth_uid='auth-c',
                caller_volunteer_id='8',
                post_id='post-1',
            )
        )

    def test_create_allows_cell_group_leader(self):
        db = MagicMock()

        everyone_doc = MagicMock()
        everyone_doc.exists = True
        everyone_doc.to_dict.return_value = {'isUser': True}

        cg_doc = MagicMock()
        cg_doc.exists = True
        cg_doc.to_dict.return_value = {'LeaderUserIds': ['9', '10']}

        def collection(name):
            col = MagicMock()
            if name == 'everyone':
                col.document.return_value.get.return_value = everyone_doc
            elif name == 'cell_groups':
                col.document.return_value.get.return_value = cg_doc
            return col

        db.collection.side_effect = collection

        self.assertTrue(
            _caller_may_create_placeholder(
                db,
                auth_uid='auth-d',
                caller_volunteer_id='9',
                post_id='',
                cell_group_id='cg-1',
            )
        )

    def test_link_allows_creator_while_placeholder(self):
        db = MagicMock()
        creator = MagicMock()
        creator.exists = True
        creator.to_dict.return_value = {'AuthID': 'auth-creator'}
        db.collection.return_value.document.return_value.get.return_value = creator

        self.assertTrue(
            _caller_may_link_auth(
                db,
                auth_uid='auth-creator',
                flags={'isUser': True},
                target={'IsPlaceholder': True, 'CreatedByUserID': '2', 'AuthID': ''},
                target_had_auth=False,
            )
        )

    def test_link_freezes_after_auth_for_non_admin(self):
        db = MagicMock()
        self.assertFalse(
            _caller_may_link_auth(
                db,
                auth_uid='auth-creator',
                flags={'isUser': True},
                target={'IsPlaceholder': False, 'CreatedByUserID': '2', 'AuthID': 'auth-x'},
                target_had_auth=True,
            )
        )


class LinkUserAuthImplTests(unittest.TestCase):
    def _make_req(self, data, uid='admin-auth'):
        req = MagicMock()
        req.auth = MagicMock()
        req.auth.uid = uid
        req.data = data
        return req

    def _db_for_link(
        self,
        *,
        everyone_flags,
        target_user,
        everyone_exists=True,
        conflict=None,
        caller_uid='admin-auth',
    ):
        db = MagicMock()

        caller_everyone_snap = MagicMock()
        caller_everyone_snap.exists = True
        caller_everyone_snap.to_dict.return_value = everyone_flags
        caller_everyone_ref = MagicMock()
        caller_everyone_ref.get.return_value = caller_everyone_snap

        target_everyone_snap = MagicMock()
        target_everyone_snap.exists = everyone_exists
        target_everyone_ref = MagicMock()
        target_everyone_ref.get.return_value = target_everyone_snap

        user_snap = MagicMock()
        user_snap.exists = True
        user_snap.to_dict.return_value = target_user
        user_ref = MagicMock()
        user_ref.get.return_value = user_snap

        conflict_query = MagicMock()
        conflict_query.limit.return_value.get.return_value = conflict or []

        def collection(name):
            col = MagicMock()
            if name == 'everyone':
                def everyone_doc_for(doc_id):
                    if doc_id == caller_uid:
                        return caller_everyone_ref
                    return target_everyone_ref

                col.document.side_effect = everyone_doc_for
            elif name == 'users':
                col.document.return_value = user_ref
                col.where.return_value = conflict_query
            return col

        db.collection.side_effect = collection
        return db, user_ref, target_everyone_ref

    def test_link_syncs_area_admin_to_everyone_and_users(self):
        target = {
            'Forename': 'Temp',
            'Surname': 'User',
            'AuthID': '',
            'IsPlaceholder': True,
            'IsAreaAdmin': False,
            'IsLeader': False,
            'CreatedByUserID': '1',
        }
        db, user_ref, everyone_ref = self._db_for_link(
            everyone_flags={'isAreaAdmin': True},
            target_user=target,
        )
        req = self._make_req(
            {
                'UserID': '42',
                'AuthID': 'new-auth',
                'IsLeader': True,
                'IsAreaAdmin': True,
            }
        )

        result = link_user_auth_impl(db, req)

        user_ref.update.assert_called_once()
        updates = user_ref.update.call_args[0][0]
        self.assertEqual(updates['AuthID'], 'new-auth')
        self.assertFalse(updates['IsPlaceholder'])
        self.assertTrue(updates['IsAreaAdmin'])
        self.assertTrue(updates['IsLeader'])

        everyone_ref.set.assert_called()
        payload = everyone_ref.set.call_args[0][0]
        self.assertTrue(payload['isUser'])
        self.assertTrue(payload['isAreaAdmin'])
        self.assertTrue(payload['isLeader'])

        self.assertFalse(result['IsPlaceholder'])
        self.assertTrue(result['IsAreaAdmin'])

    def test_link_falls_back_to_users_area_admin_when_omitted(self):
        target = {
            'Forename': 'Temp',
            'Surname': 'User',
            'AuthID': '',
            'IsPlaceholder': True,
            'IsAreaAdmin': True,
            'IsLeader': False,
            'CreatedByUserID': '1',
        }
        db, user_ref, everyone_ref = self._db_for_link(
            everyone_flags={'isAreaAdmin': True},
            target_user=target,
        )
        # Old clients omit IsAreaAdmin
        req = self._make_req({'UserID': '42', 'AuthID': 'new-auth', 'IsLeader': False})

        link_user_auth_impl(db, req)

        payload = everyone_ref.set.call_args[0][0]
        self.assertTrue(payload['isAreaAdmin'])
        updates = user_ref.update.call_args[0][0]
        self.assertTrue(updates['IsAreaAdmin'])

    def test_link_non_admin_cannot_grant_area_admin(self):
        target = {
            'Forename': 'Temp',
            'Surname': 'User',
            'AuthID': '',
            'IsPlaceholder': True,
            'IsAreaAdmin': False,
            'IsLeader': False,
            'CreatedByUserID': '2',
        }

        db = MagicMock()
        user_ref = MagicMock()
        user_snap = MagicMock()
        user_snap.exists = True
        user_snap.to_dict.return_value = target
        user_ref.get.return_value = user_snap

        creator_snap = MagicMock()
        creator_snap.exists = True
        creator_snap.to_dict.return_value = {'AuthID': 'creator-auth'}
        creator_ref = MagicMock()
        creator_ref.get.return_value = creator_snap

        caller_everyone_snap = MagicMock()
        caller_everyone_snap.exists = True
        caller_everyone_snap.to_dict.return_value = {'isUser': True}
        caller_everyone_ref = MagicMock()
        caller_everyone_ref.get.return_value = caller_everyone_snap

        target_everyone_snap = MagicMock()
        target_everyone_snap.exists = True
        target_everyone_ref = MagicMock()
        target_everyone_ref.get.return_value = target_everyone_snap

        conflict_query = MagicMock()
        conflict_query.limit.return_value.get.return_value = []

        def collection(name):
            col = MagicMock()
            if name == 'everyone':
                def everyone_doc_for(doc_id):
                    if doc_id == 'creator-auth':
                        return caller_everyone_ref
                    return target_everyone_ref

                col.document.side_effect = everyone_doc_for
            elif name == 'users':
                def user_doc_for(doc_id):
                    if doc_id == '2':
                        return creator_ref
                    return user_ref

                col.document.side_effect = user_doc_for
                col.where.return_value = conflict_query
            return col

        db.collection.side_effect = collection
        req = self._make_req(
            {
                'UserID': '42',
                'AuthID': 'new-auth',
                'IsLeader': True,
                'IsAreaAdmin': True,
            },
            uid='creator-auth',
        )

        link_user_auth_impl(db, req)

        updates = user_ref.update.call_args[0][0]
        self.assertEqual(updates['AuthID'], 'new-auth')
        self.assertFalse(updates['IsPlaceholder'])
        self.assertNotIn('IsAreaAdmin', updates)
        self.assertNotIn('IsLeader', updates)

        payload = target_everyone_ref.set.call_args[0][0]
        self.assertEqual(payload, {'isUser': True})
        self.assertNotIn('isAreaAdmin', payload)
        self.assertNotIn('isLeader', payload)
if __name__ == '__main__':
    unittest.main()
