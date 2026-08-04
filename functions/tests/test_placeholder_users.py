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


if __name__ == '__main__':
    unittest.main()
