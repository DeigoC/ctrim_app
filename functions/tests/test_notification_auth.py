import unittest
from unittest.mock import MagicMock, patch

from notification_auth import can_send_notifications


class NotificationAuthTests(unittest.TestCase):
    def test_can_send_notifications_from_custom_claims(self):
        self.assertTrue(
            can_send_notifications('uid-1', {'isLeader': True}),
        )
        self.assertTrue(
            can_send_notifications('uid-1', {'isAreaAdmin': True}),
        )
        self.assertFalse(
            can_send_notifications('uid-1', {}),
        )

    @patch('notification_auth.firestore')
    def test_can_send_notifications_from_firestore_is_user(self, firestore_mock):
        doc = MagicMock()
        doc.exists = True
        doc.to_dict.return_value = {'isUser': True}
        firestore_mock.client.return_value.collection.return_value.document.return_value.get.return_value = doc

        self.assertTrue(can_send_notifications('uid-1', None))

    @patch('notification_auth.firestore')
    def test_can_send_notifications_denies_unknown_user(self, firestore_mock):
        doc = MagicMock()
        doc.exists = False
        firestore_mock.client.return_value.collection.return_value.document.return_value.get.return_value = doc

        self.assertFalse(can_send_notifications('uid-1', None))


if __name__ == '__main__':
    unittest.main()
