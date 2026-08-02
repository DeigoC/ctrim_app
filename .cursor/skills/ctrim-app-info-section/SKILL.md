---
name: ctrim-app-info-section
description: Work on ctrim_app information pages (churches, testimonials, CTRIM info, Quill content, InfoRepository, Firestore info managers). Use when editing information_home, church/testimonial/ctrim info pages, info models, or migrating info content.
disable-model-invocation: false
---

# Info section — ctrim_app

## Architecture

Firestore via `InfoRepository` + `info_db_manager.dart`, cached by `LocalDataManager`.

Sections: `churches`, `testimonials`, `ctrim_info`.

Models: `ChurchInfo`, `CtrimInfo`, `TestimonialInfo` in `lib/models/info/`. Shared Quill/image parsing in `info_parsing.dart`.

Pages: `lib/pages/information_home.dart`, `lib/pages/information/`.

Shared UI:
- List shell: `InfoSectionListTab` in `info_tab_widgets.dart` (centered `maxContentWidth` on wide web)
- Detail shell: `InfoDetailLoader` + `InfoDetailPageScaffold` in `info_detail_scaffold.dart` (gutters + constrained Quill column)
- Cards: `InfoHeroOverlayCard`, `InfoTopicListCard`

## Quill

Use `QuillEditorWidget` / `QuillViewerWidget` from `lib/widgets/quill_editor_wrapper.dart`. Harden empty deltas before `Document.fromJson` (via `InfoParsing`).

## Legacy

`assets/info/` JSON — seed/reference only, not primary runtime source.

See [reference.md](reference.md).
