"""Regression: multicast builder must keep web_click_link after schedule refactor."""

import unittest

import main


class MainMulticastTests(unittest.TestCase):
    def test_build_multicast_message_sets_web_click_link(self):
        msg = main._build_multicast_message(
            {
                'Title': 'Hello',
                'Body': 'World',
                'DataKeys': 'PostID',
                'DataValues': 'post-99',
            },
            ['token-a'],
        )
        self.assertEqual(msg.tokens, ['token-a'])
        self.assertEqual(msg.notification.title, 'Hello')
        self.assertEqual(
            msg.webpush.fcm_options.link,
            'https://ctrim.app/post/post-99',
        )


if __name__ == '__main__':
    unittest.main()
