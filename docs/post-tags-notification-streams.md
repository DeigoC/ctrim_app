# Post tags & location-aware notification streams

> **Purpose:** Living design for content tags (bulletin filtering) vs FCM notification streams.  
> **Created:** 2026-08-01  
> **Status:** Implemented (V1)  
> **Start here in a new chat:** “Continue post tags from `docs/post-tags-notification-streams.md`”

---

## Three layers

| Layer | Job | Storage |
|-------|-----|---------|
| **Location** | Where the event is | `events/{id}.Location` (string name) |
| **Content tags** | Browse / filter bulletin | Admin catalog `post_tags/{id}`; IDs on head + metadata + templates as `TagIDs` |
| **Notify streams** | Who gets push | Derived: `{locationSlug}-{streamKind}` (+ location umbrella) |

Do **not** treat free-form content tags as raw FCM topic strings.

## Belfast stability

Existing Belfast FCM IDs stay frozen:

- Umbrella: `Belfast`
- Streams: `belfast-sunday-service`, `belfast-midweek-service`, …

`NotificationTopics.streamTopic(locationName:, streamKind:)` must keep producing these for Belfast.

## PostTag fields

Same shape as `UserTag`, plus optional:

- `StreamKind` — if set, tag is notifiable; FCM topic = `streamTopic(post.location, streamKind)`

## Sync rules

1. `TagIDs` denormalized on **EventHead** (bulletin filter) and **EventMetadata** (source of truth with Topics).
2. On save / tag change / location change: recompute `metadata.Topics` from location + notifiable tags (+ optional location umbrella), preserving legacy Topics only when there are no notifiable tags.
3. Templates store `TagIDs`; mapper copies them and syncs Topics.
4. **Edit existing posts:** Title & details (`EditHeadDetailsPage`) — same picker as create/template; save via normal post update.

## Caching

Tag/location **catalogs** are small and loaded once per session into `AppContext`. Hive caching is optional/overkill until cold-start cost is noticeable. Assigned `TagIDs` ride on event heads already fetched for the bulletin.

## User prefs

Prefs keys remain `topic_{fcmTopicId}`. UI groups by location (from `user_locations`) × stream kinds (from post tags with `StreamKind`, else hardcoded Belfast service kinds).

## Deploy

- Deploy `firestore.rules` for `post_tags` before admin CRUD in production (`isAreaAdmin || isAdmin`, same as `user_locations`).
- Seed starter tags from Manage Post Tags (area admins; includes stream kinds matching current Belfast services).
