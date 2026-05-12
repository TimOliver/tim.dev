# Template/ — Design Mockup Notes

This folder is a single-file (`index.html`) hand-coded mockup that establishes the design language for `tim.dev`. It's the source of truth for visual + interaction decisions that need to be ported to Ignite components/plugins.

The mockup is intentionally monolithic — all CSS and JS lives inline so the whole site can be reasoned about in one place. When porting, prefer to **preserve behavior verbatim** rather than "improve" it; many decisions below came from iteration and have non-obvious reasons.

---

## Theme System

Three states: `auto` (follows OS), `light`, `dark`. Stored in `localStorage` under key `theme`.

- **Selector pattern**: `[data-theme="dark"]` + `[data-theme="auto"]` inside a `prefers-color-scheme: dark` media query both apply the dark variable set. The `data-theme` attribute is set on `<html>`.
- **FOUC prevention**: an inline `<script>` in `<head>` reads `localStorage` and sets `data-theme` *before* paint. Don't move this to a deferred script.
- **Light-mode icon swap**: the moon icon in the header automatically replaces with `sun-bold.svg` (stroke-width 2.5) when the effective theme is light. Driven by CSS class selectors keyed off `[data-theme]`, no JS.
- **Popover background must be opaque** (`var(--bg-secondary)`), not translucent. Stacking `backdrop-filter: blur` on the popover *and* the capsule header underneath looked bad on iOS.
- **Theme popover position**: right-aligned only when viewport ≤ 1049.98px or horizontal safe-area insets are non-zero (Dynamic Island landscape). Centered otherwise. Don't right-align always — looks weird on desktop.

### Color palette
iOS UIColor-aligned semantic variables. When porting, define both light and dark sets:
- `--bg`, `--bg-secondary`, `--bg-tertiary` (translucent overlay)
- `--text`, `--text-secondary` (60% alpha), `--text-tertiary` (30%)
- `--heading`
- `--link` / `--link-hover` — currently Apple Music red (`#FA233B` light, `#F82D48` dark), but the body text isn't styled with link colors — link styling is only used on certain UI elements (footer links use `--text` directly).
- `--capsule-bg` (translucent for backdrop-filter), `--capsule-border`

---

## Sticky Capsule Header

A floating "capsule" — sticky, backdrop-blurred, centered, with a max-width.

- **Backdrop-filter**: `blur(20px) saturate(180%)` over a translucent background. Required for the iOS-feel.
- **Sticky positioning** with a `::before` pseudo-element that fades out the underlying page content below it (mask gradient). Without this, content shows through the blur sharply at the bottom edge of the header.
- **`box-sizing: border-box`** on the header is essential — without it, the right side overflows the viewport at narrow widths.
- **Nav needs `min-width: 0`** to allow proper flexbox shrinking, otherwise content forces overflow.

### Responsive scaling
Below 941px the entire header content scales (font-sizes shrink, gap clamps tighten). This is preferable to reflowing or wrapping the menu.

---

## Hamburger Menu

Below 720px the menu collapses to a "closed bar" with just About + Archive + the hamburger toggle, expanding into a full menu when tapped.

### Critical architectural decisions

- **Separate `<div class="menu-closed-bar">`** sibling of the menu `<ul>` — NOT a reused `<li>` inside the menu. This solves the "pop-in" problem where reused items would flash at the end of close animation.
- **Hidden checkbox toggle** (`<input type="checkbox" id="menu-toggle">`) flipped by a `<label>` click. Use `clip: rect(0,0,0,0)` to hide it, not `pointer-events: none` — iOS doesn't reliably honor pointer-events on hidden inputs.
- **`change` event, not `click`**: programmatic `checked = X` doesn't fire `change`, which lets the JS use a temp-toggle pattern to measure both heights in one handler.
- **All button visuals driven by WAAPI**, not CSS transitions. The icon swap (hamburger ↔ X), label background, capsule height — every animation runs via `Element.animate()`. CSS transitions on these elements were removed because they fired a second time at the end of the WAAPI close animation.
- **iOS easing curve**: `cubic-bezier(0.32, 0.72, 0, 1)` for all menu animations. Keep this.

### Animation defense
Three layers, all needed:
1. `animating` flag set on each animation start
2. `label.style.pointerEvents = 'none'` during animation
3. State-revert fallback inside the `change` handler — if rapid clicks slip through, `checkbox.checked = !checkbox.checked` undoes the desync

Don't remove any of these. They each catch a different race condition.

### Layout
- 2-column grid (via CSS Grid, NOT flex-wrap) for the menu items when expanded on iPod-touch landscape (~360px max-height). Flex-wrap with percentage widths doesn't reliably size in a flex column.
- Closed-bar uses `position: absolute` with `clamp()`-based right offset that scales with viewport.

---

## Footer

Two-column layout (left: text, right: social icons), stacking to column-reverse below 519.98px.

- **Left**: `By [Tim Oliver] • Built with [Ignite] ([305ca60]).` — three links: name → about (TBD), commit hash → GitHub commit URL, Ignite → upstream repo.
- **Right**: social icon row using brand SVGs with `filter: var(--icon-filter)` for dark mode inversion.
- **Link styling**: links use `color: var(--text)` + `font-weight: 600` + underline on hover. No `<strong>` tags — the weight is on the `<a>` directly.

---

## Lazy Image System (LQIP + responsive variants)

Every blog image should ship with:
- A tiny inline base64 placeholder (LQIP) for instant render
- Two responsive variants (~700px and ~1400px wide) for actual display, picked by the browser via `srcset` + `sizes` based on viewport + DPR
- The original full-resolution file as the Lightbox3 target (loads only on click)

### Markup pattern
```html
<a href="image-full.webp" data-lightbox>
    <img class="lqip"
         style="aspect-ratio: W / H;"
         src="data:image/png;base64,..."
         data-srcset="image-700.png 700w, image-1400.png 1400w"
         data-sizes="(max-width: 720px) 100vw, 700px"
         width="W" height="H"
         alt="">
</a>
<noscript>
    <a href="image-full.webp">
        <img srcset="image-700.png 700w, image-1400.png 1400w"
             sizes="(max-width: 720px) 100vw, 700px"
             src="image-700.png"
             width="W" height="H" alt="">
    </a>
</noscript>
```

### Why each piece matters
- **Inline base64 PNG** (32px wide, ~1-2 KB) as initial `src`. PNG preserves alpha. Could be WebP if `cwebp` is available at build time (macOS ImageIO can't write WebP natively as of Sequoia).
- **`aspect-ratio` inline style** is required to prevent layout pop. Without `auto` qualifier, this CSS rule overrides the browser's preference for using the loaded image's natural dimensions — so the 32×N placeholder's slightly-different aspect ratio doesn't cause reflow when the real image swaps in.
- **`width`/`height` HTML attrs** mirror the real image's dimensions (not the placeholder's).
- **`data-srcset` + `data-sizes`** hold the responsive variant candidates and the size hint. Runtime JS hands these over to the browser by setting `srcset` + `sizes` directly; from there the browser handles candidate selection, fetching, and the visible swap.
- **`<noscript>` fallback**: full markup loads when JS is disabled, including its own native `srcset` so JS-disabled users still get responsive serving. The `<html class="no-js">` + head-script-removes-it pattern (combined with `.no-js article img.lqip { display: none; }`) ensures non-JS users see only the real image, not both.
- **Lightbox `href`** always points to the original (full-resolution) asset, not a variant. Click-to-zoom should reveal more detail than what was displayed inline.

### Runtime flow
1. Page renders with LQIP visible (inline base64). No real image has been requested yet.
2. IntersectionObserver (rootMargin: 200px) watches each `img.lqip`.
3. On intersection:
    - Build a detached `new Image()` probe with the same `srcset`/`sizes` to test the cache.
    - If `probe.complete && probe.naturalWidth > 0` synchronously, the chosen variant is in cache → set `srcset`/`sizes` on the visible img, no animation.
    - Otherwise: add `.loading` class (CSS applies `filter: blur(8px)`), attach a one-shot `load` listener that removes `.loading` (CSS transitions blur → 0 over 400ms), then set `srcset`/`sizes`. The browser fetches the chosen variant; once loaded, `load` fires and the blur fades out.

### Build-time work (Ignite side)
For each image referenced in markdown:
1. Read the source image, capture width × height.
2. **LQIP**: downscale to 32px wide → encode as PNG (preserves alpha) → base64.
3. **Variants**: downscale to ~700px and ~1400px wide using `CGContext` / `NSImage`. Output as WebP (if `cwebp` available) or PNG (preserves alpha) or JPEG (smaller, no alpha — fine for photos).
4. **Original**: copy verbatim to `Build/`. This is the lightbox target.
5. Emit the markup above. The `sizes` value should match the article content width (currently `(max-width: 720px) 100vw, 700px`).

Use a custom `LazyImage(...)` Ignite view that wraps this. Don't try to retrofit `Image(...)` — the markup difference is substantial. Consider caching variant generation by source hash so rebuilds don't redo unchanged images.

### Skip-variants short-circuit
If the source image is narrower than ~1400px, skip generating the 1400 variant. If it's narrower than ~700px, skip both variants and just inline the original as the lone candidate (or omit `srcset` entirely). The LQIP + lightbox pieces still apply.

### Format pragma
The mockup currently uses PNG variants because macOS ImageIO can't write WebP. In production, prefer WebP for ~70% smaller files. Install via `brew install webp` and shell out to `cwebp -q 75 -m 6 <in> -o <out>` from the Ignite build, or use a Swift WebP encoder package if one becomes available.

### Sizing constraints
`article img` is capped at `max-height: 650px` to prevent tall portrait images from dominating the layout. Combined with the inline `aspect-ratio` and `max-width: 100%`, the browser proportionally narrows the width when height clamps. Centered horizontally via `margin: 0 auto 1.75em` — block-level images with auto side margins center within the section even when wrapped by an inline lightbox anchor (the anchor doesn't establish a containing block for the block img). Landscape images at full width are unaffected; only height-clamped images visibly shift to center.

On iPhone-class landscape viewports (`@media (orientation: landscape) and (max-height: 500px)`), the cap tightens to 320px so media doesn't dominate the short viewport:
- Images: `max-height: 320px` (works directly with aspect-ratio).
- `lite-youtube`: `max-width: calc(320px * 16 / 9)` (~569px). The library enforces 16:9 via `padding-bottom` on a `::after` pseudo, which doesn't respect `max-height` — so we cap *width* such that 16:9 gives a 320px height. Update this if the library ever switches to native `aspect-ratio`.

### ThumbHash was considered and rejected
We initially used [evanw/thumbhash](https://github.com/evanw/thumbhash) (procedural ~30-byte hashes). The Swift port exists and is buildable, but:
- Decoded placeholders are colored blobs, not recognizable miniatures of the image — looks like a glitch on stylized/transparent content.
- Required ~150 lines of JS decoder + PNG encoder runtime.
- Blur filter transitions had visual artifacts on transparent images.

LQIP is bigger inline (~1-2 KB vs ~30 bytes per image) but renders as a tiny version of the actual image and needs zero runtime decoder. For a blog with ~10 images per post that's still negligible.

If you ever want to revisit ThumbHash, the Swift API is `imageToThumbHash(image: NSImage) -> Data` and `/tmp/lqip-webp.swift` (one-off generator script from the mockup session) has working scaffolding.

---

## Lightbox3 Integration

Clicking any blog image opens [Lightbox3](https://github.com/lokesh/lightbox3) for full-screen viewing with spring-physics zoom.

- **Zero-dependency** (no jQuery), zero-config — auto-binds to any `<a data-lightbox>` it finds.
- Loaded from jsdelivr CDN: `lightbox3@1.1.0/dist/lightbox3.css` + `dist/lightbox3.umd.js`.
- For self-hosting later, copy both files to `Assets/` and update the URLs.
- The `<a href="real.webp" data-lightbox>` wraps the LQIP `<img>`. Both the lazy load and the lightbox bindings work on the same element without conflict.

---

## Social Embeds (X / Bluesky / Mastodon)

All three platforms use a **unified custom-card facade** — no third-party widget JS, no iframes. Base pattern lifted from [alexwlchan.net/2025/good-embedded-toots/](https://alexwlchan.net/2025/good-embedded-toots/), extended to all three platforms via a `data-platform="..."` attribute. Dark mode adapts automatically through the site's existing CSS variables.

### Why the same pattern for all three
- ✅ Zero runtime JS for embeds (drop ~200 KB of widget scripts).
- ✅ Dark mode Just Works — no per-widget theme attribute juggling, no iframe filter hacks, no re-mount on toggle.
- ✅ Identical visual rhythm across platforms; same border, same padding, same typography.
- ❌ Like/reply counts are frozen at build time (not live).
- ❌ Embedded media (polls, multi-image grids, quote-of-quote) need bespoke rendering — currently only images are supported.

### Unified markup pattern

```html
<blockquote class="embed_social" data-platform="<mastodon|bluesky|twitter>">
    <div class="header">
        <a class="name_header" href="<profile-url>">
            <img class="avatar" src="<avatar-url>" alt="" width="46" height="46">
            <div class="name">
                <span class="display_name">Display Name</span>
                <span class="account_name">@handle</span>
            </div>
        </a>
        <svg class="embed_logo" viewBox="..." aria-hidden="true" width="40">
            <title>Mastodon|Bluesky|X</title>
            <path d="..." fill="currentColor"/>
        </svg>
    </div>
    <p class="text">Post body. Use `<br><br>` for paragraph breaks; inline `<a>` for hashtags/mentions/URLs.</p>
    <div class="media">
        <a href="<full-resolution-url>" data-lightbox>
            <img src="<preview-url>" alt="<description>" loading="lazy">
        </a>
    </div>
    <p class="meta">
        <a href="<post-url>"><time datetime="<iso-8601>">DD MMM YYYY at HH:MM</time></a>
    </p>
</blockquote>
```

`data-platform` controls:
- **Link accent color** (`--accent`) — Mastodon purple, Bluesky blue, Twitter blue.
- **Avatar shape** — Twitter + Bluesky are circular (`border-radius: 50%`); Mastodon uses an 8px rounded square (matches the Mastodon app).
- **Brand SVG** picked per-platform in the markup (logo paths live inline so they get `fill: currentColor`). Mastodon's logo inherits `--text-secondary`; Twitter and Bluesky override to their brand blue.

### Per-platform palettes (Twitter + Bluesky)
Twitter and Bluesky both opt out of the site's theme variables for surface colors — they override `background`, `border-color`, text, and secondary text via a per-platform set of custom properties, so the embeds always look unmistakably "Twitter" or "Bluesky" regardless of host site theme.

**Twitter (`--tw-*`)** — pre-rebrand identity. Light = "default" theme, dark = "Dim".
- Light: `#F5F8FA` bg, `#E1E8ED` border, `#14171A` text, `#657786` handle/meta
- Dark: `#15202B` bg, `#38444D` border, `#FFFFFF` text, `#8899A6` handle/meta
- Bird logo: `#1DA1F2` (classic Twitter blue) in both modes.

**Bluesky (`--bs-*`)** — the Bluesky web app palette.
- Light: `#FFFFFF` bg, `#D4DBE2` border, `#0B0F19` text, `#42576C` handle/meta
- Dark: `#161E27` bg, `#2E3641` border, `#FFFFFF` text, `#8D9AAA` handle/meta
- Butterfly logo + link accent: `#0085FF` light, `#208BFE` dark (slightly brighter for contrast).

We deliberately use the OG Twitter identity (bird logo, classic blue) rather than the 2023 X rebrand. This is an opinionated styling choice baked into the platform, not configurable per-post. If you want to honor the X rebrand on individual posts, override `data-platform="x"` with the X glyph and a black/white palette.

Mastodon stays on the site's theme variables (`--bg-secondary`, `--border`, `--text`, `--text-secondary`) — its visual identity is the purple `--accent` + the Mastodon logo, not the surface color.

The `.media` grid uses 2 columns by default, collapsing to 1 column via `:has(> a:only-child)` when there's a single attachment. Clicking opens the original-resolution image via Lightbox3. Drop `<div class="media">` entirely for text-only posts.

### Styling
Width caps at 508px (matches Mastodon's official embed minus padding). CSS Grid handles the header layout. Per-platform link accent flows through a single `--accent` custom property set on the blockquote based on `data-platform`, with light/dark variants for Mastodon and Bluesky. The brand SVG inside `.embed_logo` inherits `currentColor: var(--text-secondary)`. No `!important` overrides — we control all the markup.

The generic article `blockquote::before` rule (which draws a 5px gray left bar for pull-quotes) is explicitly suppressed on `.embed_social` via `content: none;` — otherwise it leaked into the embed cards and made them look like double-quoted content. Pull-quote blockquotes elsewhere on the page keep their bar.

### Per-platform fetching

**Mastodon — public per-instance API**
```
GET https://<instance>/api/v1/statuses/<status-id>
```
- `content` (HTML) → `.text`. Convert `<p>...</p><p>...</p>` to `...<br><br>...`; strip `<span class="invisible">` URL display tricks.
- `account.{display_name, acct, avatar, url}` → header (prepend `@` to `acct`, append `@<instance>`).
- `url` + `created_at` → `.meta`.
- `media_attachments[].{preview_url, url, description}` → `.media` (Lightbox3 anchor wrapping each).

**Bluesky — public AT Proto API (no auth)**
```
GET https://public.api.bsky.app/xrpc/app.bsky.feed.getPostThread?uri=at://<did>/app.bsky.feed.post/<rkey>&depth=0
```
- Resolve handle → DID via `com.atproto.identity.resolveHandle?handle=<handle>` if you only have the friendly URL.
- `thread.post.author.{handle, displayName, avatar}` → header.
- `thread.post.record.text` → `.text` (plain text; if you want clickable mentions/hashtags, walk `thread.post.record.facets` and slice the text into runs).
- `thread.post.record.createdAt` → `<time datetime>`.
- `thread.post.embed.images[].{thumb, fullsize, alt}` → `.media`.

**X / Twitter — no free API**
The public oEmbed endpoint returns 401 unauthenticated; the paid API is overkill for a blog. Practical paths:
1. **Manual paste** of all fields (post text, handle, display name, avatar URL, date) into the markup. Fine for occasional embeds.
2. **Local archive** — if you have a Twitter Archive download, the plugin can read post data from there.
3. **Scraper** — fragile, against ToS.

### Caching
Mirror avatars + media locally at build time. Store under `Assets/social-cache/<post-hash>/` so embeds survive the original CDN going away. The mockup currently references CDN URLs directly for convenience — production should swap to local paths.

### Ignite plugin sketch
Three views, one shared output template:
- `MastodonPost("POST_URL")` — hit `<instance>/api/v1/statuses/<id>` at build time, transform, emit `.embed_social[data-platform="mastodon"]`.
- `BlueskyPost("POST_URL")` — resolve handle → DID, hit `getPostThread`, emit `.embed_social[data-platform="bluesky"]`.
- `Tweet(handle:displayName:avatarPath:text:statusURL:date:)` — fields-in API since there's no public fetch path. Emit `.embed_social[data-platform="twitter"]`.

No runtime widget scripts needed; embed loaders should be removed from the layout entirely.

---

## YouTube Embeds (lite-youtube-embed)

YouTube's native `<iframe>` ships ~1 MB+ of JS just to render the player chrome — bad for Lighthouse on pages where the video isn't always played. We use the **facade pattern** via Paul Irish's [`lite-youtube-embed`](https://github.com/paulirish/lite-youtube-embed) (~3 KB): render a thumbnail + play button, swap in the real iframe only on click.

### Markup pattern
```html
<lite-youtube videoid="VIDEO_ID" params="modestbranding=1&rel=0"></lite-youtube>
<noscript>
    <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/VIDEO_ID?modestbranding=1&rel=0" title="YouTube video" frameborder="0" allowfullscreen></iframe>
</noscript>
```

- **`videoid`** is the only required attribute — the YouTube video ID (11 chars).
- **`params`** are URL-encoded querystring params passed to the embed iframe on click. Use `modestbranding=1&rel=0` to suppress related videos and minimize YouTube branding.
- **Thumbnail fetched at runtime** from `i.ytimg.com/vi/<id>/hqdefault.jpg` by the library. No build-time fetch required.
- **Uses `youtube-nocookie.com`** domain by default — privacy-respecting (no tracking until play).
- **`<noscript>` fallback** loads a regular iframe directly so JS-disabled users still see the video. Same privacy domain.

### CSS overrides (applied in the template)
```css
article lite-youtube {
    border-radius: 15px;
    overflow: hidden;
    margin: 0 auto 1.75em;
}
```

The library's defaults handle aspect ratio (16:9 via padding-bottom trick), maximum width (720px), and the play-button overlay. We just round the corners and match the article spacing.

### Build-time work (Ignite side)
A simple `YouTube("VIDEO_ID", params: "modestbranding=1&rel=0")` view that emits the `<lite-youtube>` element + the `<noscript>` fallback. No asset generation needed — thumbnails come from YouTube's CDN at runtime.

For self-hosting later, copy `lite-yt-embed.css` and `lite-yt-embed.js` to `Assets/` and update the CDN URLs. The library file sizes are tiny (~3 KB combined), so this is mostly about avoiding the third-party request.

---

## Third-party Dependencies

All loaded from `cdn.jsdelivr.net` or platform-specific CDNs. Pin exact versions; for self-hosting later, copy the files into `Assets/` and update URLs.

| Purpose | Files | Notes |
|---------|-------|-------|
| Lightbox3 image viewer | `lightbox3@1.1.0/dist/lightbox3.css` + `dist/lightbox3.umd.js` | Zero-dep. Auto-binds to `<a data-lightbox>`. |
| YouTube facade | `lite-youtube-embed@0.3.4/src/lite-yt-embed.css` + `src/lite-yt-embed.js` | ~3 KB. Web component (`<lite-youtube>`). |
| Social embed assets (per-post) | platform CDNs (`files.mastodon.social`, `cdn.bsky.app`, etc.) | Avatars + media images only. Social embeds are all custom CSS facades — no runtime widget JS. Cache locally at build time. |

Total weight when all loaded: ~10-30 KB transferred (Lightbox3 + lite-youtube-embed). When porting to Ignite, layout views should conditionally inject only the loaders that this page actually needs.

---

## iOS / Safe-Area Concerns

- **Viewport meta**: `viewport-fit=cover` is required to extend the background under the notch/island. Combined with `padding: env(safe-area-inset-*)` on `<body>` to inset content from the unsafe regions.
- **Don't try to conditionally cancel safe-area-inset in landscape**. We explored detecting notched-device via `@media (max-height: calc(env(safe-area-inset-top) * 1000))` — broke other Safari behaviors. Live with the inset.
- **Text size adjust**: `-webkit-text-size-adjust: 100%` + `text-size-adjust: 100%` on body to prevent iOS Safari from inflating text on rotation.
- **Touch testing**: iOS Simulator requires a local HTTP server (e.g., `python3 -m http.server 8001`). `file://` URLs don't trigger many touch behaviors correctly.

---

## Breakpoints

The mockup uses these breakpoint boundaries (not all are arbitrary — the .98 suffixes match the smallest layout-affecting widths just below a round number):

| Width | Trigger |
|-------|---------|
| 1049.98px | Theme popover right-aligns |
| 1000px | (reserved for content max-width) |
| 941px | Header content starts scaling |
| 720px | Hamburger menu activates |
| 519.98px | Footer stacks vertically |
| 389px | Hamburger menu uses 2-column grid (iPod touch landscape) |
| 374.98px | Outer padding shrinks 16px → 8px, body font scales to 85% |
| `orientation: landscape` + `max-height: 500px` | Images/YouTube embeds capped at 320px height (iPhone-class landscape) |

---

## When porting to Ignite

### Components / layouts
- **`CapsuleHeader` layout**: the sticky backdrop-blurred header with the menu/logo/theme/social icons. Includes the `::before` mask gradient for fade-out below the capsule.
- **`HamburgerMenu` component**: encapsulates the WAAPI animation logic + checkbox toggle. The JS is verbose enough to belong in a separate `Includes/hamburger.js` rather than re-emitted inline per page.
- **`ThemeToggle` component**: the popover with auto/light/dark options. Pair with a head-script `Include` for FOUC prevention. Don't forget the right-align media queries for narrow + notched-landscape viewports.
- **`Footer` component**: two-column responsive footer with the byline + GitHub + Ignite + commit links on the left and social icons on the right.

### Content views (Markdown extensions)
- **`LazyImage`**: build-time LQIP generation + 700/1400 variant generation + lightbox-anchor wrapping. Emits the full `<a>` + `<img class="lqip">` + `<noscript>` triple. Reads source dimensions; caches variants by source hash.
- **`YouTube("VIDEO_ID")`**: emits `<lite-youtube>` + `<noscript>` iframe.
- **`Tweet(handle:displayName:avatarPath:text:statusURL:date:)`**: fields-in markup (no free API). Emits `.embed_social[data-platform="twitter"]`.
- **`BlueskyPost("POST_URL")`**: at build time, resolves handle → DID, hits `getPostThread`, caches avatar + media locally, emits `.embed_social[data-platform="bluesky"]`.
- **`MastodonPost("POST_URL")`**: at build time, hits `<instance>/api/v1/statuses/<status-id>`, caches avatar + media locally, converts `<p>` paragraphs to `<br><br>`-separated text, emits `.embed_social[data-platform="mastodon"]`. All three are pure HTML/CSS — no runtime widget needed.

### Asset pipeline plugin
A single build-time pass that:
1. Walks Markdown for `LazyImage` references.
2. For each unique source, generates LQIP base64 + 700/1400 variants (with the skip-short-circuit). Caches by source content hash.
3. Copies the originals to `Build/` for the lightbox target.
4. Pre-fetches Bluesky/Mastodon oembed responses and stashes them by URL hash so rebuilds don't re-hit the API.

### Loader injection
Layouts should inject embed/widget loaders **only on pages that use them**. Cleanest approach: each content view sets a flag in `@Environment` during render; the layout's `<body>` end reads those flags and emits the corresponding loader scripts.

### CSS split suggestion
- `theme.css` — variables (light + dark sets) + base body
- `header.css` — capsule, menu, hamburger
- `footer.css`
- `article.css` — typography, hr, `img.lqip`, social embed margins, lite-youtube overrides
- `iphone-landscape.css` — the `@media (orientation: landscape) and (max-height: 500px)` rules

Match the existing class names where possible so the mockup remains a reference.
