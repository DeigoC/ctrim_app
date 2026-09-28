"""FCM topic message shared by callable sends and scheduled reminders."""

from __future__ import annotations

from firebase_admin import messaging

from fcm_payload import web_click_link


def apns_android_configs(ios_image: str, android_image: str):
    apns = messaging.APNSConfig(
        payload=messaging.APNSPayload(aps=messaging.Aps(mutable_content=True)),
    )
    if ios_image:
        apns = messaging.APNSConfig(
            payload=messaging.APNSPayload(aps=messaging.Aps(mutable_content=True)),
            fcm_options=messaging.APNSFCMOptions(image=ios_image),
        )

    android = messaging.AndroidConfig()
    if android_image:
        android = messaging.AndroidConfig(
            notification=messaging.AndroidNotification(image=android_image),
        )
    return apns, android


def build_topic_message(
    *,
    topic: str,
    title: str,
    body: str,
    data: dict[str, str],
    ios_image: str,
    android_image: str,
) -> messaging.Message:
    apns, android = apns_android_configs(ios_image, android_image)
    return messaging.Message(
        topic=topic,
        data=data,
        notification=messaging.Notification(title=title, body=body),
        apns=apns,
        android=android,
        webpush=messaging.WebpushConfig(
            fcm_options=messaging.WebpushFCMOptions(
                link=web_click_link(data),
            ),
        ),
    )
