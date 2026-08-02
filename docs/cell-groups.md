# Cell Groups — design & implementation handoff

> **Purpose:** Living design for a first-class **Cell Group** section and data model (beyond bulletin posts alone).  
> **Created:** 2026-08-01  
> **Status:** Planning — product + companion user-model (temp profiles) largely locked; some IA / tier details still open  
> **Start here in a new chat:** “Continue cell groups from `docs/cell-groups.md`”  
> **Supersedes:** earlier draft named `docs/caregroups.md` (renamed after product language lock)

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

**Still open:** guest-visible trail depth; whether **templates** may store default `CellGroupIDs` (optional convenience — see below).

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

**Lean lock for planning:** start with **A** — a boolean on metadata, e.g. `IsPeriodParent` (or `IsSeasonParent` if you prefer church wording). Revisit enum only if a second container type appears soon.

Optional later (not required for V1):

- `PeriodStart` / `PeriodEnd` on the same metadata (or on head) for “current season” picking
- Denorm a tiny flag on `EventHead` **only if** we need to filter season posts in the bulletin list without loading metadata

**What the flag enables:**

1. **Editable ParentID picker** — offer posts marked as period parents (not every post in the feed).
2. **CG / leader UX** — “attach to this season” without guessing.
3. **Admin clarity** — season containers are explicit, not tribal knowledge.
4. Future create-from-CG can default to the active period parent if dates are added later.

**Who sets it:** post owner/editor or admin when creating/editing the season container post (toggle in edit UI). Templates could also default `IsPeriodParent: true` for a “new season” template.

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
| **Member / leader of that CG** | On roster or marked leader | Roster (at least for own group); manage own group’s meeting posts / membership per rules |
| **Admin / oversight** | App admins / pastoral oversight | Full directory detail, all rosters, edit any group, reporting later |

**Rules must enforce tiers** — client-only hiding is not privacy (same lesson as post attendance). World-readable docs may only hold guest-safe fields; roster/venue in private supplemental or locked subcollections.

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
| **What a “temp account” is** | A real `users/{uid}` doc with **empty `AuthID`** (same placeholder shape Register User already supports). Not a separate collection. |
| **Who creates** | A **CG leader/owner** (of a group they lead) may create a placeholder profile for roster use. Area admins keep full Register User. |
| **`CreatedByUserID`** | New field on `users/{uid}`: volunteer **`users` uid** of the creator (not Auth UID — stable if the creator later re-links). Set once at create; do not rewrite when Auth is linked. |
| **Who may link / reassign Auth** | **Creator** (`CreatedByUserID` matches their `users` id) **or area admin**. Not every CG leader app-wide. |
| **After successful link** | Prefer **freeze** further Auth changes on that profile to **area admins only** (stops a leader quietly re-pointing a live account). Creator may still correct **name** on placeholders they own. |
| **What creator must not do** | Set `IsLeader` / `IsAreaAdmin`, edit unrelated users, or broadly edit Volunteers directory fields beyond name (+ Auth link while still a placeholder). |
| **Directory / pickers** | Hide empty-`AuthID` placeholders from Belfast Volunteers list and program role pickers by default (admin opt-in later if needed). Avoid directory pollution. |
| **Free-text on CG roster** | **Keep** for true one-offs who will never register. Prefer a **placeholder `User`** when you expect them to get an app account later. |
| **Claim / promote flow** | Person registers with email → creates `everyone/{authId}` → leader opens the placeholder → Link account by email → reuse `UserAuthLinkService` (existing conflict checks: email must exist; Auth not already owned by another `users` doc). |
| **Rules** | Enforce “creator or area admin may write `AuthID` on a placeholder they own” in **`firestore.rules`** — client-only gating is not enough. |
| **Co-leader orphan gap** | V1: if the creating leader leaves, only an **area admin** can claim that placeholder. **Later (not V1):** optionally allow other leaders of a CG that already has this uid on its roster. |

### `User` field additions (lean)

| Field | Type | Notes |
|-------|------|--------|
| `CreatedByUserID` | string | Creator’s `users/{uid}`; empty/absent for admin-created or legacy profiles |
| *(optional)* `IsPlaceholder` | bool | Explicit flag if empty `AuthID` alone is too ambiguous in queries; otherwise derive `authID.isEmpty` |

No requirement in V1 for `CellGroupIds` on the user doc (roster remains on the CG). Revisit if “My cell group” on Personal needs a reverse index.

### Permission matrix (Auth link)

| Actor | Create placeholder | Edit name on placeholder | Link / reassign Auth (while unlinked) | Reassign Auth after linked | Set Leader/Admin flags |
|-------|--------------------|---------------------------|----------------------------------------|----------------------------|------------------------|
| Creating CG leader | Yes (for roster) | Own creations | Own creations only | No (admin) | No |
| Other CG leader | Own placeholders only | Own creations only | Own creations only | No | No |
| Area admin | Yes | Any | Any | Yes | Yes |
| Signed-in member | No | No | No | No | No |

### Implementation notes (when coding)

1. Extend `User` + `User.fromMap` / `toJson` with `CreatedByUserID` (PascalCase Firestore key).
2. CG (or Personal) “Add member” flow: create placeholder with `CreatedByUserID = currentUser.id`, empty `AuthID`, then add uid to CG roster.
3. Scoped Link UI for creators (not full Edit User) — call `UserAuthLinkService.linkAuth`.
4. Filter `allUsers` / selectors: exclude empty Auth unless admin or “include placeholders”.
5. Unit tests for model + auth-link permission helper; rules tests if you have them.
6. Cross-update Phase 6 notes in the users/volunteers handoff when this ships.

### Still open (user model)

- Exact UI entry points (CG roster only vs also a limited Personal tool).
- Whether `IsPlaceholder` is stored or derived.
- Self-claim / “this is me” merge — out of scope for V1.

---

## Permissions & privacy

| Concern | V1 lean |
|---------|---------|
| Section visible | **Yes** for everyone, tiered detail |
| Roster names | Not guest-visible; rules-enforced |
| Edit group / roster | Any listed **leader/owner** of that CG + admin — confirm |
| Venue / home address | Private or omit in V1 |
| Meeting proof | Linked posts; guest may see titles/dates only |

Map tiers onto `everyone.isUser`, admin flags, and any new cell-leader capability from the user-model work.

---

## Phased delivery

### Phase 0 — Product lock — mostly done

Lock decisions; bulletin↔CG mechanics + companion user-model (placeholders / `CreatedByUserID`) captured below. Remaining open questions are mostly IA / tier matrix / location scope.

### Phase 0.5 — Period parents + editable `ParentID` (side track / precursor)

- Metadata flag for designated period/season posts (`IsPeriodParent` or agreed name)
- Toggle in post edit UI (+ optional template default)
- Mutable parent on metadata + bidirectional `ChildrenIDs` sync
- Parent picker preferably filtered to period-marked posts
- Unblocks season attach without create-from-CG

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
| 15 | Period parent marker | **Yes** — supplemental field on metadata (lean: bool `IsPeriodParent` / similar). Not inferred from children; not a post tag. | 2026-08-01 |
| 16 | Placeholder users | CG leaders may create `users` with empty `AuthID` for roster names; promote later via Auth link. | 2026-08-02 |
| 17 | `CreatedByUserID` | On `users/{uid}`: creator’s volunteer uid. Only **creator** or **area admin** may link Auth while still a placeholder. | 2026-08-02 |
| 18 | Post-link Auth freeze | After a successful Auth link, further Auth reassign is **area admin only**. | 2026-08-02 |
| 19 | Placeholder visibility | Hide empty-`AuthID` profiles from Volunteers list / program pickers by default. | 2026-08-02 |
| 20 | Free-text vs placeholder | Free-text for never-register one-offs; placeholder `User` when a real account is expected. | 2026-08-02 |
| 21 | Co-leader claim | **Not V1** — orphan placeholders after creator leaves → area admin only; optional later: other leaders of a CG that already lists that uid. | 2026-08-02 |

---

## Open questions

### Identity & scope

1. ~~Product name?~~ → **Cell Group** (locked).
2. One directory for **all CTRIM locations**, or start **Belfast-only**?
3. Include **Youth Online Caregroup** as a normal cell group record (with special tag), or keep it notify-only for now?

### People

4. ~~Registered vs free-text?~~ → **Registered + placeholder users + free-text** (locked).
5. Can someone belong to **multiple** cell groups?
6. ~~One senior leader vs many?~~ → **1+ leaders/owners** (locked). Optional primary contact later.
7. Do members self-join, or is roster **leader-managed only**?
8. ~~User model change?~~ → **Placeholder `users` + `CreatedByUserID` + scoped Auth link** (locked — see Companion). Remaining: UI entry points; `IsPlaceholder` stored vs derived.

### Meetings & bulletin

9. ~~Required every week?~~ → **Strongly encouraged**, not required (locked).
10. ~~Association shape?~~ → **`CellGroupIDs` on metadata + denorm on head** (locked lean).
11. ~~Templates / create-from-CG?~~ → Templates **pre-fill** `CellGroupIDs` (locked). Create-from-CG **deferred** (season parent problem).
12. Editable `ParentID` UX: where in the UI? Picker filtered to `IsPeriodParent == true`?
13. Exact field name: `IsPeriodParent` vs `IsSeasonParent` vs kind enum?
14. Period dates on the season post in V1, or flag-only first?
15. What does each visibility tier see on the CG meeting trail (title/date only vs open post vs attendance)?
16. Does post **attendance** double as “who came”, or is that later / separate?
17. Ship editable ParentID + period flag as one small side PR before CG V1?

### App IA

14. Fourth bottom-nav icon?
15. ~~Guests see section?~~ → **Yes**, least detail (locked).
16. Day-to-day management in Cell Groups tab vs Personal?

### Technical

17. Confirm collection id `cell_groups`?
18. Reuse `Location` strings from posts / `user_locations`?
19. Cloud Functions needed in V1 for private writes / counts, or client + rules enough?

---

## Implementation checklist (for later chat)

```
- [x] Phase 0 companion user-model notes (placeholders / CreatedByUserID) — 2026-08-02
- [ ] Finish remaining Phase 0 open questions (location scope, tier field matrix, self-join)
- [ ] Model: CellGroup + User.CreatedByUserID + unit tests
- [ ] DB manager: lib/firebase/db_managers/
- [ ] firestore.rules (tiered CG public vs private; placeholder Auth write = creator or area admin)
- [ ] AppContext or CellGroupContext if list caching needed
- [ ] Pages: lib/pages/cell_groups/ + home_page nav destination
- [ ] Scoped Link-account UI for creators (reuse UserAuthLinkService); hide placeholders from pickers
- [ ] EventMetadata + EventHead `CellGroupIDs` (list; joint sessions); keep in sync like TagIDs
- [ ] PostTemplate (+ mapper): store / apply `CellGroupIDs`
- [ ] `IsPeriodParent` (or agreed name) on EventMetadata + edit/template UI
- [ ] Editable `ParentID` (mutable metadata + ChildrenIDs sync + UI; picker can filter period posts) — side track
- [ ] flutter analyze && flutter test test/unit/
- [ ] Update AGENTS.md Recent changes when shipped
```

---

## Related docs & code

- [`docs/post-attendance-interest.md`](post-attendance-interest.md) — RSVP vs membership; privacy split pattern
- [`docs/post-tags-notification-streams.md`](post-tags-notification-streams.md) — tags / `youth-cg` stream
- [`docs/users-volunteers-improvement.md`](users-volunteers-improvement.md) — user/volunteer model (companion change)
- Info content: `assets/info/ctrim_info/cell_group.json`
- Nav shell: `lib/pages/home_page.dart`
- Topics: `lib/utility/notification_topics.dart` (`kindYouthCaregroup`)

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
