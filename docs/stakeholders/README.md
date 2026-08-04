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
| [overview.md](overview.md) | Draft | Product overview for stakeholders |

Add new pages here, then list them under `nav:` in `mkdocs.yml`.

## Continue on Cursor / cloud

In a new agent chat against **ctrim_app**, say:

> Continue stakeholder documentation from `docs/stakeholders/overview.md`

Keep stakeholder copy non-technical. Put agent/dev handoffs in `docs/` (parent of this folder), not here.

### First-time GitHub Pages setup

After the workflow has run once on `main`:

1. Repo **Settings → Pages**
2. **Source:** GitHub Actions
3. Confirm the deploy succeeded under **Actions**

Private repos need a plan that includes GitHub Pages.
