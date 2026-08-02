# Cell Groups — design & implementation handoff

> **Purpose:** Living design for a first-class **Cell Group** section and data model (beyond bulletin posts alone).  
> **Created:** 2026-08-01  
> **Status:** Phase 0 product lock **done** — ready for implementation / period-parent side track  
> **Start here in a new chat:** “Continue cell groups from `docs/cell-groups.md`” (or “Implement period parent + editable ParentID from `docs/cell-groups.md`”)

---

## What this is

CTRIM already describes cell groups (also called caregroups in older copy) in Information content: small groups that meet **weekly outside the main service**, focused on Bible study, care, prayer, and discipleship — usually hosted in homes and led by trained members, not only pastors.

Today the app only touches cell groups lightly:

| Existing surface | What it does | Gap |
|------------------|--------------|-----|
| Bulletin posts | Can advertise a group’s weekly meeting (title, date, location, tags) | Ephemeral / event-shaped; no lasting group identity |
| Post tag + stream `youth-cg` / `belfast-youth-cg` | Filter + notify for Youth Online Caregroup | One stream, not a roster of groups |
| Info pages (`cell_group.json`, church blurbs) | Explains the ministry | Not operational data |
| Post attendance / interest | Per-post RSVP lists | Not the same as “who belongs to this cell group” |

**Goal of this feature:** treat each cell group as a **durable entity** (identity, leadership, roster) the app can list and manage in a dedicated main section — while **bulletin posts remain the primary public record that meetings happened**.

---

## Goals (V1-oriented)

1. **Catalogue cell groups** — name, location/church link, meeting pattern, status (active / paused / archived).
2. **Leadership** — senior leader (and possibly co-leaders / hosts) as first-class fields, preferably linked to `users` when they have an app account.
3. **Membership** — regulars/members of *this* group: **registered users**, **leader-created placeholder users**, and **free-text** one-offs. Distinct from one-off post RSVP.
4. **Main app section** — dedicated nav destination with **tiered visibility** (guests see least; admins see most).
5. **Bulletin as meeting proof** — weekly (or per-meeting) posts linked to a cell group are the main content trail that the CG met; exact linking UX still being hashed out.
6. **Companion user-model work** — ship with CG: placeholder `users` profiles + scoped Auth link via `CreatedByUserID` (see [Companion: user model change](#companion-user-model-change)).

### Non-goals for V1

- Attendance **trends** / sparkline analytics (fine to add later).
- Separate “log meeting without a post” workflow as the primary path (posts are the proof).
- Replacing Information “what is a cell group?” teaching content.
- Full CRM / pastoral counselling notes.
- Multiplying / planting workflow automation.

---

## Product language

| Prefer in UI | Also heard in content | Notes |
|--------------|----------------------|--------|
| **Cell Group** | Caregroup, care group, CG | **Locked** product name. Legacy notify label “Youth Online Caregroup” can stay until a separate rename. |
| **Senior leader** | Cell leader, CG leader | Confirm exact role names with stakeholders |
| **Members / regulars** | Attendees | “Attendee” stays for **post RSVP**; roster uses **member** / **regular** |

Short form in docs/UI where needed: **CG**.

---

## Concepts (proposed)

```text
CellGroup (durable)
  ├── Profile: name, summary, photo?, church/location, meeting cadence, venue notes
  ├── Leadership: one or more owners/leaders (not a single mandatory “senior” only)
  ├── Roster: members / regulars (registered users + free-text)
  ├── Linked bulletin posts: meeting “proof” / public content trail
  └── Meta: status, created/updated, visibility tiers, who can edit
```

### Relationship to bulletin posts

**Locked:**

- Cell group doc = source of truth for **identity, leadership/owners, roster, cadence**.
- **Bulletin posts** = main **content / proof** that meetings happened.
- Leaders are **strongly encouraged** (not required) to create their own posts for meetings.
- Post attendance (RSVP) ≠ cell group membership.
- **Joint sessions** are first-class: **one post can link to multiple cell groups** (one meeting, several CGs / leaders taking part).

**Link field (lean recommendation — treat as locked unless we find a blocker):**

| Layer | Field | Why |
|-------|--------|-----|
| `events/{id}/supplemental/metadata` (`EventMetadata`) | **`CellGroupIDs`: `List<String>`** | Canonical link; supports joint sessions; same place as author/topics/tags source fields |
| `events/{id}` (`EventHead`) | **`CellGroupIDs` denorm (same list)** | Needed to query “posts for this CG” and show trail on CG detail without loading every metadata doc — same pattern as `TagIDs` on head for bulletin filter |

Singular `CellGroupID` is **not** enough because of joint sessions. Prefer plural everywhere from day one.

Do **not** overload **post tags** as the CG link. Tags remain content/notify categories (templates + edit flow, including things like Youth Online Caregroup stream). A post may have both:

- `TagIDs` — e.g. browse/notify category  
- `CellGroupIDs` — which concrete group(s) this meeting belongs to  

**Still open:** *(none on this subsection — templates pre-fill and trail depth locked below.)*

### How posts get `CellGroupIDs` (UX)

| Idea | What it means | Status |
|------|----------------|--------|
| **CG picker on create/edit** | On the normal post editor, author/owner can set **one or more** `CellGroupIDs` (including other groups for a joint session). | **Locked** — always available |
| **Template pre-fill** | Templates store default `CellGroupIDs` (same spirit as `TagIDs`). Leaders pick their template → new bulletin post already linked to their CG record(s). | **Intended** — primary fast path for leaders |
| **Create-from-CG** | Shortcut from CG detail → “New meeting post”. | **Deferred / tricky** — see season parents below |

**Who may set the list:** the **post owner/editor** can set/change the full `CellGroupIDs` list, including other CGs for joint sessions.

### Season parent posts (bulletin hierarchy)

Operating pattern (product):

- A **parent post** covers cell groups for a **period** (e.g. a 3-month season, term, or similar).
- Individual CG meeting posts are **children** of that season parent (`EventMetadata.ParentID` / parent’s `ChildrenIDs`).
- Related-posts UI already surfaces parent / children / siblings.

That’s why **create-from-CG** is awkward: creating from the CG section would also need to know **which season parent** to attach under (current season? pick from list?). Templates + create under the parent (today’s “add related post”) fit the hierarchy better.

### Designated period / season posts (new metadata field)

**Yes — worth a real field.** Do not infer “season parent” only from “has children” (many non-season posts have children), and do not overload **post tags** for structural hierarchy role.

**Lean recommendation** on `EventMetadata` (supplemental):

| Approach | Field | Pros | Cons |
|----------|--------|------|------|
| **A. Boolean (V1)** | `IsPeriodParent: bool` (name TBD) | Simple; easy rules/UI toggle | Less expressive if we later need other container types |
| **B. Kind enum** | `PostRole` / `ContainerKind`: `none` \| `period` \| … | Extensible (retreat series, campaign, etc.) | Slightly more UI |

**Lean lock:** field name **`IsPeriodParent`** (boolean on `EventMetadata`). Time range can vary — “period” not “season”. Flag-only in the side-track V1 (no required `PeriodStart`/`PeriodEnd` yet).

**Who may set / change a post’s parent (`ParentID`):** **Author** of the post **or area admin** — **not** ordinary contributors. Picker lists posts with `IsPeriodParent == true`.

Ship editable ParentID + `IsPeriodParent` as a **side track** beside CG work (own PR / chat), not blocked on the full Cell Groups section.

### Editable `ParentID` (enabling fix)

**Today:** `ParentID` is set when the post is created (`EventMetadata` field is effectively immutable — `late final`, no setter). Children are appended on the parent via `ChildrenIDs` at create time only. There is **no** UI to reparent a post later.

**Wanted:** allow editing a post’s parent (set / change / clear `ParentID`) so leaders can:

- Create a meeting post (e.g. from a CG-prefilled template) and **attach it to the right season parent** afterward, or
- Fix mistakes / move a post between seasons without recreating it.

**Implementation notes for a later chat (likely a small precursor or parallel task):**

1. Make `ParentID` mutable on `EventMetadata` (+ Firestore update).
2. On change, **bidirectionally** update old parent’s `ChildrenIDs` (remove) and new parent’s `ChildrenIDs` (add); handle clear-parent and set-parent-from-null.
3. Guard cycles (post cannot be its own ancestor) and preferably block parenting under one of its current children.
4. UI: edit on post admin / metadata edit surface; picker among suitable parents (e.g. season posts) — exact UX TBD.
5. Permissions: same as who can edit the post today, unless tighter rules wanted.

This is **related to Cell Groups but not CG-only** — it improves the whole related-posts model. Worth tracking as its own checklist item; unblocks cleaner CG + season workflows without forcing create-from-CG in V1.

### Tags vs cell group links

| | Post tags (`TagIDs`) | Cell group links (`CellGroupIDs`) |
|--|---------------------|-----------------------------------|
| Job | Bulletin filter + optional notify `StreamKind` | Point at durable `cell_groups/{id}` record(s) |
| Cardinality | Many tags catalog-wide | Specific group instances |
| Joint meeting | N/A (category) | **Multiple CG ids on one post** |
| Edited via | Templates + edit title/details (existing) | CG picker on create/edit (+ create-from-CG later) |

### Relationship to notification streams

- Today: one frozen Belfast stream for Youth Online Caregroup (`belfast-youth-cg`) via tags/`StreamKind`.
- Cell group **entity** links do not replace that stream unless we later add per-CG or “all CGs” topics.
- Future options unchanged; do **not** invent per-group topic IDs until audience is decided.

---

## Visibility tiers (locked intent)

Everyone can open the **Cell Groups** section; **detail depth is tiered**. Exact field matrix still TBD — draft:

| Tier | Who | Typical access |
|------|-----|----------------|
| **Guest** | Anonymous / not signed in | Section visible; public cards (name, maybe area, next public meeting teaser). **No** roster names, venue/address, private counts beyond what’s safe |
| **Signed-in** | Firebase Auth (incl. before volunteer) | More profile detail; maybe member count; still **no** full roster / sensitive venue unless policy says otherwise |
| **Member / leader of that CG** | On roster or marked leader | Roster (at least for own group); manage own group’s membership; see meeting trail with post links |
| **Admin / oversight** | App admins / pastoral oversight | Full directory detail, all rosters, edit any group |

**Meeting trail depth** = how much of each linked bulletin post a tier sees on the CG detail “meetings” list.

**Locked lean for V1:**

- Show about **3–4 most recent** linked posts (by event/recent date); “see more” later if needed.
- Each row: **title + date**; tap **opens the post** (normal post navigation).
- **Attendance names** follow **existing post attendance** privacy — not a separate CG rule.

### Technical locks + security guidance

| Topic | Decision |
|-------|----------|
| Collection id | **`cell_groups`** |
| Location scope | **Belfast** for V1 (still store `Location: "Belfast"` on records for future multi-site) |
| Roster shape | **Single supplemental doc** `cell_groups/{id}/supplemental/roster` — easiest for small lists; revisit subcollection only if size/rules force it |
| Nav icon | **`Icons.groups`** |

#### Cloud Functions vs client + `firestore.rules` (security-focused)

**Rule of thumb:** if a wrong client write can **mint or hijack identity** (`users` / Auth link), prefer a **callable Cloud Function** (or equally strict Admin-SDK path). If the write only updates **app content the user already has soft gates for** (CG profile, roster of a group they lead, `CellGroupIDs` on a post they edit), **client + field-scoped rules** matching the post-tags pattern is appropriate.

| Write path | Risk if client-trusted | Lean approach |
|------------|------------------------|---------------|
| **Create placeholder `users` doc** | Today rules: **admin-only create**. Opening create to CG leaders without tight field locks lets a malicious client set `IsLeader` / `IsAreaAdmin` / steal identity shape | **Callable CF** (or Admin SDK): server sets `IsPlaceholder: true`, empty `AuthID`, `CreatedByUserID`, forbids privilege flags. Client must not be free to write arbitrary user fields. |
| **Link / reassign Auth on placeholder** | Pointing `AuthID` at the wrong account is high impact; post-link freeze must be real | **Prefer CF / harden existing `UserAuthLinkService` behind rules that only allow creator+admin while `IsPlaceholder`**, and **deny Auth changes after link** except area admin. If rules get too clever/fragile → move link to CF. |
| **CG head / public profile** | Low–medium (spam/defacement) | **Client + rules** (leader of that CG or area admin) |
| **CG roster supplemental** | Medium (privacy of names) | **Client + rules**: read signed-in / leader / admin per tier; write = leaders of that CG + admin. Roster is small → one doc is fine. |
| **`CellGroupIDs` on post head + metadata** | Low (wrong links) | **Client + rules** (same people who can edit the post), keep lists in sync like `TagIDs` |
| **MemberCount denorm** | Low | Client transaction or same write as roster update; rules ensure only allowed editors bump it |

**Bottom line for implementers:** treat **placeholder create (+ Auth link if rules feel thin)** as the security-critical path → **Cloud Function**. Treat **cell group CRUD, roster, and post `CellGroupIDs`** as **client + strict rules**. Do not widen `users` `allow create` to all `isUser` without field constraints — that would be a regression vs today’s admin-only create.

---

## Main section (UI sketch)

Nav today: **Events | Information | Personal**. Proposed: add **Cell Groups** as a fourth destination (icon TBD).

| Screen | Audience | Purpose |
|--------|----------|---------|
| Cell Groups home | Everyone (tiered cards) | List active groups |
| Cell Group detail | Tiered | Profile; leaders (as allowed); linked meeting posts; CTAs by role |
| Roster / members | Leaders + admin | Add/remove regulars (registered + free-text) |
| Admin: create/edit group | Admin (+ maybe senior leader for own group) | CRUD profile + leadership |
| Meeting trail | Tiered | List of linked bulletin posts as proof/history (not a separate trends UI in V1) |

Leaders’ day-to-day likely lives in this tab (create/link weekly post, manage roster); Personal may later surface “My cell group”.

---

## Data model (sketch — not locked)

Prefer a **top-level collection**:

```text
cell_groups/{cellGroupId}                   ← list/card head (guest-safe public fields only)
  supplemental/roster                       ← private (signed-in / leader / admin per rules)
  # meeting history primarily via posts with CellGroupId — not a required meetings/ subcollection in V1
```

Collection id **`cell_groups`** (snake) unless we prefer camel; confirm at implement time.

### Cell group head (fields under discussion)

| Field | Type | Notes |
|-------|------|--------|
| `Name` | string | Display name |
| `Subtitle` / `Summary` | string | Short blurb — guest-safe |
| `Location` | string | Align with post locations / church sites? |
| `LeaderUserIds` | list | **One or more** owner/leader `users` uids (registered or placeholder) |
| `LeaderNames` / free-text leaders | list? | Fallback only if needed; prefer placeholder `User` when account expected |
| `MemberCount` | int | Denorm; may be **hidden from guests** even if stored |
| `Status` | enum | `active` / `paused` / `archived` / … |
| `MeetingWeekday` / `MeetingTime` / `Cadence` | … | “Every Tuesday 7:30pm” |
| `VenueNotes` | string | Home address — **private**, not on guest-readable head |
| `PhotoUrl` / media | … | Optional cover |
| `TagIDs` | list? | Optional content tags on the *group* itself (separate from post tags) |
| `CreatedAt` / `UpdatedAt` | timestamp | |
| `CreatedBy` | authId / uid | |

**Owners / leaders:** a CG has **1+ leaders** who “own” it (edit profile, roster, encouraged to post). No requirement that exactly one be “senior” in V1 unless product wants a primary contact field later (`PrimaryLeaderUserId` optional add-on).

### Roster (private)

Prefer a **`users` uid** (registered or placeholder). Keep **free-text** only for never-register one-offs.

| Field | Notes |
|-------|--------|
| `UserId` | `users` uid when linked to a profile (registered **or** placeholder) |
| `AuthId` | optional; usually derived from linked user when present |
| `DisplayName` | required for free-text rows; otherwise display from `User` |
| `Role` | `member` / `leader` / `host` / … |
| `JoinedAt` | optional |
| `Status` | `active` / `inactive` |

### Meetings via bulletin (V1)

No separate attendance-trend store in V1.

**Meeting trail for a CG:** query bulletin heads where `CellGroupIDs` **array-contains** this group’s id, ordered by `EventDate` / `RecentDate`.

Joint session: one post appears on **each** linked CG’s trail.

Post attendance can still record who came that week when useful; membership roster stays separate.

---

## Companion: user model change

**Intent:** ship with Cell Groups (not as an afterthought). Builds on the existing placeholder Auth pattern in [`docs/users-volunteers-improvement.md`](users-volunteers-improvement.md) (`AuthID` empty → Link / Reassign via `UserAuthLinkService`).

### Problem

CG leaders need names on the roster **before** someone has registered with email. Free-text alone does not give a stable identity to promote later. Today only **area admins** can Link / Reassign Auth on Edit User — too narrow for CG ops, too wide if every leader could edit every placeholder.

### Locked approach: leader-created placeholder users

| Idea | Decision |
|------|----------|
| **What a “temp account” is** | A real `users/{uid}` doc with **`IsPlaceholder: true`**, empty `AuthID`, and `CreatedByUserID` set. Not a separate collection. |
| **Who creates** | A **CG leader/owner** (of a group they lead) may create a placeholder profile for roster use. Area admins keep full Register User. |
| **`CreatedByUserID`** | New field on `users/{uid}`: volunteer **`users` uid** of the creator (not Auth UID — stable if the creator later re-links). Set once at create; do not rewrite when Auth is linked. |
| **Who may link / reassign Auth** | **Creator** (`CreatedByUserID` matches their `users` id) **or area admin**. Not every CG leader app-wide. |
| **After successful link** | Prefer **freeze** further Auth changes on that profile to **area admins only** (stops a leader quietly re-pointing a live account). Creator may still correct **name** on placeholders they own. |
| **What creator must not do** | Set `IsLeader` / `IsAreaAdmin`, edit unrelated users, or broadly edit Volunteers directory fields beyond name (+ Auth link while still a placeholder). |
| **Directory / pickers** | Hide **`IsPlaceholder == true`** from Belfast Volunteers list and program role pickers by default (admin opt-in / “show placeholders” filter later). |
| **Placeholder UI entry** | **Shared `SelectUsersPage`** (already used for attendance, contributors, program roles, etc.): when search finds no one, offer **Create placeholder** (gated). Also available from **CG roster → Add member** (may open the same picker). Admins keep Register / Edit User. |
| **Legacy backfill** | Existing `users` with empty `AuthID` → set **`IsPlaceholder: true`** (migration / one-shot backfill) so they appear in the addressing queue. |
| **Free-text on CG roster** | **Keep** for true one-offs who will never register. Prefer a **placeholder `User`** when you expect them to get an app account later. |
| **Claim / promote flow** | Person registers with email → creates `everyone/{authId}` → leader opens the placeholder → Link account by email → reuse `UserAuthLinkService` (existing conflict checks: email must exist; Auth not already owned by another `users` doc). |
| **Rules** | Enforce “creator or area admin may write `AuthID` on a placeholder they own” in **`firestore.rules`** — client-only gating is not enough. |
| **Co-leader orphan gap** | V1: if the creating leader leaves, only an **area admin** can claim that placeholder. **Later (not V1):** optionally allow other leaders of a CG that already has this uid on its roster. |

### `User` field additions (lean)

| Field | Type | Notes |
|-------|------|--------|
| `CreatedByUserID` | string | Creator’s `users/{uid}`; empty/absent for admin-created or legacy profiles |
| **`IsPlaceholder`** | **bool** | **Explicit** mark for leader-created (or admin) temp profiles that still need Auth addressing. **Locked** — do not rely only on empty `AuthID`. |

**Why store `IsPlaceholder` instead of deriving from empty `AuthID`:**

| Approach | Meaning | Problem |
|----------|---------|---------|
| Derive: `authID.isEmpty` | Treat every empty Auth as “placeholder” | Collides with **legacy / incomplete** profiles that never got Auth for other reasons; hard to list “who still needs addressing” as an intentional queue |
| **Store: `IsPlaceholder: true`** | Profile was created as a temp roster identity and is **tracked** until linked (or cleared by admin) | Clear filter for Volunteers admin / CG leaders: “placeholders needing attention” |

**Lifecycle (lean):**

1. Create placeholder → `IsPlaceholder: true`, `AuthID: ''`, `CreatedByUserID` set.
2. Successful Auth link → set `AuthID`; set **`IsPlaceholder: false`** (no longer in the “needs addressing” queue). Keep `CreatedByUserID` for audit.
3. Directory / program pickers: hide where `IsPlaceholder == true` (and/or still-empty Auth — belt and braces).
4. Admin / creator views: filter **`IsPlaceholder == true`** to see who still needs link/claim work.

No requirement in V1 for `CellGroupIds` on the user doc (roster remains on the CG). Revisit if “My cell group” on Personal needs a reverse index.

### Permission matrix (Auth link)

| Actor | Create placeholder | Edit name on placeholder | Link / reassign Auth (while unlinked) | Reassign Auth after linked | Set Leader/Admin flags |
|-------|--------------------|---------------------------|----------------------------------------|----------------------------|------------------------|
| Creating CG leader | Yes (for roster) | Own creations | Own creations only | No (admin) | No |
| Other CG leader | Own placeholders only | Own creations only | Own creations only | No | No |
| Area admin | Yes | Any | Any | Yes | Yes |
| Signed-in member | No | No | No | No | No |

### Implementation notes (when coding)

1. Extend `User` + `User.fromMap` / `toJson` with `CreatedByUserID` and **`IsPlaceholder`** (PascalCase Firestore keys).
2. **Callable CF** to create placeholder (server-enforced fields); do not open unrestricted `users` create to all volunteers.
3. Enhance **`SelectUsersPage`**: empty search → Create placeholder (gated); used from attendance, schedule/roles, CG roster, etc.
4. CG roster Add member can open the same picker (or a thin wrapper).
5. Scoped Link UI for creators — harden `UserAuthLinkService` with rules and/or CF; on success clear **`IsPlaceholder`**.
6. Filter pickers/directory: hide `IsPlaceholder == true` unless “include placeholders” / addressing queue.
7. Unit tests for model + permission helpers; deploy rules + functions with the feature.
8. Cross-update Phase 6 notes in the users/volunteers handoff when this ships.

### Still open (user model)

- Self-claim / “this is me” merge — out of scope for V1.

---

## Permissions & privacy

| Concern | V1 lean |
|---------|---------|
| Section visible | **Yes** for everyone, tiered detail |
| Roster names | Not guest-visible; rules-enforced |
| Edit group / roster | Leaders of that CG + area admin |
| Create new CG record | **Area admin** (lean) — then assign leaders; leaders do not mint new groups in V1 |
| Venue / home address | Private or omit in V1 |
| Meeting proof | Linked posts; trail ~3–4; title/date/open post |

Map tiers onto `everyone.isUser`, admin flags, and any new cell-leader capability from the user-model work.

---

## Phased delivery

### Phase 0 — Product lock — **done** (2026-08-02)

Enough locked for an implementing chat. Remaining nits are implement-time defaults (see “Deferred to implement chat” below).

### Phase 0.5 — Period parents + editable `ParentID` (side track)

- Metadata flag **`IsPeriodParent`**
- Toggle in post edit UI (+ optional template default)
- Mutable parent on metadata + bidirectional `ChildrenIDs` sync
- Parent picker UI: **title/subtitle edit page** (`EditTitleSubtitlePage` / head details) — **author or area admin** only; list = `IsPeriodParent` posts
- Own side-track PR beside CG

### Phase 1 — Foundation (no trends)

- `CellGroup` model + `cell_groups` collection + tiered `firestore.rules`
- Cell Groups main section: list + detail (tiered)
- Admin / leader create/edit (leadership, cadence, status)
- Roster CRUD (registered + placeholder users + free-text)
- Placeholder user create + scoped Auth link (`CreatedByUserID`); hide placeholders from global pickers
- `CellGroupIDs` on metadata + head; templates store/pre-fill them
- Meeting trail on CG detail via head query
- Unit tests; ship user-model companion with this phase

### Phase 2 — Operating rhythm

- Clearer “meeting proof” UX on detail
- Notify / tag strategy for CGs
- “My cell group” on Personal (optional)
- Create-from-CG only if season-parent picking is solved

### Phase 3 — Insights (later)

- Attendance trends / health views derived from linked posts + post attendance
- Oversight reports across all groups
- Multiplication (parent/child groups)
- Free-text → placeholder / registered merge (beyond V1 Auth link)

---

## Locked product decisions

| # | Topic | Decision | Date |
|---|--------|----------|------|
| 1 | Product name | **Cell Group** (UI/docs). Short: CG. | 2026-08-01 |
| 2 | Section visibility | **Everyone** can open the section; **tiered detail** (guest least → admin most). Enforce in rules. | 2026-08-01 |
| 3 | Roster identity | **Registered users**, **leader-created placeholder `users`**, and **free-text** one-offs. | 2026-08-01 |
| 4 | Meeting proof | **Bulletin posts** are the main content/proof that CGs happened. | 2026-08-01 |
| 5 | Trends in V1 | **Out of scope** for V1. | 2026-08-01 |
| 6 | Posting rhythm | Leaders **strongly encouraged** to create meeting posts; **not** hard-required. | 2026-08-01 |
| 7 | Post ↔ CG link | **`CellGroupIDs` list** on `EventMetadata` (supplemental); **denorm same list on `EventHead`** for queries (mirror `TagIDs` pattern). | 2026-08-01 |
| 8 | Joint sessions | **One post, multiple `CellGroupIDs`** — appears on each CG’s meeting trail. | 2026-08-01 |
| 9 | CG owners | A CG has **1+ leaders/owners** (not single-leader-only). | 2026-08-01 |
| 10 | Tags vs CG links | **Separate concerns** — do not use post tags as the entity link to a CG. | 2026-08-01 |
| 11 | Who sets `CellGroupIDs` on a post | **Post owner/editor** (same edit rights as today) may set/change the full list, including other CGs for joint sessions. | 2026-08-01 |
| 12 | Template pre-fill | Templates **will** store `CellGroupIDs` so leaders get a fast linked create path. | 2026-08-01 |
| 13 | Season hierarchy | Meeting posts hang under a **period/season parent post**; create-from-CG deferred because parent selection is the hard part. | 2026-08-01 |
| 14 | Editable parent | **Wanted:** posts can edit `ParentID` (reparent / attach to season). Today immutable at create. Side track / precursor. | 2026-08-01 |
| 15 | Period parent marker | Metadata bool **`IsPeriodParent`**. Flag-only first (no required period dates). | 2026-08-02 |
| 16 | Placeholder users | CG leaders may create `users` with **`IsPlaceholder: true`** + empty `AuthID` for roster names; promote later via Auth link (clears flag). | 2026-08-02 |
| 17 | `CreatedByUserID` | On `users/{uid}`: creator’s volunteer uid. Only **creator** or **area admin** may link Auth while still a placeholder. | 2026-08-02 |
| 18 | `IsPlaceholder` field | **Stored bool** on `users` — intentional queue for “needs Auth addressing”; do not derive only from empty `AuthID`. | 2026-08-02 |
| 19 | Post-link Auth freeze | After a successful Auth link, further Auth reassign is **area admin only**. | 2026-08-02 |
| 20 | Placeholder visibility | Hide **`IsPlaceholder == true`** from Volunteers list / program pickers by default. | 2026-08-02 |
| 21 | Free-text vs placeholder | Free-text for never-register one-offs; placeholder `User` when a real account is expected. | 2026-08-02 |
| 22 | Co-leader claim | **Not V1** — orphan placeholders after creator leaves → area admin only; optional later: other leaders of a CG that already lists that uid. | 2026-08-02 |
| 23 | Multi-CG membership | A person **can** be on multiple CG rosters. | 2026-08-02 |
| 24 | Roster join model | **Leader-managed only** — no self-join in V1. | 2026-08-02 |
| 25 | Placeholder UI entry | Enhance shared **`SelectUsersPage`** (attendance, roles/schedule, contributors, CG roster, …) with create-when-missing; plus CG roster Add member. | 2026-08-02 |
| 26 | Legacy empty Auth | **Backfill** existing empty-`AuthID` users to `IsPlaceholder: true`. | 2026-08-02 |
| 27 | Who edits `ParentID` | **Author or area admin** only (not contributors). Picker = `IsPeriodParent` posts. | 2026-08-02 |
| 28 | Period/parent ship | Side track **beside** CG — own PR/chat. | 2026-08-02 |
| 29 | Location scope V1 | **Belfast only** (still set `Location: "Belfast"` on CG docs). | 2026-08-02 |
| 30 | Youth Online as CG | **Not yet** — leave as notify/tag stream. | 2026-08-02 |
| 31 | Nav icon | **`Icons.groups`**. | 2026-08-02 |
| 32 | Meeting attendance | Use **post attendance** on linked bulletin posts — no separate CG attendance store in V1. | 2026-08-02 |
| 33 | Meeting trail depth | **~3–4** recent linked posts; title + date + open post; attendance privacy = existing post rules. | 2026-08-02 |
| 34 | Collection id | **`cell_groups`**. | 2026-08-02 |
| 35 | Roster storage | **`supplemental/roster` single doc** (small lists). | 2026-08-02 |
| 36 | CF vs client | **CF for placeholder create** (and Auth link if rules fragile); **client + rules** for CG/roster/`CellGroupIDs`. | 2026-08-02 |
| 37 | Create-placeholder gate | **Medium:** CG leaders + area admins; also **post author** when picker opened from that post (attendance/roles). | 2026-08-02 |
| 38 | Legacy `CreatedByUserID` | Backfill leaves creator **empty** → area-admin-only Auth link. | 2026-08-02 |
| 39 | Parent picker UI | **Title/subtitle (head details) edit page**; author or area admin. | 2026-08-02 |
| 40 | Guest CG cards | **Name + cadence** (hide roster/counts). | 2026-08-02 |
| 41 | Leaders’ home V1 | **Cell Groups** tab; Personal “my groups” later. | 2026-08-02 |
| 42 | Who creates CG records | **Area admin** creates groups and assigns leaders (lean). | 2026-08-02 |

---

## Open questions

**Phase 0 product lock is complete.** Nothing blocking another chat from implementing V1 + the period-parent side track.

### Deferred to implement chat (defaults OK — change only if awkward)

These are small enough not to need another planning round:

| Topic | Default if unspecified |
|-------|------------------------|
| Exact cadence fields | e.g. `MeetingWeekday` + `MeetingTime` strings/enums on CG head |
| `IsPeriodParent` toggle placement | Same head/metadata edit surfaces as other post flags; templates may default true for “new period” templates |
| Show placeholders in picker | Hidden by default; addressing queue / “include placeholders” for creators & admins |
| Free-text on roster UI | Simple name field alongside user picker |
| Venue / address on CG | **Omit in V1** (privacy) unless you ask for private notes later |
| FCM for CGs | Unchanged — no per-CG topics in V1 |
| Id tracker for `cell_groups` | Follow existing post/user id patterns in the codebase |

Out of scope (do not block V1): self-claim merge, create-from-CG, trends, Youth Online as a CG record, multi-location directory, co-leader orphan claim.

---

## Implementation checklist (for later chat)

```
- [x] Phase 0 product + companion user-model locks — 2026-08-02
- [ ] Model: CellGroup + User.`CreatedByUserID` + User.`IsPlaceholder` + unit tests
- [ ] Backfill: empty AuthID → IsPlaceholder true (CreatedByUserID empty)
- [ ] Callable CF: createPlaceholderUser (+ harden Auth link as needed)
- [ ] firestore.rules: CG tiers; placeholder paths; do not naively open users create
- [ ] Enhance SelectUsersPage: create-when-missing (medium gate)
- [ ] Pages: lib/pages/cell_groups/ + home_page (`Icons.groups`); area-admin create CG
- [ ] EventMetadata/Head + templates: CellGroupIDs
- [ ] Side track: IsPeriodParent + editable ParentID on title/subtitle edit page
- [ ] flutter analyze && flutter test test/unit/
- [ ] Update AGENTS.md Recent changes when shipped
```

---

## Related docs & code

- [`docs/post-attendance-interest.md`](post-attendance-interest.md) — RSVP vs membership; privacy split pattern
- [`docs/post-tags-notification-streams.md`](post-tags-notification-streams.md) — tags / `youth-cg` stream
- [`docs/users-volunteers-improvement.md`](users-volunteers-improvement.md) — user/volunteer model (companion change)
- Shared picker: `lib/pages/personal/select_users_page.dart` (attendance, roles, contributors, …)
- Parent edit surface: `lib/pages/events/edit_title_subtitle_page.dart`
- Info content: `assets/info/ctrim_info/cell_group.json`
- Nav shell: `lib/pages/home_page.dart` (Bulletin / CTRIM / Personal → + Cell Groups)
- Topics: `lib/utility/notification_topics.dart` (`kindYouthCaregroup`)
- Rules today: `users` **create = admin only** (`firestore.rules`) — placeholders via **CF**, not a wide open client create

---

## Discussion log

| Date | Notes |
|------|--------|
| 2026-08-01 | Initial draft under Caregroups name. |
| 2026-08-01 | Renamed product to **Cell Group**. Locked: tiered visibility; roster = registered + free-text + user-model companion; bulletin = meeting proof; no trends in V1. |
| 2026-08-01 | Post link: **`CellGroupIDs` list** on supplemental metadata + head denorm (not singular id; not via tags). Joint sessions = multi-id. CG has **1+ leader owners**. Posting strongly encouraged, not required. |
| 2026-08-01 | Clarified UX: main path is multi-select on post create/edit; post owner can include other CG ids. Create-from-CG and template pre-fill are optional conveniences, not the permission model. |
| 2026-08-01 | Templates **will** pre-fill `CellGroupIDs`. Season **parent** posts group CG meetings for a period; create-from-CG deferred. Wanted: **editable ParentID** (today set-once at create; needs ChildrenIDs rewiring). |
| 2026-08-01 | Agreed: designated period/season posts get an explicit **supplemental metadata field** (lean bool); not tags, not “has children”. Pairs with editable ParentID picker. |
| 2026-08-02 | Companion user model: CG leaders create **placeholder `users`** (empty `AuthID`); **`CreatedByUserID`** scopes who may Link Auth; post-link freeze to area admins; hide placeholders from global pickers; keep free-text for one-offs; co-leader orphan claim deferred. |
| 2026-08-02 | Locked **`IsPlaceholder` as stored bool** (not derived from empty Auth) for filter/queue “who needs addressing”; clear flag on successful link. |
| 2026-08-02 | Locked: multi-CG membership; leader-managed roster; shared SelectUsersPage create entry; legacy empty-Auth → IsPlaceholder backfill; `IsPeriodParent`; ParentID edit = author/area admin; side-track ship; Belfast-only; no Youth Online CG yet; `Icons.groups`; attendance = post attendance; trail ~3–4. |
| 2026-08-02 | Placeholder create via shared **`SelectUsersPage`**; `cell_groups` + supplemental roster; **CF for placeholder create**, client+rules for CG content. |
| 2026-08-02 | Final Phase 0: medium create-placeholder gate; legacy CreatedBy empty; parent picker on **title/subtitle edit**; guest cards name+cadence; Cell Groups tab home; area admin creates CG records. Phase 0 **done**. |
