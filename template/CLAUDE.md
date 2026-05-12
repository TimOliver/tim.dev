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

---

## When porting to Ignite

Likely plugin/component scaffolding:

- **`LazyImage` view**: combines build-time LQIP generation + lightbox wrapping. Emits the full `<a>` + `<img class="lqip">` + `<noscript>` triple.
- **`CapsuleHeader` layout**: the sticky backdrop-blurred header with the menu/logo/theme/social icons.
- **`HamburgerMenu` component**: encapsulates the WAAPI animation logic + checkbox toggle. The JS is verbose enough to belong in a separate `Includes/hamburger.js` rather than re-emitted inline per page.
- **`ThemeToggle` component**: the popover with auto/light/dark options. Pair with a head-script `Include` for FOUC prevention.
- **Asset pipeline**: hook into Ignite's build to pre-generate LQIP base64 for any image referenced in Markdown. Likely a custom `Plugin` or post-processing step.

The mockup's CSS can be split into:
- `theme.css` (variables + body)
- `header.css` (capsule, menu, hamburger)
- `footer.css`
- `article.css` (typography, hr, img.lqip)
- `lightbox-overrides.css` (if any)

Match the existing class names where possible so the mockup remains a reference.
