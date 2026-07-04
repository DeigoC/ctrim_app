---
name: ctrim-app-new-feature
description: Add a new feature to ctrim_app following project conventions (model, DB manager, AppContext, UI, tests). Use when implementing new functionality, adding screens, or extending data models in ctrim_app.
disable-model-invocation: false
---

# New feature — ctrim_app

## Checklist

```
- [ ] Model (if needed): lib/models/, fromMap, toJson, unmodifiable list getters
- [ ] DB manager: lib/firebase/db_managers/
- [ ] AppContext / EventContext: app-wide state + notifyListeners
- [ ] UI: lib/pages/<section>/ or lib/widgets/
- [ ] Tests: test/unit/models/<model>_test.dart
- [ ] flutter analyze && flutter test test/unit/
```

## Order

1. Model — plain Dart, `fromMap`/`toJson`, private fields, unmodifiable lists
2. DB manager — one per collection; no direct Firestore in UI
3. State — `AppContext` or `EventContext` only if needed
4. UI — no business logic in `build`; Quill via `QuillEditorWidget`/`QuillViewerWidget`
5. Tests — real objects for models; add mock lib only if Firebase mocking needed

```bash
flutter analyze && flutter test test/unit/
```

Do not modify `pubspec.yaml` version numbers.
