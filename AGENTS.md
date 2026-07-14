# ctrim_app — Agent Guide

Flutter app for church/community events, information, personal section, and bulletin board. Firebase backend (Firestore, Auth, Analytics, Messaging, App Check, Cloud Functions). Hive used for local caching via `LocalDataManager`.

## Which project?

This file applies to **ctrim_app only**. For worship-team work, switch to the `ctrim_worship` folder or say "in ctrim_worship" in your prompt.

## Multi-root workspace

Open `ctrim_worship/lib/firebase/ctrim_projects.code-workspace` in Cursor to work across ctrim_app, ctrim_worship, firebase_hosting, my_python_stuff, and ctrim_powerpoint_utils. Rules apply per folder based on the files you edit.

## Dart MCP setup

Configured globally in `~/.cursor/mcp.json` as the **dart** server (`dart mcp-server --force-roots-fallback`). Cursor exposes it to the agent as **user-dart**.

`add_roots` is not a setting you toggle — it is an MCP tool the agent must call at the start of a Flutter session to register project paths. Without registered roots, `run_tests`, `analyze_files`, and other Dart MCP tools will refuse to run.

**Roots to register** (multi-root workspace):

| Project | URI |
|---------|-----|
| ctrim_app | `file:///Users/diego/Developer/ctrim_app` |
| ctrim_worship | `file:///Users/diego/Developer/ctrim_worship` |

**Prefer MCP over shell** when available:

| Task | Tool |
|------|------|
| Tests | `run_tests` |
| Analyzer | `analyze_files` |
| Format / fix | `dart_format`, `dart_fix` |
| Dependencies | `pub` |
| Run / debug app | `launch_app`, `hot_reload`, `get_runtime_errors` |

**Verified working** (2026-06-25): `add_roots` + `analyze_files` on ctrim_app; `add_roots` + `run_tests` on ctrim_worship.

## Cursor Agent (Auto mode)

- Rules in `.cursor/rules/` load automatically — overview always on; model/Firebase/test rules when matching files are in context
- Skills in `.cursor/skills/` activate from task descriptions (e.g. "add info page", "debug web auth")
- Prefer the **Dart MCP** tools (`analyze_files`, `run_tests`, `dart_fix`) over raw shell when available
- After significant features or non-obvious fixes, use skill **`maintain-agent-docs`** to keep rules/skills current

## Ongoing work

- **Users / Belfast Volunteers refactor** — plan and audit in [`docs/users-volunteers-improvement.md`](docs/users-volunteers-improvement.md) (typed roles, Volunteers UI, schedule sync). Continue across chats from that doc.

## Recent agent-relevant changes

- **2026-07-14** — Personal tab (web only): first visit shows `AddToHomeScreenDialog` instead of the old personal hub explainer; skipped on native and when already installed (`hasSeenPwaHomeScreenPrompt`).
- **2026-07-12** — Personal share: `ShareWebAppPage` replaces beta TestFlight/Android page; web link share + Add to Home Screen on that page (`PwaInstallService` + `web/pwa_install.js`).
- **2026-07-11** — Bulk post dates: `BulkPostDates` anchors bulk-created posts to the source post's event date (#18).
- **2026-07-11** — Web Hosting CI: merge to `main` deploys via `.github/workflows/firebase-hosting-merge.yml`; PRs get preview channels via `firebase-hosting-pull-request.yml` (secret `FIREBASE_SERVICE_ACCOUNT_CTRIM_APP`). Flutter pinned to `3.41.9` (quill 11.5.0 incompatible with 3.44).
- **2026-07-09** — Broadcast notify compose page: `SendBroadcastNotificationPage` + `EventNotificationCopy` (preset / subtitle / custom body); `Notify: Broadcast` opens the page instead of sending subtitle immediately.

## Commands

```bash
flutter pub get
flutter analyze
flutter test test/unit/
```

Web debug: use `.vscode/launch.json` profile **ctrim_app (Chrome)** — pinned to `localhost:7357`.

## Feature checklist

1. Model in `lib/models/` (`fromMap`, `toJson`, unmodifiable lists)
2. DB manager in `lib/firebase/db_managers/` if Firestore needed
3. `AppContext` / `EventContext` if app-wide state needed
4. Page under `lib/pages/<section>/` or widget under `lib/widgets/`
5. Tests in `test/unit/models/`
6. `flutter analyze` before commit

## Do not

- Business logic in widget `build` methods
- `cloud_firestore` imports in pages/widgets
- `print()` — use `debugPrint()` or remove
- New dependencies without checking `pubspec.yaml` first
- Change `pubspec.yaml` version numbers (managed manually per platform)
