# People & roles

How people show up in the app, and what different levels of access roughly mean.

This page is safe for a public product audience: it describes **what people can do**, not how accounts are stored or secured behind the scenes.

Short definitions of **guest**, **community profile**, **placeholder**, **Leader**, and related terms: [Key concepts](key-concepts.md).

## At a glance

| Who | Roughly can… |
|-----|----------------|
| **Guest** | Browse bulletin, information, and public cell-group cards without signing in |
| **Signed-in person** | Interest (“follow updates”), notification preferences, and richer personal options once they have an account |
| **Community profile** | Appear in the People directory; My Schedule, My Posts, and assignments when organisers involve them |
| **Serving** | Shown by default in the directory: Leader or Admin, a team tag, or cell-group leadership |
| **Placeholder** | An organiser-created name in the directory **before** that person has signed in — for attendance, cell groups, and programmes |
| **Leader** | Create posts and templates; register / add people they work with; edit the Information (CTRIM) section |
| **Area admin** | A **Leader** plus admin for their **assigned area(s)** — people, tags, locations, cell groups |
| **Site admin** *(planned working title)* | Admin **without** the area location restriction — above area admin |

**Guests** and ordinary **signed-in members** cannot edit Information or other admin surfaces. Elevated roles (**Leader**, **Area admin**, and later **Site admin**) can.

## How the tiers relate

These are not five separate “apps” — they stack:

1. **Anyone** can open the app as a **guest** and browse public content.  
2. **Signing in** unlocks personal actions (interest, notification prefs, and similar).  
3. A **community profile** is the person record organisers assign to programmes, attendance, and cell groups. Signing in creates that profile; it does **not** mean they serve. The People directory defaults to people who **serve** (Leader/Admin, a team tag, or cell-group leadership) — turn off **Serving** to see everyone.  
4. **Placeholder** profiles fill the gap when someone needs to be listed **before** they create an account — same kind of directory entry, without a sign-in yet.  
5. **Leader** is an elevated flag on a community profile. **Area admin** is a step above Leader — every area admin is a Leader, but not every Leader is an area admin.  
6. Separately, the **author** of a post (and anyone listed as a **contributor**) can edit **that** post even if they are not a global admin.

## What each tier can access

| Capability | Guest | Signed in | Community profile | Leader | Area admin |
|------------|:-----:|:---------:|:-----------------:|:------:|:----------:|
| Browse bulletin, Information, public cell-group cards | Yes | Yes | Yes | Yes | Yes |
| See interest / attendance **counts** on posts | Yes | Yes | Yes | Yes | Yes |
| Mark interest (“follow updates”) and see who is interested | — | Yes | Yes | Yes | Yes |
| Richer people / member details on posts and groups | — | Yes | Yes | Yes | Yes |
| My Schedule / My Posts | — | When they have a profile & assignments | Yes | Yes | Yes |
| People → Who's who (Personal → People) | — | Yes* | Yes | Yes | Yes |
| Recent activity on a profile (last few lines) | — | Yes* | Yes | Yes | Yes |
| Full activity list for a person | — | — | — | — | Yes |
| Create posts / use post templates | — | — | — | Yes | Yes |
| Edit **this** post (if author or contributor) | — | If listed | If listed | If listed | If listed |
| Register / add people (incl. placeholders) | — | — | — | Yes | Yes |
| Edit Information (church overview, testimonials, CTRIM pages) | — | — | — | Yes | Yes |
| Extra pages on a church hub | — | — | — | — | Yes |
| Manage tags, locations, cell-group **catalogue** | — | — | — | — | Yes |

\*Signed-in people with access to Personal can open the People directory when that section is available.

Programme lines on a post can also be marked so **guests do not see** staff-only schedule items — signed-in organisers still see the full programme.

For the shorter guest vs signed-in Personal table, see [Personal](personal.md).

## What “Leader” means

In the app, **Leader** is one role that covers different church leadership hats — for example **department leaders** and **cell group leaders**. There is overlap in practice.

Leaders should be able to:

- Create posts (and use templates)  
- Add / register people they need for their work (including placeholders when needed)  
- Edit the **Information** (CTRIM) section — church overviews, testimonials, and related pages (not the extra pages on a church hub)  

They are not a catch-all for every admin control; area-scoped settings (tags, locations, cell-group catalogue admin, and similar) stay with **Area admin** / **Site admin**.

## Area admin

**Area admin** is a step above **Leader**: every area admin is a Leader, and also looks after admin work scoped to the **area(s)** they are assigned to. That includes registering and editing people in that scope, tags and locations, cell groups, and extra pages on a church hub. Controls will continue to be gated by area assignment as that model lands fully.

## Site admin *(planned)*

**Site admin** is the working title for a level **above** area admin: the same kind of admin power **without** being limited to a single area’s location scope.

## People directory

**Who's who** (from Personal → People) is a searchable list of community profiles. It opens on your location (for example Belfast, Portadown, North Coast) and on people who **serve**.

Use the **location** chips at the top to switch site. Tap **Refine list** (tune icon in the app bar) for **Serving**, role filters, team tags, and **Placeholders**. When sorted by surname, names are grouped **A–Z** by last name. Each row shows a photo, name, location, and at most one role badge plus one team tag — open a profile for the full picture.

**Serving** means any of:

- Leader or Area admin  
- A **team tag** (Worship, Welcome, and similar)  
- Listed as a leader on a cell group (including paused groups, not archived ones)

Turn **Serving** off in **Refine list** to see everyone at that location — including people who only registered to follow updates. Registering still creates a profile; it does not put them in the serving list until an organiser tags them or they become a Leader / cell-group leader.

Role filters (in **Refine list**, on top of Serving or All):

- **Leaders** — everyone with Leader access, including area admins  
- **Admins** — area admins only (a tighter view; you do not also select Leaders)  
- **CG Leaders** — people listed as a leader on a cell group

Each person shows at most one of **Admin** or **Leader** from their profile permissions (Admin is the higher badge). **CG Leader** can appear alongside either — it is not a separate switch on the person.

When organisers pick people for **programme roles**, lead speaker, contributors, pastors, or cell-group leaders, the picker also starts on serving people (turn Serving off there too if you need someone else). Attendance, expected attendees, and cell members still list everyone.

Opening someone’s profile also shows their **recent activity** — a short list of the last few things they saved in the app (for example creating a bulletin post, editing a profile, or adding a church page). Anyone who can open the profile can see those last few lines. **Area admins** can open the full activity list, including which record was changed.

When you are signed in, the profile also lists **cell groups** that person belongs to (from the group roster or as a listed leader). If they are in at least one group, a banner shows whether they **checked in** at a linked meeting in the **past 3 weeks** (the same window as the Cell Groups activity snapshot), including the date of their most recent check-in when applicable. Guests do not see check-in details. Tap a group to open its detail page.

## Placeholders

Sometimes organisers need to assign or list someone **before** that person has signed in. The app supports **placeholder** people for that — useful for attendance, cell groups, and programmes.

When you pick people (programmes, attendance, cell members, and similar), **placeholder** profiles are listed so they can be assigned like anyone else. Use the **Placeholders** chip on that picker to show only those profiles. Leaders and area admins can **create placeholder** from the picker when a search finds no match — search first so you do not duplicate someone already in the directory. The People directory still hides placeholders by default; turn on **Placeholders** in **Refine list** to review them. Later, when that person creates an account, organisers can connect it to the existing profile so history is not lost.

## Related pages

- [Key concepts](key-concepts.md)  
- [Events & bulletin](events-and-bulletin.md)  
- [Information](information.md)  
- [Personal](personal.md)  
- [Cell Groups](cell-groups.md)  
- [Roadmap](roadmap.md)
