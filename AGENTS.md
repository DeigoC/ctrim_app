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

- **2026-07-04** — Users/Volunteers Phase 3: profile hub, location filter, schedule badge fix; see `docs/users-volunteers-improvement.md`.
- **2026-07-04** — Users/Volunteers Phase 2: `UserScheduleService` for role/post pruning; see `docs/users-volunteers-improvement.md`.
- **2026-07-04** — Users/Volunteers Phase 1: typed `UserRoleAssignment` / `UserPostInvolvement`; see `docs/users-volunteers-improvement.md`.
- **2026-07-04** — Users/Volunteers Phase 0: awaited supplemental Firestore writes; `ViewUserRolesPage` Schedule/Posts tabs when `allowPostView`; see `docs/users-volunteers-improvement.md`.
- **2026-07-04** — Wide-screen home shell: `NavigationRail` (≥900px) in `home_page.dart`; CTRIM section uses vertical subsection nav on wide screens in `information_home.dart` (mobile keeps bottom nav + horizontal tabs).
- **2026-06-29** — Web push aligned with worship pattern: `send_each_for_multicast` CF, topic fan-out via `web_topics` only, `WebNotificationLifecycle`, `NotificationTokenResolver`; deploy `functions/` + `firestore.rules` to `ctrim-8b49b`.
- **2026-06-29** — Added `ResponsiveLayout` + `ResponsiveContent`; refactored inline 768px gutter checks across pages.
- **2026-06-25** — Documented Dart MCP setup and `add_roots` URIs in AGENTS.md.
- **2026-06-25** — Added `.cursor/rules/`, skills (new-feature, fix-bug, info-section, web-debug, maintain-agent-docs), and this file; Quill widgets are `QuillEditorWidget`/`QuillViewerWidget` in `quill_editor_wrapper.dart`.

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
