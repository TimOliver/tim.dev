# tim.dev — Personal Blog

Built with [Ignite](https://github.com/twostraws/Ignite), a Swift static site generator with SwiftUI-like syntax.

## Project Structure

```
Sources/
├── Site.swift               # Site config (@main entry point, TimDevSite: Site)
├── Layouts/MainLayout.swift # Page wrapper (nav, content, footer)
└── Pages/                   # StaticPages, article/error templates, shared renderers
    ├── Apps/                #   grid (Apps) · detail (AppDetail) · model (AppModel)
    ├── Art/                 #   Art · ArtDetail · ArtModel
    ├── Code/                #   Code · CodeDetail · CodeModel
    ├── Talks/               #   Talks · TalkDetail · TalkModel
    ├── CollectionRenderer.swift  # Shared collection parsing / media / HTML helpers
    ├── ArticleShell.swift        # Shared article-body renderer (posts + detail pages)
    ├── Home.swift · About.swift · Contact.swift · Archive.swift  # Standalone pages
    ├── PostPage.swift            # ArticlePage template for Markdown blog posts
    ├── InstagramEmbed.swift      # Instagram embed rewriter
    └── NotFound.swift            # Custom 404 (ErrorPage)
Content/                     # Markdown articles (YAML front matter)
Assets/                      # Static files (images, fonts) — copied to Build/
Includes/                    # Raw HTML snippets, loaded via Include("file.html")
Build/                       # Generated output (deploy this)
Template/                    # Previous hand-coded HTML/CSS design (reference)
Package.swift                # Swift package — depends on Ignite (main branch)
```

## Ignite Framework Reference

### Core Protocols
- **`Site`** — Top-level config: `name`, `url`, `homePage`, `layout`, plus optional `author`, `titleSuffix`, `lightTheme`/`darkTheme`, `feedConfiguration`, `favicon`, `builtInIconsEnabled`, etc.
- **`StaticPage`** — Swift-defined page: requires `title: String` and `var body: some HTML`. Optional `path`, `description`, `image`.
- **`Layout`** — Page wrapper: `var body: some Document`. Use `content` to place page body. Wraps all pages.
- **`ArticlePage`** — Template for Markdown articles. Access `article` property for metadata/content.
- **`TagPage`** — Template for tag archive pages. Access `tag` property.
- **`ErrorPage`** — Custom 404 page.
- **`Theme`** — Full visual theming: colors (`accent`, `primary`, `background`, `link`, etc.), typography (`font`, `headingFont`, `rootFontSize`), responsive sizing.

### Key Elements
| Category | Elements |
|----------|----------|
| Text | `Text`, `Span`, `Strong`, `Emphasis`, `Code`, `CodeBlock`, `Quote`, `Strikethrough`, `Underline` |
| Structure | `Section`, `Group`, `Body`, `Head` |
| Layout | `HStack`, `VStack`, `ZStack`, `Grid`, `Column`, `Row`, `Spacer` |
| Navigation | `NavigationBar`, `Link`, `LinkGroup`, `Dropdown` |
| Media | `Image`, `Video`, `Audio`, `Embed` |
| Interactive | `Button`, `ButtonGroup`, `Modal`, `Accordion`, `Carousel` |
| Forms | `Form`, `Input`, `TextField`, `Label`, `SubscribeForm` |
| Content | `Card`, `Badge`, `Alert`, `Divider`, `Table`, `ArticlePreview` |
| Meta | `MetaTag`, `MetaLink`, `MetaStyle`, `Script`, `Include` |
| Utility | `ForEach`, `Tag`, `String` (raw HTML) |

### Common Modifiers
- **Typography:** `.font(.title1)`, `.fontWeight(.bold)`, `.lineSpacing()`, `.letterSpacing()`
- **Color:** `.foregroundStyle(Color)`, `.background(Color)`, `.opacity(Double)`
- **Spacing:** `.padding()`, `.padding(.top, 5)`, `.margin()`
- **Size:** `.frame(width:height:)`, `.aspectRatio()`
- **Visual:** `.border()`, `.cornerRadius()`, `.shadow()`, `.clipped()`
- **Custom:** `.id()`, `.class()`, `.style()`, `.data()`, `.aria()`, `.customAttribute()`
- **Interaction:** `.onClick {}`, `.onHover {}`, `.cursor(.pointer)`
- **Visibility:** `.hidden()`, `.disabled()`

### Content System (Markdown Articles)
Place `.md` files in `Content/` subfolders. Front matter:
```yaml
---
title: Post Title
date: 2024-02-24
tags: swift,web
author: Name
published: true
image: /images/hero.jpg
layout: CustomArticlePage
---
```
Article properties: `title`, `description`, `text`, `date`, `lastModified`, `tags`, `path`, `estimatedReadingMinutes`, `image`, `isPublished`.

### Collection Media

Collection items (apps, code, art, talks) reference real images by site path in
front matter. Files live under `Assets/img/<collection>/<slug>/`.

| Collection | Keys |
|---|---|
| Apps | `icon:` (one path), `shots:` (comma-separated paths) |
| Code | `image:` |
| Talks | `image:` (poster; the video itself comes from `youtube:`) |
| Art | `image:` (poster) |

**Adding an image:**
1. Drop the file in `Assets/img/<collection>/<slug>/`.
2. Run `python3 Scripts/strip-exif.py Assets/img/<collection>/<slug>/*` (GPS
   leaks otherwise). With no arguments the script only walks
   `Assets/img/posts/` — pass the path explicitly for anything else. Staged
   images get this for free at commit time too: the pre-commit hook runs the
   same script over staged paths under `Assets/` and re-stages the result.
3. Run `python3 Scripts/build-media.py` — generates responsive `@<width>w`
   variants and rewrites `media-manifest.json` at the repo root.
4. Reference it in front matter.

`media-manifest.json` is a build input and deliberately lives outside `Assets/`
(everything under `Assets/` is copied verbatim into `Build/`). Swift reads it
via `Media.manifest`. Every call site into `Media.image`/`Media.box` threads
its own `sizes` attribute — an app icon, an app screenshot, a grid thumbnail,
and a detail hero each occupy a different fraction of the viewport, so each
call site's `sizes` is tailored to where it renders, not a single shared
default. An image referenced in front matter but missing from the manifest
**fails the build** (a `fatalError`, not a warning) rather than shipping a
silent hole in the page.

Images render through the LQIP system: a base64 blur in `src`, real candidates
in `data-srcset`, swapped in by `Assets/js/site.js` when the image nears the
viewport, with a `<noscript>` sibling for JS-less visitors.

**App screenshots carry their device chrome baked into the PNG** (so each can
be tailored per device). They are therefore rendered bare — `.app-shot` must
never get a `border-radius`, `background`, or `overflow: hidden`, or CSS
clipping eats the bezel's own corners. This is the single most important
non-obvious constraint for anyone adding images to Apps later.

A media slot with no image yet renders a flat `.is-empty` surface — no
gradient, no fake device shape.

### Environment
```swift
@Environment(\.articles) var articles  // ArticleLoader — .all, .tagged("swift")
@Environment(\.site) var site          // SiteMetadata — .name, .url
@Environment(\.themes) var themes
@Environment(\.author) var author
```

### Assets & Images
- Files in `Assets/` are copied to `Build/` automatically.
- Dark mode image variants: `logo~dark.svg` alongside `logo.svg`.
- Retina: `icon@2x.png` alongside `icon.png`.
- Bootstrap icons: `Image(systemName: "heart-fill")` (requires `builtInIconsEnabled`).

### Custom CSS/HTML
- **Inline style:** `MetaStyle(content: "css here")` in `Head`
- **External stylesheet:** `MetaLink(relationship: .stylesheet, href: "/css/custom.css")`
- **HTML snippet:** `Include("file.html")` — loads from `Includes/`
- **Raw HTML:** `String("<div>raw</div>")`

### Theming
- Set `lightTheme` / `darkTheme` on `Site` for automatic light/dark mode.
- `SwitchTheme(themeName:)` action for manual theme switching.
- Colors: `Color(hex:)`, `Color.blue`, `.opacity()`, `.weighted(.lighter/.darker)`.
- Units: `.px()`, `.rem()`, `.em()`, `.percentage()`.

### Build & Deploy
- Run the executable to build: output goes to `Build/`.
- `Build/` contains static HTML/CSS/JS ready for any web server.
- RSS feed at `feed.xml` if `feedConfiguration` is set.
- `robots.txt` and `sitemap.xml` auto-generated.

## Design Mockup (Template/)
`Template/index.html` is a single-file hand-coded mockup that's the source of truth for visual + interaction decisions. See `Template/CLAUDE.md` for detailed patterns and decisions, including:
- Theme system (light/dark/auto, FOUC prevention, opaque popover requirement)
- Sticky capsule header with backdrop-filter
- Hamburger menu (WAAPI-driven, change-event pattern, animation defenses)
- Footer structure and link styling
- Lazy image system (LQIP + responsive variants + lightbox target)
- Lightbox3 integration for full-screen image viewing
- YouTube embeds via lite-youtube-embed facade
- iOS/safe-area concerns and breakpoint table

When porting to Ignite components/plugins, preserve behavior verbatim — many decisions there came from iteration and have non-obvious reasons.
