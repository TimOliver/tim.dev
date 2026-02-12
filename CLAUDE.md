# Dark Mode Popover

## What was done
All changes are in `index.html`. The appearance (moon) icon in `<ul id="menu">` is now a `.theme-toggle` `<li>` with a hover popover offering Auto/Light/Dark options.

### CSS
- All hardcoded colors replaced with CSS custom properties (`:root` block): `--bg`, `--text`, `--text-secondary`, `--text-tertiary`, `--heading`, `--link`, `--link-hover`, `--blockquote-bg`, `--border`, `--icon-filter`.
- Dark theme variables defined in two places (identical values):
  - `[data-theme="dark"]` — forced dark mode.
  - `@media (prefers-color-scheme: dark) { [data-theme="auto"] { ... } }` — follows OS preference.
- Icons (all `stroke="currentColor"` SVGs loaded via `<img>`) use `filter: var(--icon-filter)` which is `none` in light and `invert(1)` in dark.
- Nav icon selector narrowed to `#menu > li > a > img` to avoid specificity conflicts with popover icons.
- `.theme-toggle` has `padding: 0 15px; margin: 0 -15px` to widen the hover zone without shifting layout.
- Popover shown via `@media (hover: hover)` on desktop; `.open` class toggled via JS for touch devices. Invisible `::before` pseudo-element bridges the gap between trigger and popover.
- Icon hover tinting (changing icon color on mouseover) is not yet implemented. `filter: invert(1)` on `<img>` tags inverts any background/box-shadow applied to the same element. The clean fix is inlining the SVGs so `currentColor` works natively — planned for when the static site generator templating is set up.
- Popover sizing: min-width 200px, padding 10px, border-radius 16px. Options: font-size 18px, padding 12px 16px, icons 24px. 4px gap between options.
- Active option: bold weight + subtle background (`color-mix(in srgb, var(--blockquote-bg) 50%, transparent)`). Hover overrides to full `var(--blockquote-bg)` on all options including the active one.

### HTML
- `.theme-toggle` is an `<li>` inside `#menu`, positioned before the RSS icon.
- Contains the moon icon trigger (`img/appearance.svg`) and a `.theme-popover` div with 3 `<button>` elements (Auto/Light/Dark), each with an icon and label.

### JS
- Kept minimal — goal is to rely on as little JS as possible.
- Inline `<script>` in `<head>`: reads `localStorage('theme')` and sets `data-theme` on `<html>` immediately to prevent FOUC.
- Main `<script>` at end of `<body>`:
  - Click on trigger toggles `.open` class on popover (for touch).
  - Click on an option: saves to `localStorage`, sets `data-theme`, updates `.active` class, closes popover.
  - Click outside `.theme-toggle` removes `.open`.

## Icon inventory (`img/appearance/`)
- `auto.svg` — Auto option
- `sun.svg` — Light option
- `moon.svg` — Dark option
