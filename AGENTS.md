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

- **Cell Groups** — Phase 1 (foundation) shipped; next Phase 2 operating rhythm. Handoff: [`docs/cell-groups.md`](docs/cell-groups.md).
- **Post tags & notify streams** — V1 in place; handoff in [`docs/post-tags-notification-streams.md`](docs/post-tags-notification-streams.md). Deploy `firestore.rules` for `post_tags`; seed starter tags from Manage Post Tags.
- **Post attendance & interest** — V1 code in place; handoff/checklist in [`docs/post-attendance-interest.md`](docs/post-attendance-interest.md). Deploy `firestore.rules` before privacy testing.
- **Users / Belfast Volunteers refactor** — plan and audit in [`docs/users-volunteers-improvement.md`](docs/users-volunteers-improvement.md) (typed roles, Volunteers UI, schedule sync). Continue across chats from that doc.
- **Stakeholder documentation** — product-facing pages in [`docs/stakeholders/`](docs/stakeholders/) (MkDocs Material → GitHub Pages). Config: `mkdocs.yml`. Continue with: “Continue stakeholder documentation from `docs/stakeholders/overview.md`”.

## Recent agent-relevant changes

- **2026-08-04** — Cell Groups Phase 1: `CellGroup` + `cell_groups` / supplemental roster; nav `Icons.groups`; area-admin CRUD + leader roster; `CellGroupIDs` on head/metadata/templates; meeting trail; CG-leader placeholder create via CF `CellGroupID`. Deploy `firestore.rules` + `create_placeholder_user`; seed `id_tracker/cell_groups` (`{id: "1"}`).
- **2026-08-04** — Stakeholder docs site: MkDocs Material (`mkdocs.yml`, `docs/stakeholders/` only) + GitHub Pages workflow `.github/workflows/docs-pages.yml`. Preview: `pip install -r requirements-docs.txt && mkdocs serve`. Enable Pages source “GitHub Actions” after first deploy on `main`.
- **2026-08-04** — Placeholder users (Cell Groups Phase 0.75): `User.IsPlaceholder` + `CreatedByUserID`; CFs `create_placeholder_user` / `link_user_auth` / `backfill_placeholder_flags`; `SelectUsersPage` create-when-missing (admin/post author); Volunteers hide placeholders + toggle. Deploy functions + `firestore.rules`; run backfill once.
- **2026-08-04** — Access hardening: `firestore.rules` users/`user_tags`/`id_tracker`/`everyone` flag updates align with `isAreaAdmin`; `EveryoneDBManager.setAsUser` syncs `isAreaAdmin`; in-page `RoleAccessGate` on manage tags/locations, register/edit user, and template pages. Helpers: `User.canManageVolunteers` / `canManagePostTemplates`. Deploy `firestore.rules`.
- **2026-08-02** — Info section add/edit/delete (churches, testimonials, CTRIM info) gated by `User.canManageInfo` (`isAreaAdmin || isLeader`); guests and regular users never see Add/Edit UI. Deploy `firestore.rules` for leader writes on `information`.
- **2026-08-02** — Period parents side track: `IsPeriodParent` on metadata (+ head denorm) and templates; editable `ParentID` with bidirectional `ChildrenIDs` sync on Title & details (`EditHeadDetailsPage` / `SelectPeriodParentPage`). Author or area admin only. See `docs/cell-groups.md` Phase 0.5.

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
