# Info section reference

## Pages (`lib/pages/information/`)

| Page | Role |
|------|------|
| `information_home.dart` | Shell: nav + tabs; loads futures via `InfoRepository` |
| `information/about_tab.dart` | About tab content (still has hardcoded Drive image URLs) |
| `information/churches_tab.dart` | Thin wrapper around `InfoSectionListTab` |
| `information/testimonials_tab.dart` | Thin wrapper around `InfoSectionListTab` |
| `information/ctrim_info_list_tab.dart` | Thin wrapper; hero cards when image present on wide |
| `information/info_tab_widgets.dart` | Shared list shell, cards, empty/error states |
| `information/info_detail_scaffold.dart` | Shared detail loader + layout |
| `church_info_page.dart` / `testimonial_info_page.dart` / `ctrim_info_page.dart` | Detail pages via `InfoDetailLoader` |
| `edit_info_body_page.dart` | Area admin / leader Quill + metadata edit/delete (`User.canManageInfo`) |

## Models (`lib/models/info/`)

- `church_info.dart`, `ctrim_info.dart`, `testimonial_info.dart`
- Shared parsing: `info_parsing.dart` (`parseBody`, `parseImageSources`, `parseUpdatedAt`, `parseDisplayOrder`)
- Typical fields: Quill `_body`, `imageSources` (legacy `imgSrc` fallback), `displayOrder`, `updatedAt`/`updatedBy`
- Church/Testimonial: `summary`; CTRIM: `description`; Church/CTRIM: `analyticsTitle`

## Wide / web layout DNA

- List tabs: center content with `ResponsiveLayout.maxContentWidth`, 16px gutters on narrow
- Detail: `ResponsiveLayout.horizontalGutter` + Quill column capped at `chordMaxWidth`
- Carousel (`InfoImageCarousel`) probes image bytes via `CachedImageLoader` + `ImageOrientationHelper` and switches:
  - landscape → full-width cover banner
  - portrait → centered contained frame (better for people photos)
- Gallery tiles use `AdaptiveInfoGalleryImage` with the same probe

## Known gaps / TODOs

- Replace hardcoded Drive image URLs in `about_tab.dart` with Firestore-backed content

## Firestore managers

`ChurchInfoDBManager`, `TestimonialInfoDBManager`, `CtrimInfoDBManager` in `info_db_manager.dart`.
Deletes must also clear the Hive entry via `LocalDataManager.delete*InfoData` and sync `lastUpdate`.
