---
name: ctrim-app-web-debug
description: Debug ctrim_app on Flutter web (Firebase Auth persistence, localhost ports, login flow, firestore.rules). Use when debugging web auth, permission-denied errors, or web-specific Firebase issues in ctrim_app.
disable-model-invocation: false
---

# Web debug — ctrim_app

## Auth persistence

- Firebase Auth on web is **origin-scoped** — different ports = different sessions
- Use launch profile **ctrim_app (Chrome)** — pinned to `localhost:7357` in `.vscode/launch.json`
- Background login from SharedPreferences exists in `lib/main.dart`; fixed port is still preferred

## Permission-denied

- Check `firestore.rules` at repo root
- Verify auth state and collection paths match rules
- Info collections may need seeded documents

```bash
flutter analyze && flutter test test/unit/
```
