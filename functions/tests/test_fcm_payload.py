import unittest

from fcm_payload import (
    fcm_image_url,
    is_valid_fcm_topic,
    looks_like_image_error,
    web_click_link,
)


class FcmPayloadTests(unittest.TestCase):
    def test_is_valid_fcm_topic(self):
        self.assertTrue(is_valid_fcm_topic('Belfast'))
        self.assertTrue(is_valid_fcm_topic('belfast-sunday-service'))
        self.assertTrue(is_valid_fcm_topic('Portadown'))
        self.assertFalse(is_valid_fcm_topic('North Coast'))
        self.assertFalse(is_valid_fcm_topic(''))

    def test_fcm_image_url_strips_drive_and_non_https(self):
        self.assertEqual(
            fcm_image_url('https://example.com/cover.png'),
            'https://example.com/cover.png',
        )
        self.assertEqual(
            fcm_image_url('https://drive.google.com/uc?id=abc123'),
            '',
        )
        self.assertEqual(
            fcm_image_url(
                'https://drive.google.com/file/d/abc123/view?usp=sharing'
            ),
            '',
        )
        self.assertEqual(fcm_image_url('http://example.com/cover.png'), '')
        self.assertEqual(fcm_image_url(''), '')
        self.assertEqual(fcm_image_url(None), '')

    def test_looks_like_image_error(self):
        self.assertTrue(
            looks_like_image_error(
                Exception('The notification image provided is invalid')
            )
        )
        self.assertFalse(looks_like_image_error(Exception('invalid topic')))

    def test_web_click_link(self):
        self.assertEqual(
            web_click_link({'PostID': 'post-42'}),
            'https://ctrim.app/?postId=post-42',
        )
        self.assertEqual(
            web_click_link({'InfoPage': 'core values'}),
            'https://ctrim.app/?infoPage=core%20values',
        )
        self.assertEqual(web_click_link({}), 'https://ctrim.app/')
        self.assertEqual(web_click_link(None), 'https://ctrim.app/')


if __name__ == '__main__':
    unittest.main()
