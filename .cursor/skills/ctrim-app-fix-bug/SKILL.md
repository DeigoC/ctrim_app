---
name: ctrim-app-fix-bug
description: Fix a bug in ctrim_app with minimal changes and test coverage. Use when debugging, fixing regressions, or resolving analyzer/test failures in ctrim_app.
disable-model-invocation: false
---

# Fix bug — ctrim_app

1. **Reproduce** — expected vs actual; check `test/unit/models/`
2. **Failing test** — add before fixing when practical
3. **Minimal fix** — no unrelated refactors
4. **Verify** — `flutter test test/unit/` and `flutter analyze`

## Common pitfalls

- `cloud_firestore` in pages/widgets — move to manager/model
- `notifyListeners()` outside `AppContext`
- Empty Quill delta — normalize to `[{'insert': '\n'}]` before `Document.fromJson` (see `_safeDocumentFromJson` in `quill_editor_wrapper.dart`)
- `Timestamp` vs `DateTime` in models
