# CTRIM Community (`ctrim_app`)

Flutter app for CTRIM community life: **bulletin** (events), **information**, **personal** schedule & notifications, and **cell groups**. Backend is Firebase (Auth, Firestore, Cloud Functions, Messaging, App Check).

**Current focus:** the **web app**. Native iOS / Android store releases are not prioritised right now.

This is **not** the worship-team song/setlist app (`ctrim_worship`) — that is a separate project.

## Stakeholder docs

Product-facing documentation (plain language) lives in [`docs/stakeholders/`](docs/stakeholders/) and is published with **MkDocs Material** → GitHub Pages:

**https://deigoc.github.io/ctrim_app/**

Preview locally:

```bash
python3 -m venv .venv-docs && source .venv-docs/bin/activate
pip install -r requirements-docs.txt
mkdocs serve
```

## Develop

```bash
flutter pub get
flutter analyze
flutter test test/unit/
```

Web debug: VS Code / Cursor launch profile **ctrim_app (Chrome)** (pinned to `localhost:7357`).

Agent-oriented notes for contributors working in Cursor: [`AGENTS.md`](AGENTS.md).

## Layout (short)

| Path | Role |
|------|------|
| `lib/pages/` | Screens (events, information, personal, cell groups, …) |
| `lib/models/` | Dart models |
| `lib/firebase/` | Auth, functions, messaging, Firestore managers |
| `docs/stakeholders/` | Public product docs (MkDocs) |
| `docs/*.md` | Internal engineering handoffs (not published to the docs site) |
| `functions/` | Cloud Functions (Python) |

## Privacy note for a public GitHub repo

- Do **not** commit Firebase **Admin** / service-account keys, `.env` files, or signing keystores.
- Client Firebase config (`lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`) is normal to ship with the app; protect the project with **App Check** and API key restrictions.
- Never commit **`emulators_data/`** or legacy **`assets/info/`** seed JSON (Information content is loaded from Firestore).
- Cursor / agent guidance (`.cursor/`, `AGENTS.md`, top-level `docs/*.md` handoffs) is intended to stay **local-only** when the GitHub remote is public — see `.gitignore`. Stakeholder docs under `docs/stakeholders/` remain public.
