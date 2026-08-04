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
| [index.md](index.md) | Draft | Site home |
| [overview.md](overview.md) | Draft | Product overview |
| [events-and-bulletin.md](events-and-bulletin.md) | Stub | Events & bulletin |
| [personal.md](personal.md) | Stub | Profile, schedule, prefs |
| [information.md](information.md) | Stub | Churches, testimonials, CTRIM info |
| [people-and-roles.md](people-and-roles.md) | Stub | Members, volunteers, admins |
| [notifications.md](notifications.md) | Stub | Alerts & broadcasts |
| [platforms.md](platforms.md) | Stub | iOS / Android / web |
| [roadmap.md](roadmap.md) | Stub | Priorities & open questions |

Add new pages here, then list them under `nav:` in `mkdocs.yml`.

## Continue on Cursor / cloud

In a new agent chat against **ctrim_app**, say:

> Continue stakeholder documentation from `docs/stakeholders/README.md` — fill stub pages in plain language (start with `events-and-bulletin.md` or whichever area we pick). Do not add agent/dev handoff jargon; update the Documents table status when a page moves past Stub.

Keep stakeholder copy non-technical. Put agent/dev handoffs in `docs/` (parent of this folder), not here.

### Keep in sync with the app

Major **user-facing** product changes should update the matching page here in the same work (steering: always-on `maintain-agent-docs` rule + skill). Skip for internal-only refactors. Map of areas → files is in `.cursor/skills/maintain-agent-docs/SKILL.md`.

### First-time GitHub Pages setup

After the workflow has run once on `main`:

1. Repo **Settings → Pages**
2. **Source:** GitHub Actions
3. Confirm the deploy succeeded under **Actions**

Private repos need a plan that includes GitHub Pages.
