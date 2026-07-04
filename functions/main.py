# Deploy with `firebase deploy --only functions`

from firebase_functions import https_fn, options
from firebase_admin import initialize_app, messaging

initialize_app()
options.set_global_options(max_instances=10, region='europe-west1')

_FCM_MULTICAST_BATCH_SIZE = 500


def _parse_tokens(tokens_value) -> list[str]:
    return [t.strip() for t in str(tokens_value).split(',') if t.strip()]


def _parse_data_dict(req_data) -> dict[str, str]:
    data_keys = str(req_data.get('DataKeys', ''))
    data_values = str(req_data.get('DataValues', ''))

    if not data_keys:
        return {}

    if ',' in data_keys:
        keys = data_keys.split(',')
        values = data_values.split(',')
        return {
            keys[i]: values[i] if i < len(values) else ''
            for i in range(len(keys))
        }

    return {data_keys: data_values}


def _build_multicast_message(req_data, tokens: list[str]) -> messaging.MulticastMessage:
    data_dict = _parse_data_dict(req_data)
    ios_image = str(req_data.get('iOSImage', '')).strip()
    android_image = str(req_data.get('AndroidImage', '')).strip()

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

    return messaging.MulticastMessage(
        tokens=tokens,
        data=data_dict,
        notification=messaging.Notification(
            title=req_data['Title'],
            body=req_data['Body'],
        ),
        apns=apns,
        android=android,
    )


def _send_multicast_batches(req_data, tokens: list[str]) -> dict:
    total_success = 0
    total_failure = 0

    for start in range(0, len(tokens), _FCM_MULTICAST_BATCH_SIZE):
        batch = tokens[start:start + _FCM_MULTICAST_BATCH_SIZE]
        msg = _build_multicast_message(req_data, batch)
        response = messaging.send_each_for_multicast(msg)
        total_success += response.success_count
        total_failure += response.failure_count

        for idx, send_response in enumerate(response.responses):
            if not send_response.success:
                token_preview = batch[idx][:20] if idx < len(batch) else '?'
                print(
                    f'FCM send failed for token {token_preview}…: '
                    f'{send_response.exception}'
                )

    return {
        'success_count': total_success,
        'failure_count': total_failure,
    }


@https_fn.on_call(region='europe-west1')
def send_notification_to_multiple_tokens(req: https_fn.CallableRequest) -> any:
    tokens = _parse_tokens(req.data['Tokens'])
    if not tokens:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message='No valid tokens provided',
        )

    data_dict = _parse_data_dict(req.data)
    print(f'--------------- Token count: {len(tokens)}')
    print(f'--------------- DataDict is {data_dict}')

    result = _send_multicast_batches(req.data, tokens)
    print(
        '--------------- Multicast result: '
        f"success={result['success_count']} failure={result['failure_count']}"
    )

    return {
        'result': 'finished sending to multiple devices',
        **result,
    }


@https_fn.on_call(region='europe-west1')
def send_to_topic(req: https_fn.CallableRequest) -> any:
    topic = str(req.data['Topic'])
    data_dict = _parse_data_dict(req.data)
    ios_image = str(req.data.get('iOSImage', '')).strip()
    android_image = str(req.data.get('AndroidImage', '')).strip()

    print(f'--------------- Topic is {topic}')
    print(f'--------------- DataDict is {data_dict}')

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

    msg = messaging.Message(
        topic=topic,
        data=data_dict,
        notification=messaging.Notification(
            title=req.data['Title'],
            body=req.data['Body'],
        ),
        apns=apns,
        android=android,
    )

    messaging.send(msg)
    return {'result': 'finished sending to topic!'}
