# Deploy with `firebase deploy --only functions`

from firebase_functions import firestore_fn, https_fn, options
from firebase_admin import firestore, initialize_app, messaging

from fcm_payload import fcm_image_url, is_valid_fcm_topic, looks_like_image_error
from user_role_sync import sync_post_program_roles, sync_program_roles_from_change
from notification_auth import require_notification_sender
from token_pruning import is_invalid_token_error, prune_invalid_tokens
from placeholder_users import (
    backfill_placeholder_flags_impl,
    create_placeholder_user_impl,
    link_user_auth_impl,
)

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


def _https_error_from_fcm(exc: BaseException) -> https_fn.HttpsError:
    return https_fn.HttpsError(
        code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
        message=str(exc) or 'FCM send failed',
    )


def _notification_payload(req_data) -> messaging.Notification:
    return messaging.Notification(
        title=str(req_data.get('Title', '')),
        body=str(req_data.get('Body', '')),
    )


def _apns_android_configs(ios_image: str, android_image: str):
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


def _build_multicast_message(req_data, tokens: list[str]) -> messaging.MulticastMessage:
    data_dict = _parse_data_dict(req_data)
    ios_image = fcm_image_url(req_data.get('iOSImage', ''))
    android_image = fcm_image_url(req_data.get('AndroidImage', ''))

    apns, android = _apns_android_configs(ios_image, android_image)
    return messaging.MulticastMessage(
        tokens=tokens,
        data=data_dict,
        notification=_notification_payload(req_data),
        apns=apns,
        android=android,
    )


def _send_multicast_batches(req_data, tokens: list[str]) -> dict:
    total_success = 0
    total_failure = 0
    invalid_tokens: list[str] = []

    for start in range(0, len(tokens), _FCM_MULTICAST_BATCH_SIZE):
        batch = tokens[start:start + _FCM_MULTICAST_BATCH_SIZE]
        msg = _build_multicast_message(req_data, batch)
        response = messaging.send_each_for_multicast(msg)
        total_success += response.success_count
        total_failure += response.failure_count

        for idx, send_response in enumerate(response.responses):
            if not send_response.success:
                token = batch[idx] if idx < len(batch) else '?'
                token_preview = token[:20] if isinstance(token, str) else '?'
                print(
                    f'FCM send failed for token {token_preview}…: '
                    f'{send_response.exception}'
                )
                if isinstance(token, str) and is_invalid_token_error(send_response.exception):
                    invalid_tokens.append(token)

    pruned_count = 0
    if invalid_tokens:
        try:
            pruned_count = prune_invalid_tokens(firestore.client(), invalid_tokens)
            print(f'Pruned {pruned_count} invalid FCM token(s)')
        except Exception as exc:  # noqa: BLE001 — best-effort cleanup
            print(f'Token prune failed: {exc}')

    return {
        'success_count': total_success,
        'failure_count': total_failure,
        'invalid_token_count': pruned_count,
    }


@https_fn.on_call(region='europe-west1')
def send_notification_to_multiple_tokens(req: https_fn.CallableRequest) -> any:
    require_notification_sender(req)
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


def _build_topic_message(req_data, *, include_images: bool) -> messaging.Message:
    topic = str(req_data.get('Topic', ''))
    data_dict = _parse_data_dict(req_data)
    ios_image = fcm_image_url(req_data.get('iOSImage', '')) if include_images else ''
    android_image = fcm_image_url(req_data.get('AndroidImage', '')) if include_images else ''
    apns, android = _apns_android_configs(ios_image, android_image)
    return messaging.Message(
        topic=topic,
        data=data_dict,
        notification=_notification_payload(req_data),
        apns=apns,
        android=android,
    )


@https_fn.on_call(region='europe-west1')
def send_to_topic(req: https_fn.CallableRequest) -> any:
    require_notification_sender(req)
    topic = str(req.data.get('Topic', ''))
    if not is_valid_fcm_topic(topic):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f'Invalid FCM topic name: {topic!r}',
        )

    data_dict = _parse_data_dict(req.data)
    print(f'--------------- Topic is {topic}')
    print(f'--------------- DataDict is {data_dict}')

    try:
        messaging.send(_build_topic_message(req.data, include_images=True))
    except Exception as exc:  # noqa: BLE001 — map FCM failures to callable errors
        print(f'FCM topic send failed: {exc}')
        if looks_like_image_error(exc):
            try:
                messaging.send(_build_topic_message(req.data, include_images=False))
                return {'result': 'finished sending to topic!', 'image_omitted': True}
            except Exception as retry_exc:  # noqa: BLE001
                print(f'FCM topic retry without image failed: {retry_exc}')
                raise _https_error_from_fcm(retry_exc) from retry_exc
        raise _https_error_from_fcm(exc) from exc

    return {'result': 'finished sending to topic!'}


@https_fn.on_call(region='europe-west1')
def sync_user_roles_for_post(req: https_fn.CallableRequest) -> any:
    """Callable fallback for role sync (no Eventarc). Client invokes after program save."""
    post_id = str(req.data.get('PostID', '')).strip()
    if not post_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message='PostID is required',
        )

    removed_raw = str(req.data.get('RemovedUIDs', '')).strip()
    cleared_uids = [uid.strip() for uid in removed_raw.split(',') if uid.strip()]

    db = firestore.client()
    result = sync_post_program_roles(db, post_id, cleared_uids=cleared_uids or None)
    print(f'sync_user_roles_for_post post={post_id} result={result}')
    return {'result': 'sync complete', **result}


# Optional: auto-sync on program writes. Requires Eventarc IAM on first deploy —
# if deploy fails with "Eventarc Service Agent", use sync_user_roles_for_post above
# or wait a few minutes and retry.
@firestore_fn.on_document_written(
    document='events/{postId}/supplemental/program',
    region='europe-west1',
)
def sync_user_roles_on_program_write(event: firestore_fn.Event[firestore_fn.Change | None]) -> None:
    """Keep users/{uid}/supplemental/roles in sync when program docs change."""
    if event.data is None:
        return

    post_id = event.params['postId']
    db = firestore.client()

    before_program = None
    after_program = None
    if event.data.before is not None and event.data.before.exists:
        before_program = event.data.before.to_dict()
    if event.data.after is not None and event.data.after.exists:
        after_program = event.data.after.to_dict()

    result = sync_program_roles_from_change(db, post_id, before_program, after_program)
    print(f'sync_user_roles_on_program_write post={post_id} result={result}')


@https_fn.on_call(region='europe-west1')
def create_placeholder_user(req: https_fn.CallableRequest) -> any:
    """Mint a placeholder users/{id} doc (IsPlaceholder, empty AuthID, CreatedByUserID)."""
    db = firestore.client()
    result = create_placeholder_user_impl(db, req)
    print(f'create_placeholder_user id={result.get("Id")}')
    return result


@https_fn.on_call(region='europe-west1')
def link_user_auth(req: https_fn.CallableRequest) -> any:
    """Link AuthID on a volunteer profile; clears IsPlaceholder. Creator or area admin."""
    db = firestore.client()
    result = link_user_auth_impl(db, req)
    print(f'link_user_auth user={result.get("Id")}')
    return result


@https_fn.on_call(region='europe-west1')
def backfill_placeholder_flags(req: https_fn.CallableRequest) -> any:
    """One-shot: empty AuthID users → IsPlaceholder true (CreatedByUserID left empty)."""
    db = firestore.client()
    result = backfill_placeholder_flags_impl(db, req)
    print(f'backfill_placeholder_flags updated={result.get("updated")}')
    return result
