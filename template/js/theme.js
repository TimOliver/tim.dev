// FOUC prevention + theme propagation. `data-theme` reflects the user's
// saved choice (`auto` | `light` | `dark`); `data-color-scheme`
// reflects the resolved effective scheme (`light` | `dark`) — CSS uses
// `data-color-scheme` so dark-mode rules need a single selector instead
// of duplicating across `[data-theme="auto"] @media-dark` and
// `[data-theme="dark"]`. Both attributes are kept in sync via a
// MutationObserver (toggle changes) + matchMedia listener (OS pref).
(function() {
    var saved = localStorage.getItem('theme') || 'auto';
    var darkQuery = window.matchMedia('(prefers-color-scheme: dark)');
    function syncScheme() {
        var t = document.documentElement.getAttribute('data-theme') || 'auto';
        var effective = t === 'auto' ? (darkQuery.matches ? 'dark' : 'light') : t;
        document.documentElement.setAttribute('data-color-scheme', effective);
    }
    document.documentElement.setAttribute('data-theme', saved);
    syncScheme();
    darkQuery.addEventListener('change', syncScheme);
    new MutationObserver(syncScheme).observe(document.documentElement, {
        attributes: true,
        attributeFilter: ['data-theme']
    });
    document.documentElement.classList.remove('no-js');
})();
