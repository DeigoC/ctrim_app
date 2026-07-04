# Info section reference

## Pages (`lib/pages/information/`)

| Page | Role |
|------|------|
| `information_home.dart` | Shell: nav + tabs; loads futures via `InfoRepository` |
| `information/about_tab.dart` | About tab content |
| `information/churches_tab.dart` | Churches list/grid |
| `information/testimonials_tab.dart` | Testimonials list/grid |
| `information/ctrim_info_list_tab.dart` | CTRIM topics list/grid |
| `information/info_tab_widgets.dart` | Shared cards, empty/error states |
| `church_info_page.dart` | Single church; loads content via repository |
| `ctrim_info_page.dart` | CTRIM org topics |
| `testimonial_info_page.dart` | Testimonial detail |
| `edit_info_body_page.dart` | Debug/admin Quill editing |

## Model fields (typical)

- `_body` — List&lt;dynamic&gt; Quill JSON
- `_imgSrc` — image URL
Models: `ChurchInfo`, `CtrimInfo`, `TestimonialInfo` in `lib/models/info/`.

**Filename note:** `testimonial_into.dart` (typo) — class is `TestimonialInfo`; do not rename without a dedicated refactor.

## Known gaps / TODOs in codebase

- Topic-specific images for CTRIM info cards
- Replace remaining hardcoded image URLs in home tab builders
- Ensure admin edit flows persist through Firestore managers (not clipboard-only)

## Firestore managers

`ChurchInfoDBManager`, `TestimonialInfoDBManager`, `CtrimInfoDBManager` in `info_db_manager.dart`.
