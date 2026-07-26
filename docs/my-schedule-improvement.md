# My Schedule — review findings & recommendations

> **Purpose:** Handoff doc for a follow-up chat to improve `ViewUserRolesPage` (My Schedule) and related schedule UX.  
> **Created:** 2026-07-05  
> **Start here in a new chat:** “Continue My Schedule improvements from `docs/my-schedule-improvement.md`”

---

## Scope note

**My Schedule** is in the **Personal** section, not Information.

| Entry | File |
|-------|------|
| Menu item | `lib/pages/personal_home.dart` (`mySchedule` / `_onViewTasksClick`) |
| Schedule UI | `lib/pages/personal/view_user_roles_page.dart` |
| Shared logic | `lib/utility/user_schedule_service.dart` |
| Badge | `personal_home.dart` → `UserScheduleService.upcomingPostCount` |
| Related | `view_user_profile_page.dart`, `view_my_posts_page.dart`, `home_page.dart` (`_updateUserRoles`) |

Architecture context: see `docs/users-volunteers-improvement.md` (Phases 0–5 largely complete).

---

## Current behaviour (summary)

- Program role assignments are denormalized to `users/{uid}/supplemental/roles`.
- Cloud Function `sync_user_roles_for_post` syncs roles when a post program is saved.
- `UserScheduleService` centralizes stale cleanup and badge counting.
- Own My Schedule from Personal: **roles only** (no Posts tab — editable posts live under **My Posts**).
- Volunteer profiles: `allowPostView: true` → **Schedule** + **Posts** tabs (or jump straight to Posts).
- Role retention: prune after **28 days** past `eventDate`; UI shows **Upcoming** + **Recent** (last 28 days).
- Badge / profile preview still count **upcoming** only.

---

## Findings

### Critical — missing event heads can hide and delete valid roles

`AppContext` loads only the **40 most recent** event heads (`EventHeadDBManager.fetchEventHeads`).

`UserScheduleService.staleRolePostIDs` treats any role whose `postID` is **not** in `eventHeads` as stale (`head == null`).

On `ViewUserRolesPage`, stale posts are removed from the list **before** `_buildTile` can fetch the head individually — then `_runRoleCleanup` **deletes** those roles from Firestore.

**When this bites:** user is scheduled on an upcoming post outside the top-40-by-`RecentDate` feed (older parent, bulk-created child, etc.). Assignment disappears from UI and may be pruned from supplemental roles.

**Relevant code:**

- `lib/utility/user_schedule_service.dart` — `staleRolePostIDs`
- `lib/pages/personal/view_user_roles_page.dart` — `_buildScheduleBodyWithData` (filter + prune before per-tile fetch)
- `lib/firebase/db_managers/event_db_manager.dart` — `fetchEventHeads` (limit 40), `fetchHeadsFromList` (exists, unused here)

---

### Medium — sort can crash on null `eventDate`

After stale filtering, list sort uses `getPostHead(a).eventDate!`. Posts without an event date will throw.

**File:** `view_user_roles_page.dart` ~line 146

---

### Medium — schedule badge hidden until roles are loaded

`personal_home.dart` `_buildScheduleBadge` returns `null` when `currentUser.roles == null`.

Roles are loaded on login (`main.dart`) and when opening My Schedule, but **not** at normal app startup for an already-logged-in session. Badge may stay hidden until user opens My Schedule once.

---

### Medium — FCM role refresh doesn’t refresh Personal UI

`home_page.dart` `_updateUserRoles` calls `setRoles` but does not call `AppContext.notifyListeners()`. Personal badge/menu won’t update until another rebuild.

---

### Low — pull-to-refresh can silently no-op

`canRefreshRoles` throttles real refresh to once per 2 minutes (`app_shared_preferences.dart`). Inside the window, `_refreshRoles` only `Future.delayed(1s)` and still shows “Refresh Complete!” — misleading.

**File:** `view_user_roles_page.dart` `_refreshRoles`

---

### Low — `allowTaskCheck` doesn’t detect conflicts

In program role user picker (`select_users_page.dart`), schedule icon opens the user’s schedule only. No overlap/conflict detection (was noted as future work in `users-volunteers-improvement.md`).

---

## UX gaps (not bugs)

| Area | Current | Suggestion |
|------|---------|------------|
| Date format | `EEE d MMM` (no ordinals) | Match bulk-create style (`5th Jul`) |
| Past vs upcoming | Past roles pruned after 28 days | UI: Upcoming + Recent sections (done) |
| Profile preview | Next 3 tasks don’t tap through to post | Make preview tiles open `ViewEventPage` |
| Posts tab | Was duplicating My Posts for self | Fixed: self schedule is roles-only; Posts tab remains on other users’ profiles |
| Localization | Menu localized; page strings hardcoded | Move empty states, tabs, errors into `app_en.arb` |
| Help | My Posts has help dialog; My Schedule doesn’t | Short explainer for assigned program roles |
| Title | Self: full name + tabs; others: `"{forname}'s Schedule"` | Minor inconsistency |

---

## What’s already in good shape

- [x] `UserScheduleService` with unit tests (`test/unit/utility/user_schedule_service_test.dart`)
- [x] Badge counts distinct upcoming **posts**, not raw role rows
- [x] Stale cleanup centralized (login + schedule page)
- [x] Cloud Function role sync on program save
- [x] Profile hub → full schedule navigation
- [x] `RefreshIndicator` on schedule list
- [x] Card tap opens event post

---

## Recommended implementation order

Use this checklist across chats. Update status when items complete.

### Priority 1 — Data integrity (do first)

- [ ] **Prefetch role post heads before stale logic**
  - On schedule open (and optionally login prune), fetch heads for all role `postID`s missing from `eventHeads` via `fetchHeadsFromList` / per-id `fetchHead`
  - Add heads to `AppContext` before `staleRolePostIDs` / display / prune
  - Consider splitting stale rules: “unknown head after fetch failed” vs “past event”
  - Add unit test or widget test for “role post not in top-40 heads still shown”

### Priority 2 — Badge & refresh accuracy

- [ ] **Load roles at startup** (or when Personal tab first shown) so badge works without opening My Schedule
- [ ] **`notifyListeners()` after `_updateUserRoles`** in `home_page.dart` (and any similar refresh paths)
- [ ] **Honest pull-to-refresh** — show “Already up to date” or disable refresh while throttled; don’t fake success

### Priority 3 — Small robustness fixes

- [ ] **Safe sort** when `eventDate` is null (fallback to `recentDate` or end of list)
- [ ] **Await** any remaining fire-and-forget writes if found during implementation

### Priority 4 — UX polish

- [ ] Ordinal date formatting on schedule cards (`5th Jul`)
- [ ] Localize hardcoded strings on `ViewUserRolesPage`
- [ ] Help dialog (mirror `ViewMyPostsPage`)
- [ ] Tap-through on profile preview task tiles
- [x] Optional **Upcoming / Past** sections (Recent = last 28 days; prune aligned)

### Priority 5 — Larger feature (optional)

- [ ] **Scheduling conflict hints** in role user picker (`allowTaskCheck`) — show overlap with existing assignments when picking users

---

## Key files to touch

| Task | Files |
|------|-------|
| Prefetch heads + stale fix | `view_user_roles_page.dart`, `user_schedule_service.dart`, maybe `app_context.dart` |
| Startup roles / badge | `main.dart`, `personal_home.dart`, `home_page.dart` |
| Refresh UX | `view_user_roles_page.dart`, `app_shared_preferences.dart` |
| Date / l10n / help | `view_user_roles_page.dart`, `app_en.arb`, `app_localizations*.dart` |
| Profile tap-through | `view_user_profile_page.dart` |
| Conflict detection | `select_users_page.dart`, `user_schedule_service.dart` |

---

## Verify after changes

```bash
flutter analyze
flutter test test/unit/
```

Manual checks:

1. Assign user to a post **not** in the home feed top 40 → role still appears on My Schedule; not pruned from Firestore.
2. Pull-to-refresh within 2 min → honest feedback.
3. Role assignment push notification → Personal badge updates without opening My Schedule.
4. Post with null `eventDate` in schedule → no crash.

---

## Related docs

- `docs/users-volunteers-improvement.md` — broader Users/Volunteers refactor (mostly complete)
- `AGENTS.md` — agent conventions; add one-line entry when a phase completes
