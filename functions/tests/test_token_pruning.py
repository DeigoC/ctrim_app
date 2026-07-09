import unittest
from unittest.mock import MagicMock, patch

from token_pruning import is_invalid_token_error, prune_invalid_tokens


class TokenPruningTests(unittest.TestCase):
    def test_is_invalid_token_error_detects_unregistered(self):
        exc = MagicMock()
        exc.code = 'NOT_FOUND'
        exc.__str__ = lambda self: 'Requested entity was not found'
        self.assertTrue(is_invalid_token_error(exc))

    def test_is_invalid_token_error_ignores_other_errors(self):
        exc = MagicMock()
        exc.code = 'INTERNAL'
        exc.__str__ = lambda self: 'temporary failure'
        self.assertFalse(is_invalid_token_error(exc))

    def test_is_invalid_token_error_none(self):
        self.assertFalse(is_invalid_token_error(None))

    @patch('token_pruning.firestore')
    def test_prune_invalid_tokens_removes_web_entry(self, firestore_mock):
        db = MagicMock()
        web_tokens_ref = MagicMock()
        web_topics_ref = MagicMock()

        web_tokens_doc = MagicMock()
        web_tokens_doc.exists = True
        web_tokens_doc.to_dict.return_value = {
            'entries': {'dead-token': {'authId': 'auth-1'}},
        }

        web_topics_doc = MagicMock()
        web_topics_doc.exists = True
        web_topics_doc.to_dict.return_value = {
            'belfast-sunday-service': ['dead-token', 'keep-token'],
        }

        device_ref = MagicMock()
        device_doc = MagicMock()
        device_doc.exists = True
        device_doc.to_dict.return_value = {
            'device_tokens': {'dead-token': 'Web', 'other': 'iOS'},
        }
        device_ref.get.return_value = device_doc

        def collection_side_effect(name):
            col = MagicMock()
            if name == 'notification_tokens':
                def doc_side_effect(doc_id):
                    if doc_id == 'web_tokens':
                        web_tokens_ref.get.return_value = web_tokens_doc
                        return web_tokens_ref
                    if doc_id == 'web_topics':
                        web_topics_ref.get.return_value = web_topics_doc
                        return web_topics_ref
                    return MagicMock()
                col.document.side_effect = doc_side_effect
            elif name == 'everyone':
                everyone_doc = MagicMock()
                supplemental = MagicMock()
                supplemental.document.return_value = device_ref
                everyone_doc.collection.return_value = supplemental
                col.document.return_value = everyone_doc
            return col

        db.collection.side_effect = collection_side_effect
        firestore_mock.DELETE_FIELD = 'DELETE'
        firestore_mock.ArrayRemove = lambda values: ('REMOVE', values)

        pruned = prune_invalid_tokens(db, ['dead-token'])

        self.assertEqual(pruned, 1)
        web_tokens_ref.set.assert_called()
        web_topics_ref.update.assert_called()
        device_ref.update.assert_called()


if __name__ == '__main__':
    unittest.main()
