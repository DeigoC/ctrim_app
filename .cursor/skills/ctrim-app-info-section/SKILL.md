---
name: ctrim-app-info-section
description: Work on ctrim_app information pages (churches, testimonials, CTRIM info, Quill content, InfoRepository, Firestore info managers). Use when editing information_home, church/testimonial/ctrim info pages, info models, or migrating info content.
disable-model-invocation: false
---

# Info section — ctrim_app

## Architecture

Firestore via `InfoRepository` + `info_db_manager.dart`, cached by `LocalDataManager`.

Sections: `churches`, `testimonials`, `ctrim_info`.

Models: `ChurchInfo`, `CtrimInfo`, `TestimonialInfo` in `lib/models/info/`. Testimonial file: `testimonial_into.dart` (typo in filename).

Pages: `lib/pages/information_home.dart`, `lib/pages/information/`.

## Quill

Use `QuillEditorWidget` / `QuillViewerWidget` from `lib/widgets/quill_editor_wrapper.dart`. Harden empty deltas before `Document.fromJson`.

## Legacy

`assets/info/` JSON — seed/reference only, not primary runtime source.

See [reference.md](reference.md).
