// Theme, before first paint. Inlined into every page's <head> at build time
// (comments and indentation stripped, see InlineScript in MainLayout.swift),
// so it costs no request. Keep it small; only whole-line `//` comments are
// stripped, so don't use `/* */`.
//
// `data-theme` is the saved choice (auto | light | dark); `data-color-scheme`
// is the resolved scheme (light | dark), so dark-mode CSS needs one selector.
// The toggle in site.js changes `data-theme`; the observer and the OS
// preference listener below keep `data-color-scheme` and the browser-UI tint
// (theme-color: the page background, #fff / #141414) in sync.
(function () {
    var root = document.documentElement;
    var dark = matchMedia('(prefers-color-scheme: dark)');
    var tint = document.querySelector('meta[name="theme-color"]');
    var valid = /^(auto|light|dark)$/;

    // Narrow-iPad Safari layout class. iPadOS reports MacIntel; touch points
    // tell it from a Mac. Set here so the capsule doesn't jump when site.js
    // loads at the end of the body.
    if (/iPad/.test(navigator.platform) ||
        (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)) {
        root.classList.add('is-ipad');
    }

    function sync() {
        var t = root.getAttribute('data-theme');
        var s = valid.test(t) && t !== 'auto' ? t : (dark.matches ? 'dark' : 'light');
        root.setAttribute('data-color-scheme', s);
        if (tint) tint.content = s === 'dark' ? '#141414' : '#ffffff';
    }

    // Storage can throw (private windows, blocked site data): fall back to auto.
    var saved;
    try { saved = localStorage.getItem('theme'); } catch (e) {}
    root.setAttribute('data-theme', valid.test(saved) ? saved : 'auto');
    sync();

    dark.addEventListener('change', sync);
    new MutationObserver(sync).observe(root, { attributes: true, attributeFilter: ['data-theme'] });
})();
