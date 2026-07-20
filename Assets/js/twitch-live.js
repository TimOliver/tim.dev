// Twitch "live now" card. Fetches https://twitch.tim.dev (JSON) and, when the
// channel is live, fills the card's slots and reveals it. Polls every 60s while
// the tab is visible (matches the endpoint's max-age=60) and removes the card
// when the stream ends. Home page only — the [data-twitch-live] element is
// absent elsewhere, so this self-exits. The big play button (facade embed) is
// wired in a separate block; see below.
(function () {
    'use strict';

    // "started N ago" from an ISO timestamp, relative to `now` (ms since epoch).
    function relativeTime(startedAtISO, now) {
        var started = Date.parse(startedAtISO);
        if (isNaN(started)) return '';
        var mins = Math.max(0, Math.floor((now - started) / 60000));
        if (mins < 1) return 'just now';
        if (mins < 60) return mins + ' min ago';
        var hrs = Math.floor(mins / 60);
        if (hrs < 24) {
            var rem = mins % 60;
            return rem ? (hrs + 'h ' + rem + 'm ago')
                       : (hrs + (hrs === 1 ? ' hr ago' : ' hrs ago'));
        }
        var days = Math.floor(hrs / 24);
        return days + (days === 1 ? ' day ago' : ' days ago');
    }

    // Viewer count with thousands separators: 1284 -> "1,284".
    function formatViewers(n) {
        var v = typeof n === 'number' ? n : parseInt(n, 10);
        if (isNaN(v) || v < 0) v = 0;
        return v.toLocaleString('en-US');
    }

    // Expose the pure helpers to Node for unit tests; a no-op in the browser.
    if (typeof module !== 'undefined' && module.exports) {
        module.exports = { relativeTime: relativeTime, formatViewers: formatViewers };
    }
    // Everything below needs the DOM. Node (unit tests) stops here.
    if (typeof document === 'undefined') return;

    var ENDPOINT = 'https://twitch.tim.dev';
    var CHANNEL = 'timXD';
    var POLL_MS = 60000;
    // Twitch's embed requires a `parent` for every host that serves the page.
    var EMBED_PARENTS = ['tim.dev', 'www.tim.dev', 'localhost'];

    var root = document.querySelector('[data-twitch-live]');
    if (!root) return;

    var media = root.querySelector('.twitch-live-media');
    var thumb = root.querySelector('[data-twitch-thumb]');
    var watch = root.querySelector('.twitch-live-watch');
    var slots = {
        title: root.querySelector('[data-twitch-title]'),
        game: root.querySelector('[data-twitch-game]'),
        viewers: root.querySelector('[data-twitch-viewers]'),
        ago: root.querySelector('[data-twitch-ago]')
    };
    var timer = null;
    var playing = false;
    // The channel currently being watched, reported by the endpoint. Drives the
    // embed and preview thumbnail; falls back to the owner's channel if absent.
    var currentLogin = CHANNEL;

    function render(stream) {
        slots.title.textContent = stream.title || '';
        slots.game.textContent = stream.game || '';
        slots.viewers.textContent = formatViewers(stream.viewers);
        slots.ago.textContent = relativeTime(stream.startedAt, Date.now());
        currentLogin = stream.login || CHANNEL;
        // "Watch on Twitch" follows the channel actually being watched (the
        // hardcoded href in the markup is the no-JS fallback to the owner's).
        if (watch) watch.href = 'https://twitch.tv/' + encodeURIComponent(currentLogin);
        // Fill Helix's {width}x{height} template; the CSS blurs it, so a modest
        // resolution reads as a soft ambient backdrop rather than an upscale.
        if (thumb && stream.thumbnail) {
            thumb.src = stream.thumbnail.replace('{width}', '1280').replace('{height}', '720');
        }
    }

    // Remove the on-demand Twitch embed (used when the stream ends). No-op until
    // the facade player has injected one.
    function teardownEmbed() {
        if (!playing) return;
        var iframe = media.querySelector('.twitch-live-embed');
        if (iframe && iframe.parentNode) iframe.parentNode.removeChild(iframe);
        media.classList.remove('is-playing');
        playing = false;
    }

    function show() { root.hidden = false; }

    function hide() {
        root.hidden = true;
        teardownEmbed();
    }

    function apply(data) {
        if (data && data.live && data.stream) {
            render(data.stream);
            show();
        } else {
            hide();
        }
    }

    function refresh() {
        fetch(ENDPOINT, { headers: { Accept: 'application/json' } })
            .then(function (res) { return res.ok ? res.json() : null; })
            .then(function (data) { apply(data); })
            .catch(function () { hide(); });
    }

    function startPolling() {
        if (timer) return;
        timer = setInterval(refresh, POLL_MS);
    }

    function stopPolling() {
        if (!timer) return;
        clearInterval(timer);
        timer = null;
    }

    function onVisibilityChange() {
        if (document.hidden) {
            stopPolling();
        } else {
            refresh();
            startPolling();
        }
    }

    // --- facade player: nothing from Twitch loads until the visitor clicks ---

    var playButton = root.querySelector('[data-twitch-play]');

    // Muted autoplay is browser-allowed; the visitor unmutes via Twitch's own
    // controls. `parent` must list every host that serves this page.
    function buildEmbed() {
        var src = 'https://player.twitch.tv/?channel=' + encodeURIComponent(currentLogin);
        EMBED_PARENTS.forEach(function (parent) {
            src += '&parent=' + encodeURIComponent(parent);
        });
        src += '&muted=true&autoplay=true';

        var iframe = document.createElement('iframe');
        iframe.className = 'twitch-live-embed';
        iframe.src = src;
        iframe.title = 'Twitch stream';
        iframe.allow = 'autoplay; fullscreen';
        iframe.setAttribute('allowfullscreen', '');
        return iframe;
    }

    function onPlay() {
        if (playing) return;
        var iframe = buildEmbed();
        media.appendChild(iframe);
        media.classList.add('is-playing');
        playing = true;
        // The play button is now display:none; move keyboard focus onto the
        // player the visitor just opened instead of dropping it to <body>.
        iframe.focus();
    }

    if (playButton) playButton.addEventListener('click', onPlay);
    // Clicking anywhere on the video canvas also starts playback. onPlay is a
    // no-op once playing, and clicks inside the cross-origin embed don't bubble
    // out, so the running player is never disturbed.
    media.addEventListener('click', onPlay);
    document.addEventListener('visibilitychange', onVisibilityChange);

    // Fetch + start polling only if the tab is currently visible. A page opened
    // in a background tab starts hidden and fires no visibilitychange until the
    // user activates it, so unconditional polling would run forever unviewed.
    // onVisibilityChange() does refresh()+startPolling() when visible and nothing
    // when hidden; the listener above resumes it on activation.
    onVisibilityChange();
})();
