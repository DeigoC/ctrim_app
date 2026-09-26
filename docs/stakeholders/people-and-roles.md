# People & roles

How people show up in the app, and what different levels of access roughly mean.

This page is safe for a public product audience: it describes **what people can do**, not how accounts are stored or secured behind the scenes.

Short definitions of **guest**, **community profile**, **placeholder**, **Leader**, and related terms: [Key concepts](key-concepts.md).

## At a glance

| Who | Roughly can… |
|-----|----------------|
| **Guest** | Browse bulletin, information, and public cell-group cards without signing in |
| **Signed-in person** | Interest (“follow updates”), notification preferences, and richer personal options once they have an account |
| **Community profile** | Appear in the People directory; My Schedule, My Posts, Team rota, and assignments when organisers involve them |
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
| My Schedule / My Posts / Team rota | — | When they have a profile & assignments | Yes | Yes | Yes |
| Who's who (Personal → People & teams) | — | Yes* | Yes | Yes | Yes |
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

**Area admin** is a step above **Leader**: every area admin is a Leader, and also looks after admin work scoped to the **area(s)** they are assigned to. That includes registering and editing people in that scope, tags and locations (a cover photo and gallery for the place itself), cell groups, and extra pages on a church hub. Team and post tags get a colour when added (you can change or clear it). Each team tag can also have a **short description** of what that team is for, and one **main image**. Each church location has its own **heads** and its own **photos**. Opening a team shows, for the site you pick, those heads, the people on the team there, and that team's schedule for the past three months and the next three months. Area admins choose the heads and photos for each location. A **team tag** can be hidden from **guests**: the label drops off profiles, the People directory, schedule details, and the public team-tags list. The person still appears, and a schedule line stays unless that line itself is marked hidden from guests. Signed-in people still see the tag. Controls will continue to be gated by area assignment as that model lands fully.

## Site admin *(planned)*

**Site admin** is the working title for a level **above** area admin: the same kind of admin power **without** being limited to a single area’s location scope.

## Names guests see

On a profile link, a team list, pastors, a schedule role, or the speaker on a bulletin card, people who are not signed in see a first name and the first letter of the surname (for example Adam B.). That person can turn on **Full surname for guests** in Personal settings, and an area admin can set the same choice when editing their profile. Signed-in people still see full names.

## People directory

**Who's who** (from Personal → People & teams) is a searchable list of community profiles. It opens on your location (for example Belfast, Portadown, North Coast) and on people who **serve**. When that location has a cover photo, the photo appears at the top of the list; it stays while you keep that place selected and hides on **All**.

Use **Refine & sort** (tune icon in the app bar) to change **location**, **Serving**, role filters, team tags, sort order, and **Placeholders**. The app bar title still reflects your chosen location (for example **Belfast People**). When sorted by surname, names are grouped **A–Z** by last name. Each row shows a photo, name, location, and at most one role badge plus one team tag — open a profile for the full picture. Opening a profile updates the address so you can share or bookmark it; hidden, archived, and placeholder profiles are not reachable from a public link.

If a **search** finds no one under the current filters, the directory still shows people whose names match **without** those filters (other locations, everyone not only Serving, and placeholders you are allowed to see), with a short note and a **Widen search** action — so organisers do not invent a second profile for someone who already exists.

**Serving** means any of:

- Leader or Area admin  
- A **team tag** (Worship, Welcome, and similar)  
- Listed as a leader on a cell group (including paused groups, not archived ones)

Turn **Serving** off in **Refine & sort** to see everyone at that location — including people who only registered to follow updates. Registering still creates a profile; it does not put them in the serving list until an organiser tags them or they become a Leader / cell-group leader.

Role filters (in **Refine & sort**, on top of Serving or All):

- **Leaders** — everyone with Leader access, including area admins  
- **Admins** — area admins only (a tighter view; you do not also select Leaders)  
- **CG Leaders** — people listed as a leader on a cell group

Each person shows at most one of **Admin** or **Leader** from their profile permissions (Admin is the higher badge). **CG Leader** can appear alongside either — it is not a separate switch on the person.

When organisers pick people for **programme roles**, lead speaker, contributors, pastors, or cell-group leaders, the picker also starts on serving people (turn Serving off there too if you need someone else). Attendance, expected attendees, and cell members still list everyone.

Opening someone’s profile also shows their **recent activity** — a short list of the last few things they saved in the app (for example creating a bulletin post, editing a profile, or adding a church page). Anyone who can open the profile can see those last few lines. **Area admins** can open the full activity list, including which record was changed.

The profile also lists up to three **recent contributor posts** (from the bulletin posts already loaded). Tap a post to open it. **View posts** still opens the full list of posts they author or contribute to.

When you are signed in, the profile also lists **cell groups** that person belongs to (from the group roster or as a listed leader). If they are in at least one group, a banner summarises the **past 3 weeks** of linked meetings (the same window as the Cell Groups activity snapshot): check-ins as an attendee, or **hosting** as a listed group leader (leaders are not listed as guests). Expand **Recent meetings** to see up to four of those posts and open them. Guests do not see these details. Tap a group to open its detail page.

## Placeholders

Sometimes organisers need to assign or list someone **before** that person has signed in. The app supports **placeholder** people for that — useful for attendance, cell groups, and programmes.

When you pick people (programmes, attendance, cell members, and similar), **placeholder** profiles are listed so they can be assigned like anyone else. Location, Serving, team tags, and **Placeholders** are in **Refine & sort** (the tune icon), not a row of chips across the top. A short “Showing: …” line tells you what the list is narrowed to. Leaders and area admins can **create placeholder** from the picker when a search finds no match — search first so you do not duplicate someone already in the directory. If filters hide a name match, the picker shows those matches (and only offers create when nothing matches even without filters). The People directory still hides placeholders by default; turn on **Placeholders** in **Refine & sort** to review them.

The person who created a placeholder can later correct the name and **link** it to a real account. **Any area admin** can do the same for every placeholder. If that placeholder is a member of a cell group, **any listed leader of that group** can also edit the name and link an account — even if they did not create it, and even if the person belongs to more than one group. After the account is linked, only area admins can change the login link.

## Related pages

- [Key concepts](key-concepts.md)  
- [Events & bulletin](events-and-bulletin.md)  
- [Information](information.md)  
- [Personal](personal.md)  
- [Cell Groups](cell-groups.md)  
- [Roadmap](roadmap.md)
