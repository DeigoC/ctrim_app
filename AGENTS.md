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

- **Cell Groups** — planning nearly locked; [`docs/cell-groups.md`](docs/cell-groups.md). Belfast V1; placeholders + `IsPlaceholder`; period-parent side track. Continue with: “Continue cell groups from `docs/cell-groups.md`”.
- **Post tags & notify streams** — V1 in place; handoff in [`docs/post-tags-notification-streams.md`](docs/post-tags-notification-streams.md). Deploy `firestore.rules` for `post_tags`; seed starter tags from Manage Post Tags.
- **Post attendance & interest** — V1 code in place; handoff/checklist in [`docs/post-attendance-interest.md`](docs/post-attendance-interest.md). Deploy `firestore.rules` before privacy testing.
- **Users / Belfast Volunteers refactor** — plan and audit in [`docs/users-volunteers-improvement.md`](docs/users-volunteers-improvement.md) (typed roles, Volunteers UI, schedule sync). Continue across chats from that doc.
- **Stakeholder documentation** — product-facing drafts in [`docs/stakeholders/`](docs/stakeholders/). Continue with: “Continue stakeholder documentation from `docs/stakeholders/overview.md`”.

## Recent agent-relevant changes

- **2026-08-02** — Post templates embed change history `Logs` (`uid`/`log`/`ts`) on the doc; save uses `TemplateLogDialog`; viewer is `view_template_logs_page.dart`.
- **2026-08-02** — Cell Groups companion user model locked in `docs/cell-groups.md`: placeholder `users` (empty `AuthID`), `CreatedByUserID`, scoped Auth link (creator/admin), post-link freeze, hide placeholders from pickers.
- **2026-08-02** — Key graphic save: `getKeyGraphic` is the first head `Media` image — “Set as Key Media” now prepends (`prependMediaItem`); Change cover uses `replaceKeyGraphic`. After save, ViewEventPage refreshes discard baseline so dispose does not restore pre-edit Media.
- **2026-08-01** — Post content tags (`post_tags`) + bulletin filter; FCM streams derived from location + tag `StreamKind` (Belfast IDs frozen). Design: `docs/post-tags-notification-streams.md`. Deploy `firestore.rules` for `post_tags`.
- **2026-08-01** — Web push: SW no longer re-shows FCM `notification` payloads (fixes duplicate banners); re-register also strips stale tokens from `web_topics`.

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
