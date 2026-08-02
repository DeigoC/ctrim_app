# Post attendance & interest — design & V1 plan

> **Purpose:** Living handoff for adding attendees + public interest on event posts.  
> **Created:** 2026-07-20  
> **Status:** V1 implemented (client + rules) — deploy `firestore.rules` before testing privacy  
> **Start here in a new chat:** “Continue post attendance/interest from `docs/post-attendance-interest.md`”

---

## Goals

1. Let **authors/contributors** manage who is **attending** a post (registered users + free-text guests).
2. Let **any signed-in user** mark **interest** in a post (public by name for signed-in; count-only for anonymous guests).
3. Treat interest as “follow updates” (subscribe to existing FCM `post-{id}` / bookmark path).
4. Ship a **V1** that feels real in the UI (counts on cards, detail on post) without boiling the ocean.

Non-goals for V1: capacity/waitlist, personal Going/Interested home filter (phase 2), merge free-text → registered user, replacing all bookmarks globally.

---

## Locked product decisions (2026-07-20)

| # | Topic | Decision |
|---|--------|----------|
| 1 | Who can mark interest | Any **Firebase Auth** session (including signed-in but not yet `isUser` volunteer). **Not** anonymous guests. |
| 2 | Name visibility | Signed-in: names. Anonymous guests: **counts only** + CTA to register/sign in. |
| 3 | Interest ⇒ follow updates | **Yes** — marking interest also bookmarks / subscribes to `post-{id}`. |
| 4 | Attendee sources | Registered `users` **and** free-text external names (people not registered yet). |
| 5 | Both lists | A person **can** be interested and attending. |
| 6 | Past events | Both lists stay **editable** after the event date (updates continue). |
| 7 | UI | Counts on event cards; detail on post (tab/section); guest CTA when names are hidden. |
| 8 | EventHead denorm | **Counts only** on head (`interestedCount`, `attendeeCount`). Full lists in supplemental — **not** full name lists on head. |
| 9 | Interest vs bookmark | Interest **wraps** bookmark for posts that support it (one public action). Keep legacy bookmark UX where needed; full migration optional later. |
| 10 | Who manages attendees | Author / contributors (same soft gate as edit UI today). Free-text is **staff-owned**, not self-serve. |
| 11 | Who manages interest | Self-serve add/remove for signed-in; **author/contributors may remove** someone’s interest (moderation). Authors do **not** add interest on behalf of others. |
| 12 | Promote interested → attendee | Implemented: one-tap for author/contributor; keeps interest (both lists allowed). |
| 13 | Capacity / waitlist | **Out of scope** for V1. |
| 14 | Personal “Going / Interested” filter | **Phase 2** (needs user-side denorm). |
| 15 | Free-text merge on later register | **Deferred** — leave duplicate possible for V1. |
| 16 | Interest spam notifications | Do **not** FCM-blast author on every interest. Optional quiet EventLog later; not required for V1. |

---

## Critical security constraint

Today `firestore.rules` allow **world read** on `events/{documents=**}`:

```
allow read: if true;
allow write: if … isUser == true;
```

**Client-only hiding of names is not privacy.** If names live in a world-readable supplemental doc, guests (or any client) can still fetch them.

V1 **must** split public vs private data:

| Surface | Contents | Read access |
|---------|----------|-------------|
| Public counts | `interestedCount`, `attendeeCount` on `EventHead` (or tiny public summary doc) | Anyone (including guests) |
| Private lists | Names, authIds/uids, free-text entries | **Signed-in only** (`request.auth != null`) |

Interest **writes** also cannot rely on today’s “any `isUser` may write entire event tree”:

- Signed-in non-volunteers need to toggle **only their own** interest entry + bump count.
- Prefer **field-scoped rules** and/or a **Cloud Function** for interest mutations. Attendee list edits can stay author/contributor UX with tighter rules if feasible, or same worker write path as today for V1 (soft gate) — but interest self-serve must work for any Auth.

---

## How this maps onto existing architecture

### Post shape today

```
events/{postId}                          ← EventHead (list/card)
  supplemental/
    body | metadata | program | media | logs
```

Metadata already has `AuthorUID`, `ContributorUIDs`. Program role `uids` are **staffing**, not RSVP — **do not** overload roles or `sync_user_roles_for_post`.

### Closest existing “follow” path

- Local bookmarks: `AppSharedPreferences.bookmarkedPosts`
- FCM topic: `NotificationTopics.postTopic(postId)` → `post-{id}`
- Update notify on log save: `event_log_dialog.dart` → topic + admin tokens
- Unused cloud bookmarks: `EveryoneDBManager.updateBookmarkForAuthID` (never called from UI)

Interest V1 should reuse the bookmark + `post-{id}` subscribe path when the user marks interest.

### Identity ladder

| State | Meaning in app | Attendance/interest |
|-------|----------------|---------------------|
| Anonymous guest | `User(id: '0')`, no Auth | Counts + register CTA only; no interest toggle |
| Signed-in account | Firebase Auth + `everyone/{authId}` | See names; mark interest (even before volunteer) |
| Volunteer / worker | `users` profile + `everyone.isUser` | Above + author/contributor can manage attendees |

Two IDs: volunteer `users/{uid}` vs Auth `everyone/{authId}`. Prefer:

- **Interest** keyed by **authId** (always available when signed in); resolve display name from `users` via `AuthID` when a profile exists, else fallback (email local-part / “Signed-in user”).
- **Attendees (registered)** keyed by **user uid**; **external** by free-text name (+ optional note).

---

## Proposed data model (V1)

### EventHead additions (public)

```json
{
  "InterestedCount": 0,
  "AttendeeCount": 0
}
```

Keep existing Title/Subtitle/Location/Media/RecentDate/EventDate. Counts must stay in sync with private list mutations (client transaction or CF).

### Supplemental private doc (signed-in read)

Suggested path: `events/{postId}/supplemental/attendance`

```json
{
  "interested": [
    {
      "authId": "<firebase auth uid>",
      "userId": "<users uid or null>",
      "displayName": "Jane Doe",
      "ts": "<Timestamp>"
    }
  ],
  "attendees": [
    {
      "type": "user",
      "userId": "<users uid>",
      "displayName": "Jane Doe",
      "addedBy": "<users uid of author/contributor>",
      "ts": "<Timestamp>"
    },
    {
      "type": "external",
      "name": "Maria Guest",
      "note": "optional",
      "addedBy": "<users uid>",
      "ts": "<Timestamp>"
    }
  ]
}
```

Alternative: two docs (`interested` / `attendees`) if that simplifies rules. Either is fine; pick one and stick to it.

### Rules sketch (implement carefully)

- `events/{id}` (head): read anyone; write counts only via controlled path (same as list mutations).
- `events/{id}/supplemental/attendance`: **read if `request.auth != null`**; write via CF preferred, or rules that only allow:
  - caller add/remove own entry in `interested`
  - author/contributor (match metadata — expensive in rules) or `isUser` for attendee array edits in V1 soft gate

If matching author in rules is too heavy for V1, use Cloud Functions for all attendance mutations and deny direct client writes to the private doc.

### Phase 2 (not V1): user denorm

```
users/{uid}/supplemental/…  // posts I’m attending / interested in
```

Enables personal “Going / Interested” filter without scanning all events.

---

## UI (V1)

| Surface | Behaviour |
|---------|-----------|
| Events home card | Show “N interested · M attending” when counts &gt; 0 (from head). |
| View event (signed-in) | Section/tab: interested list + attend list; toggle “I’m interested”; author/contributor edit attendees (pick user + add free-text). |
| View event (guest) | Counts only + short copy encouraging sign-in/register to see who’s interested / attending. |
| Bookmark | Marking interest also bookmarks + FCM subscribe; clearing interest should unbookmark **if** interest was the source (define carefully so manual bookmarks aren’t wiped incorrectly — simplest V1: interest always keeps bookmark in sync). |

Do not put business logic in `build`. Follow existing `EventContext` patterns for load/save.

---

## Suggested V1 implementation phases

### Phase A — Models & storage

- [x] `EventHead`: `interestedCount` / `attendeeCount` (+ `fromMap` / `toJson` / tests)
- [x] New model(s) for attendance supplemental (`event_attendance.dart`; interested map keyed by authId)
- [x] DB manager methods on event supplemental (fetch / setOwnInterest / removeInterest / saveAttendees)
- [x] Firestore rules: private `attendance` signed-in read; public counts on head; self-serve interest writes
- [x] Decision: **client transactions + rules** (no CF in this repo); interested stored as map for rule-friendly self-toggles

### Phase B — Interest (self-serve)

- [x] Signed-in toggle on view event **People** tab
- [x] Wrap bookmark + `post-{id}` subscribe/unsubscribe
- [x] Guest UI: count + CTA to create account
- [x] Author/contributor can remove an interested entry
- [x] Keep counts consistent (transaction updates head)

### Phase C — Attendees (staff-managed)

- [x] Author/contributor UI: add/remove registered user from directory
- [x] Add/remove free-text external guest
- [x] Promote from interested → attendee (author/contributor one-tap; keeps interest)
- [x] Counts on head

### Phase D — Polish & verify

- [x] Card chips on events home (`PostHead`)
- [x] Unit tests for models
- [x] Analyzer / unit tests for models
- [ ] Manual: guest vs signed-in vs author paths; confirm guests cannot read name doc via rules (**requires deploying rules**)
- [x] Update this doc status
- [ ] Run `maintain-agent-docs` after real-world feel / any convention tweaks

### Implementation notes (2026-07-20)

| Choice | What we shipped |
|--------|-----------------|
| Storage | One doc `events/{id}/supplemental/attendance` |
| Interested shape | Map keyed by `authId` (not array) for Firestore self-write rules |
| Mutations | Client `runTransaction` in `EventSupplementalDBManager` |
| UI | Always-on **People** tab on `ViewEventPage`; counts on `PostHead` |
| New post | Empty attendance doc created in `EventContext.addNewPost` |

**Deploy:** `firestore.rules` must be deployed for name privacy. Until then, old catch-all read still applies if an older ruleset is live.

---

## Key files (current codebase)

| Area | Path |
|------|------|
| Event head | `lib/models/event/event_head.dart` |
| Metadata / authors | `lib/models/event/event_metadata.dart` |
| Event context | `lib/utility/event_context.dart` |
| Event Firestore | `lib/firebase/db_managers/event_db_manager.dart` |
| Everyone / bookmarks cloud | `lib/firebase/db_managers/everyone_db_manager.dart` |
| Local bookmarks | `lib/utility/app_shared_preferences.dart` |
| Topics | `lib/utility/notification_topics.dart` |
| Subscribe | `lib/utility/notification_subscription_service.dart` |
| View post + bookmark | `lib/pages/events/view_event_page.dart` |
| Log save → notify bookmarkers | `lib/widgets/posts/event_log_dialog.dart` |
| Rules | `firestore.rules` |
| Guest vs user | `lib/utility/app_context.dart` (`User(id: '0')`) |
| Account registration (not RSVP) | `lib/widgets/guest_registration_card.dart` |
| Related identity work | `docs/users-volunteers-improvement.md` |

---

## Explicit non-reuse

| Existing thing | Why not |
|----------------|---------|
| Program roles / `for_guests` | Staffing + CF role sync, not RSVP |
| `UserPostInvolvement` author/contributor | Editors, not attendees |
| GuestRegistrationCard | App account signup, not event attendance |
| World-readable single attendance doc with UI filter | Leaks names to guests |

---

## Open implementation choices (OK to decide in implementing chat)

1. **One supplemental doc vs two** for interested vs attendees.
2. **Cloud Function vs client + rules** for interest toggle (CF is safer for non-`isUser` Auth and count integrity).
3. Exact **displayName** fallback when signed-in user has no `users` profile yet.
4. Whether clearing interest **always** removes bookmark, or only if no independent bookmark intent (V1 simplest: keep them synced).
5. Whether attendee edits for V1 stay on soft author/contributor UX with existing worker write rules, or harden immediately.

---

## Conversation summary (for context)

Discussed in chat 2026-07-20: feature is feasible on the existing post + supplemental framework. Distilled into two lists (staff attendees vs self-serve interest). Bookmarks are the private follow mechanism today; interest should become the public follow. Guest privacy requires a **server-enforced** count/name split. V1 ships core concept for feel/testing; personal filters and free-text merge are later.

When implementing, prefer minimal diffs, no `pubspec` version bumps, no `print()`, no Firestore in pages (use managers), and tests for new models.
