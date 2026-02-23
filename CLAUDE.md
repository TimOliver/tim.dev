# tim.dev — Personal Blog

Built with [Ignite](https://github.com/twostraws/Ignite), a Swift static site generator with SwiftUI-like syntax.

## Project Structure

```
Sources/
├── Site.swift              # Site config (@main entry point, ExampleSite: Site)
├── Layouts/MainLayout.swift # Page wrapper (nav, content, footer)
└── Pages/Home.swift         # Homepage (StaticPage)
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

## Previous Design (Template/)
The hand-coded `Template/index.html` contains the original blog design with:
- Custom dark mode popover (Auto/Light/Dark) using CSS custom properties and minimal JS
- SVG icons with `filter: var(--icon-filter)` for dark mode inversion
- Touch-friendly popover with hover zone bridging
- localStorage-based theme persistence with FOUC prevention
- Icon inventory in `Template/img/appearance/` (auto.svg, sun.svg, moon.svg)

This design should be ported to Ignite's component system.
