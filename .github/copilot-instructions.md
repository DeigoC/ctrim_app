# Copilot Instructions — ctrim_app

This is a Flutter application built with Firebase (Firestore, Auth, Analytics, Messaging, App Check, Cloud Functions).
It serves a church/community organisation and includes event management, information pages, a personal section, and a bulletin board.

---

## Project Structure

```
lib/
  firebase/             # Firebase interaction layer
    auth_manager.dart
    functions_manager.dart
    messaging_manager.dart
    db_managers/        # One manager per Firestore collection
  models/               # Plain Dart model classes (no Flutter dependency where avoidable)
    event/              # EventHead, EventBody, EventLog, EventMedia, EventMetadata, EventProgram
    info/               # ChurchInfo, CtrimInfo, TestimonialInfo
    post_template.dart
    user.dart
  pages/                # Full screens (one subdirectory per top-level section)
    events/
    information/
    personal/
  src/
    settings/           # SettingsController, SettingsService, SettingsView
    localization/
  utility/              # App-wide helpers and ChangeNotifier providers
    app_context.dart    # Central ChangeNotifier; holds users, event heads, shared prefs
    app_shared_preferences.dart
    event_context.dart
    local_data_manager.dart
  widgets/              # Reusable widgets (posts, media, bulletin, info, personal)
test/
  unit/
    models/             # One *_test.dart per model class
```

---

## Key Conventions

### Models
- Model classes live in `lib/models/`. They are plain Dart; avoid importing Flutter widgets inside them unless absolutely necessary (`EventHead` is an exception due to `Color`/`TimeOfDay`).
- Every model exposes:
  - A primary constructor with named parameters and sensible defaults.
  - A `fromMap(String id, Map<String, dynamic> data)` factory-style constructor for Firestore/Hive deserialization.
  - A `toJson()` method returning a `Map<String, dynamic>` for serialization.
- Internal state uses private fields prefixed with `_`; access is through explicit getters and setters.
- List getters return `UnmodifiableListView` to prevent external mutation.
- Firestore timestamps are always handled as `Timestamp` (from `cloud_firestore`); convert to/from `DateTime` inside the model.

### Firebase / Firestore
- All Firestore reads and writes go through a dedicated manager in `lib/firebase/db_managers/`.
- Use `cloud_firestore` types (`Timestamp`, `DocumentSnapshot`, `CollectionReference`) only inside `firebase/` and `models/`; never in widgets or pages.
- Cloud Functions calls go through `functions_manager.dart`.

### State Management
- The app uses `provider` (`ChangeNotifier`). The root provider is `AppContext`.
- `AppContext` holds the current user, all event heads, shared preferences, and Firebase Analytics.
- Call `notifyListeners()` only from within `AppContext` methods, not from external code.

### UI / Pages
- Pages are under `lib/pages/`. Each major section (events, information, personal) has its own subdirectory.
- Use `flutter_localizations` / `intl` for any user-visible strings that may need translation.
- Rich text editing uses `flutter_quill`; wrap it in `QuillEditorWrapper`.
- Media display uses `photo_view` for images and `video_player` for video.

### Assets
- Images: `assets/images/`
- Testimonials: `assets/info/testimonials/`
- Ctrim info: `assets/info/ctrim_info/`
- Church info: `assets/info/churches/`
- Personal: `assets/personal/`

---

## Testing

- **Unit tests** live in `test/unit/models/`, one file per model class, named `<model_name>_test.dart`.
- **Always add or update tests** when adding or modifying a model class.
- Test groups mirror the model's public API: `constructor`, `fromMap`, `toJson`, getters, setters, collection management.
- Prefer real objects over mocks for pure Dart models.
- Use `mocktail` (already a dev dependency) for mocking Firebase-dependent classes.
- Run tests with: `flutter test test/unit/`
- Run the linter with: `flutter analyze`

---

## Adding a New Feature — Checklist

1. **Model** (if new data shape needed): add to `lib/models/`, include `fromMap`, `toJson`, unmodifiable list getters.
2. **DB Manager** (if Firestore interaction needed): add or update the relevant file in `lib/firebase/db_managers/`.
3. **AppContext / EventContext** (if the feature needs app-wide state): add methods and notifyListeners where appropriate.
4. **UI**: add page under `lib/pages/<section>/` or widget under `lib/widgets/`.
5. **Tests**: add `test/unit/models/<new_model>_test.dart` and update any affected existing test files.
6. **Lint check**: run `flutter analyze` and resolve any warnings before committing.

---

## Do Not

- Do not place business logic inside widget `build` methods.
- Do not import `cloud_firestore` in widget or page files.
- Do not use `print()` for logging (use `debugPrint()` or remove before committing).
- Do not add new top-level dependencies without checking `pubspec.yaml` first for an existing package that covers the need.
- Do not modify `pubspec.yaml` version numbers (`version: 0.8.4+31`) — those are managed manually per platform.
