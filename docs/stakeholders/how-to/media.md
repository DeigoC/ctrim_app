# Using images, GIFs, and video

How to attach media to stakeholder / how-to pages in this MkDocs site.

## Where files go

Put media under `docs/stakeholders/assets/` (this folder is published with the site):

```text
docs/stakeholders/assets/
  images/     screenshots
  gifs/       short looping demos
  video/      short .mp4 clips (prefer small files)
```

Name files clearly, e.g. `create-post-step-1-templates.png`.

## Images and GIFs

From a how-to page (e.g. `how-to/posts/create-a-post.md`), use a path relative to that page. Because MkDocs builds pages into subfolders, go up to `assets` with `../../assets/...`:

```markdown
![Choose a template](../../assets/images/create-post-step-1-templates.png)
```

GIF:

```markdown
![Opening Post Templates](../../assets/gifs/open-post-templates.gif)
```

With a caption (HTML figure):

```markdown
<figure markdown="span">
  ![Choose a template](../../assets/images/create-post-step-1-templates.png)
  <figcaption>Step 1 — pick a template from the list</figcaption>
</figure>
```

Optional size / lazy-load attributes:

```markdown
![Choose a template](../../assets/images/create-post-step-1-templates.png){ width="720" loading=lazy }
```

## Local video (MP4)

Use an HTML5 player (`md_in_html` is enabled). From a how-to under `how-to/posts/`:

```html
<video controls width="720" preload="metadata">
  <source src="../../assets/video/create-post-overview.mp4" type="video/mp4">
  Sorry, your browser doesn’t play embedded video.
</video>
```

!!! warning "File size"
    Prefer short clips or GIFs for demos. Large videos slow GitHub Pages and local previews; host long recordings on YouTube/Vimeo instead.

## Hosted video (YouTube / Vimeo)

Embed with an iframe:

```html
<iframe
  width="720"
  height="405"
  src="https://www.youtube.com/embed/VIDEO_ID"
  title="Create a post"
  frameborder="0"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
  allowfullscreen
></iframe>
```

## Subsections in the site

Nested guides already appear under **How-to** in the left nav (`mkdocs.yml`). To add another:

1. Create `how-to/<topic>/<page>.md`
2. Add it under the matching section in `mkdocs.yml` → `nav`
3. Link it from [How-to guides](index.md)
4. Update the Documents table in `README.md`
