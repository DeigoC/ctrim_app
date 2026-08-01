# Caregroups — design & implementation handoff

> **Purpose:** Living design for a first-class **Caregroup** section and data model (beyond bulletin posts).  
> **Created:** 2026-08-01  
> **Status:** Planning / draft — product decisions not locked  
> **Start here in a new chat:** “Continue caregroups from `docs/caregroups.md`”

---

## What this is

CTRIM already describes caregroups (also called cell groups) in Information content: small groups that meet **weekly outside the main service**, focused on Bible study, care, prayer, and discipleship — usually hosted in homes and led by trained members, not only pastors.

Today the app only touches caregroups lightly:

| Existing surface | What it does | Gap |
|------------------|--------------|-----|
| Bulletin posts | Can advertise a group’s weekly meeting (title, date, location, tags) | Ephemeral / event-shaped; no lasting group identity |
| Post tag + stream `youth-cg` / `belfast-youth-cg` | Filter + notify for Youth Online Caregroup | One stream, not a roster of groups |
| Info pages (`cell_group.json`, church blurbs) | Explains the ministry | Not operational data |
| Post attendance / interest | Per-post RSVP lists | Not the same as “who belongs to this caregroup” |

**Goal of this feature:** treat each caregroup as a **durable entity** the app can list, manage, and report on — with bulletin posts as one optional surface for meetings, not the source of truth for the group.

---

## Goals (draft)

1. **Catalogue caregroups** — name, location/church link, meeting pattern, status (active / paused / multiplying / archived).
2. **Leadership** — senior leader (and possibly co-leaders / hosts) as first-class fields, preferably linked to `users` when they have an app account.
3. **Membership** — people marked as regular attendees / members of *this group* (distinct from one-off post RSVP).
4. **Meeting history & attendance trends** — over time (counts and/or named lists per meeting), so leaders and oversight can see health, not only “who said they’re coming this week”.
5. **Main app section** — a dedicated nav destination (alongside Events / Information / Personal) for browsing and managing caregroups, not buried only under Personal admin tools.
6. **Bulletin integration** — weekly meeting posts can **link to** a caregroup (and maybe inherit location/tags/notify streams), without forcing every group detail onto `EventHead`.

### Non-goals (until decided otherwise)

- Replacing Information “what is a cell group?” teaching content.
- Full CRM / pastoral counselling notes.
- Automatically replacing all existing caregroup-related bulletin posts.
- Multiplying / planting workflow automation (may be phase 2+).

---

## Product language

| Prefer in UI | Also heard in content | Notes |
|--------------|----------------------|--------|
| **Caregroup** | Cell group, care group, CG | Pick one primary label for the section; info pages can keep theological wording |
| **Senior leader** | Cell leader, CG leader | Confirm exact role names with stakeholders |
| **Members / regulars** | Attendees | “Attendee” is overloaded with post RSVP — prefer **member** or **regular** for group roster |

**Open:** official spelling in product copy — `Caregroup` (one word, matches church copy) vs `Care Group`.

---

## Concepts (proposed)

```text
Caregroup (durable)
  ├── Profile: name, summary, photo?, church/location, meeting cadence, venue notes
  ├── Leadership: seniorLeader (+ optional coLeaders / host household)
  ├── Roster: members / regulars (registered users + free-text guests?)
  ├── Meetings (instances): date/time, optional linked bulletin postId, attendance snapshot
  └── Meta: status, created/updated, visibility, who can edit
```

### Relationship to bulletin posts

**Recommended direction (not locked):**

- Caregroup is the **source of truth** for identity, roster, and trends.
- A weekly meeting may optionally create or link an `events/{postId}` for the public bulletin / FCM.
- Post attendance (RSVP) ≠ caregroup membership. A guest can RSVP once without becoming a regular; a regular might miss a week without leaving the roster.
- Linking: store `caregroupId` on the post (head or metadata) and/or `linkedPostIds` / `lastMeetingPostId` on the caregroup / meeting doc.

### Relationship to notification streams

- Today: one frozen Belfast stream for Youth Online Caregroup (`belfast-youth-cg`).
- Future options (pick later):
  1. Keep coarse streams (e.g. “all caregroups at location”) + per-group optional `post-{id}` for a given meeting.
  2. Per-caregroup FCM topic (many topics; subscription UX harder).
  3. Leaders/members get targeted user messages for their group only (no new topics).

Do **not** invent per-group topic IDs until product decides audience (whole church vs members only).

---

## Main section (UI sketch)

Nav today: **Events | Information | Personal**. Proposed: add **Caregroups** (label TBD) as a fourth destination (or fifth if order changes).

| Screen | Audience | Purpose |
|--------|----------|---------|
| Caregroups home | Everyone (or signed-in?) | List active groups — cards with name, leader, next meeting, member count |
| Caregroup detail | Everyone / members | Profile, leaders, next meeting CTA, maybe public blurb |
| Roster / members | Leaders + oversight | Add/remove regulars; distinguish registered vs free-text |
| Attendance / trends | Leaders + oversight | Chart or simple history of weekly counts; drill into a meeting |
| Admin: create/edit group | Oversight / authorised leaders | CRUD profile + leadership |
| Optional: “Log this week’s meeting” | Leaders | Record attendance; optionally spawn/link bulletin post |

**Open:** should guests see the full directory, only public blurbs, or nothing until signed in?

---

## Data model (sketch — not locked)

Prefer a **top-level collection** (same spirit as `post_tags`, not nested under a single event):

```text
caregroups/{caregroupId}                    ← list/card head (public fields only if world-readable)
  meetings/{meetingId}                      ← dated instances + attendance summary
  # and/or supplemental docs for private roster
```

### Caregroup head (fields under discussion)

| Field | Type | Notes |
|-------|------|--------|
| `Name` | string | Display name |
| `Subtitle` / `Summary` | string | Short blurb |
| `Location` | string | Align with post locations / church sites? |
| `ChurchId` / location ref | string? | If we ever key churches formally |
| `SeniorLeaderUserId` | string? | `users` uid when known |
| `SeniorLeaderName` | string? | Display / free-text fallback |
| `CoLeaderUserIds` | list | Optional |
| `MemberCount` | int | Denorm for cards (like attendee counts on posts) |
| `Status` | enum | `active` / `paused` / `archived` / … |
| `MeetingWeekday` / `MeetingTime` / `Cadence` | … | “Every Tuesday 7:30pm” style |
| `VenueNotes` | string | Home address sensitivity — likely **private** |
| `PhotoUrl` / media | … | Optional cover |
| `TagIDs` | list? | Reuse content tags? (e.g. Youth) |
| `CreatedAt` / `UpdatedAt` | timestamp | |
| `CreatedBy` | authId / uid | |

### Roster (private)

Do **not** put full member name lists on a world-readable head if `firestore.rules` allow public read (same lesson as post attendance).

Options:

- `caregroups/{id}/supplemental/roster` with signed-in (or leader-only) read.
- Or subcollection `members/{memberId}` with rules scoped to leaders + self.

Member entry shape (draft):

| Field | Notes |
|-------|--------|
| `UserId` | `users` uid if registered |
| `AuthId` | if we key by Auth like interest |
| `DisplayName` | required for free-text |
| `Role` | `member` / `leader` / `host` / … |
| `JoinedAt` | optional |
| `Status` | `active` / `inactive` |

### Meetings & attendance trend

| Approach | Pros | Cons |
|----------|------|------|
| **A.** Meeting docs with `AttendanceCount` (+ optional named list) | Simple trends from counts | Named history heavier |
| **B.** Reuse post attendance when a meeting is linked to a post | Less duplication for that week | Broken if no post; mixes RSVP with “who came” |
| **C.** Hybrid: meeting always logged in caregroup; post link optional | Clean trends; bulletin optional | More UI to build |

**Lean recommendation:** **C** — log meetings on the caregroup; optionally link `postId` for bulletin/FCM.

Trend UI can start with: last N weeks’ counts + sparkline / simple bar list (phase 1), named lists phase 2.

---

## Permissions & privacy (must decide before implement)

Lessons from post attendance: **client-only hiding is not privacy** when rules allow world read.

| Question | Options |
|----------|---------|
| Who can **read** directory? | Public / signed-in / volunteers only |
| Who can **see roster names**? | Leaders of that group + oversight roles |
| Who can **edit** a group? | Senior leader + designated admins / pastors |
| Who can **log attendance**? | Leaders only |
| Are venue / home addresses stored? | If yes → private; consider not storing precise address in V1 |

Also clarify how this maps to existing `everyone.isUser` / volunteer model vs a new caregroup-leader capability.

---

## Phased delivery (suggested)

### Phase 0 — Product lock (this chat)

Lock decisions in the table below; trim V1 scope.

### Phase 1 — Foundation

- `Caregroup` model + Firestore collection + rules
- Caregroups main section: list + detail (public profile fields)
- Admin create/edit (leadership, cadence, status)
- Roster CRUD (leaders)
- Unit tests for model

### Phase 2 — Meetings & trends

- Log meeting + attendance count (and/or names)
- Simple trend on detail page
- Optional link to bulletin post

### Phase 3 — Bulletin & notify polish

- Create weekly post from caregroup (pre-filled)
- Tag / stream strategy for caregroups
- Member-facing “my caregroup” on Personal home

### Later

- Multiplication (parent/child groups)
- Reports for pastoral oversight across all groups
- Free-text member → registered user merge

---

## Locked product decisions

> Fill as we decide. Move rows from Open questions when agreed.

| # | Topic | Decision | Date |
|---|--------|----------|------|
| — | — | *(none yet)* | — |

---

## Open questions

Use this list in chat; strike or move to Locked when answered.

### Identity & scope

1. Official product name/spelling: **Caregroup** vs Care Group vs Cell Group?
2. One directory for **all CTRIM locations**, or start **Belfast-only**?
3. Include **Youth Online Caregroup** as a normal caregroup record (with special tag), or keep it notify-only?

### People

4. Membership: **registered users only**, or **registered + free-text** (like post attendees)?
5. Can someone belong to **multiple** caregroups?
6. Is **senior leader** exactly one person, or leader couple / household?
7. Do members self-join, or is roster **leader-managed only**?

### Meetings & attendance

8. Is “attendance” for trends **who came that week** (actual), **who usually comes** (roster), or both?
9. Must every meeting have a bulletin post, or is logging inside Caregroups enough?
10. How far back do we keep named attendance lists?

### App IA

11. Fourth bottom-nav item — exact label and icon?
12. Visible to **guests**, or signed-in only?
13. Where do leaders manage day-to-day — Caregroups tab vs Personal?

### Technical

14. Top-level `caregroups` collection — confirm?
15. Reuse `Location` strings from posts / `user_locations`?
16. Any Cloud Functions required for V1 (counts, private writes), or client transactions + rules enough?

---

## Implementation checklist (for later chat)

```
- [ ] Lock Phase 0 decisions in this doc
- [ ] Model: lib/models/caregroup/ (or similar) + unit tests
- [ ] DB manager: lib/firebase/db_managers/
- [ ] firestore.rules (public vs private split)
- [ ] AppContext or CaregroupContext if list caching needed
- [ ] Pages: lib/pages/caregroups/ + home_page nav destination
- [ ] Optional: EventHead/Metadata field for caregroupId
- [ ] flutter analyze && flutter test test/unit/
- [ ] Update AGENTS.md Recent changes when shipped
```

---

## Related docs & code

- [`docs/post-attendance-interest.md`](post-attendance-interest.md) — RSVP vs membership; privacy split pattern
- [`docs/post-tags-notification-streams.md`](post-tags-notification-streams.md) — tags / `youth-cg` stream
- Info content: `assets/info/ctrim_info/cell_group.json`, church pages mentioning caregroups
- Nav shell: `lib/pages/home_page.dart` (Events / Information / Personal)
- Topics: `lib/utility/notification_topics.dart` (`kindYouthCaregroup`)

---

## Discussion log

| Date | Notes |
|------|--------|
| 2026-08-01 | Doc created. Intent: durable caregroup entities + main section; bulletin posts for weekly meetings; track membership, senior leader, attendance trends. Implementation deferred to a later chat after product lock. |
