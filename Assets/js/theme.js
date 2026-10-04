// FOUC prevention + theme propagation. `data-theme` reflects the user's
// saved choice (`auto` | `light` | `dark`); `data-color-scheme`
// reflects the resolved effective scheme (`light` | `dark`) - CSS uses
// `data-color-scheme` so dark-mode rules need a single selector instead
// of duplicating across `[data-theme="auto"] @media-dark` and
// `[data-theme="dark"]`. Both attributes are kept in sync via a
// MutationObserver (toggle changes) + matchMedia listener (OS pref).
(function() {
    var root = document.documentElement;

    // Apply the narrow-iPad Safari layout class before first paint. Modern
    // iPadOS commonly reports MacIntel; multiple touch points disambiguate it
    // from a Mac. Keeping this in the synchronous head script avoids a late
    // capsule-position jump when site.js loads at the end of the body.
    try {
        var platform = navigator.platform || '';
        if (/iPad/.test(platform) ||
            (platform === 'MacIntel' && navigator.maxTouchPoints > 1)) {
            root.classList.add('is-ipad');
        }
    } catch (e) { /* detection is best-effort */ }

    var darkQuery = window.matchMedia
        ? window.matchMedia('(prefers-color-scheme: dark)')
        : { matches: false };
    var allowedThemes = /^(auto|light|dark)$/;

    function storedTheme() {
        try {
            var saved = localStorage.getItem('theme');
            return allowedThemes.test(saved) ? saved : 'auto';
        } catch (e) {
            return 'auto';
        }
    }

    function syncScheme() {
        var t = root.getAttribute('data-theme') || 'auto';
        if (!allowedThemes.test(t)) t = 'auto';
        var effective = t === 'auto' ? (darkQuery.matches ? 'dark' : 'light') : t;
        root.setAttribute('data-color-scheme', effective);
    }

    root.setAttribute('data-theme', storedTheme());
    syncScheme();

    if (darkQuery.addEventListener) {
        darkQuery.addEventListener('change', syncScheme);
    } else if (darkQuery.addListener) {
        darkQuery.addListener(syncScheme);
    }

    new MutationObserver(syncScheme).observe(root, {
        attributes: true,
        attributeFilter: ['data-theme']
    });
})();
