// Capability detection that must run before first paint (FOUC-free), the
// same pattern as theme.js. Adds `has-web-share` to <html> when the Web
// Share API exists, so CSS can reveal Share controls only where they work.
(function() {
    if (navigator.share) {
        document.documentElement.classList.add('has-web-share');
    }
})();
