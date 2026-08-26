# Stakeholder documentation

Audience-facing docs for CTRIM Community (`ctrim_app`): what the product is, who it serves, and what it does — not implementation notes.

## Published site

These files are built with **MkDocs Material** and deployed to **GitHub Pages** on push to `main` (when this folder or `mkdocs.yml` changes).

| | |
|--|--|
| **Live site** | [https://deigoc.github.io/ctrim_app/](https://deigoc.github.io/ctrim_app/) |
| **Config** | `mkdocs.yml` (repo root) · `requirements-docs.txt` |
| **Workflow** | `.github/workflows/docs-pages.yml` |

Preview locally:

```bash
python3 -m venv .venv-docs && source .venv-docs/bin/activate
pip install -r requirements-docs.txt
mkdocs serve
```

Open http://127.0.0.1:8000 — only files under this folder are published (`docs_dir`). Agent handoffs in `docs/*.md` stay private to the repo.

## Documents

| Doc | Status | Purpose |
|-----|--------|---------|
| [index.md](index.md) | Current | Site home |
| [overview.md](overview.md) | Current | Product overview |
| [key-concepts.md](key-concepts.md) | Current | Glossary (post, volunteer, interest, …) |
| [events-and-bulletin.md](events-and-bulletin.md) | Current | Events & bulletin (filters, bookmarks, related) |
| [personal.md](personal.md) | Current | Profile, schedule, prefs, share / slide decks |
| [information.md](information.md) | Current | Churches, testimonials, CTRIM info |
| [cell-groups.md](cell-groups.md) | Current | Cell Groups (in development) |
| [people-and-roles.md](people-and-roles.md) | Current | Guest → volunteer → Leader / Area admin (+ capability grid) |
| [notifications.md](notifications.md) | Current | Location-based push alerts & broadcasts |
| [platforms.md](platforms.md) | Current | iOS / Android / web |
| [roadmap.md](roadmap.md) | Current | Priorities (update as they change) |
| [how-to/index.md](how-to/index.md) | Current | How-to guides hub |
| [how-to/posts/create-a-post.md](how-to/posts/create-a-post.md) | In progress | Create a post |
| [how-to/posts/edit-a-post.md](how-to/posts/edit-a-post.md) | In progress | Edit a post (by section) |
| [how-to/information/add-or-edit-information.md](how-to/information/add-or-edit-information.md) | In progress | Information records |
| [how-to/people/register-or-edit-users.md](how-to/people/register-or-edit-users.md) | In progress | Register / edit people |
| [how-to/media.md](how-to/media.md) | Reference | Images, GIFs, video embeds |

Media files go in `assets/images/`, `assets/gifs/`, `assets/video/` (see [how-to/media.md](how-to/media.md)).

Add new pages here, then list them under `nav:` in `mkdocs.yml`. Status: **Current** = published baseline you edit as you go; **In progress** = how-tos still needing steps/screenshots.

## Continue on Cursor / cloud

In a new agent chat against **ctrim_app**, say:

> Continue stakeholder documentation from `docs/stakeholders/README.md` — edit living pages in plain language; finish how-to guides with steps and screenshots as media is ready. Do not add agent/dev handoff jargon; keep the Documents table status accurate (Current vs In progress).

Keep stakeholder copy non-technical. Put agent/dev handoffs in `docs/` (parent of this folder), not here.

### Keep in sync with the app

Major **user-facing** product changes should update the matching page here in the same work (steering: always-on `maintain-agent-docs` rule + skill). Skip for internal-only refactors. Map of areas → files is in `.cursor/skills/maintain-agent-docs/SKILL.md`.

### First-time GitHub Pages setup

After the workflow has run once on `main`:

1. Repo **Settings → Pages**
2. **Source:** GitHub Actions
3. Confirm the deploy succeeded under **Actions**

Private repos need a plan that includes GitHub Pages.
