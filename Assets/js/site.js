// LQIP swap: each <img.lqip> ships with an inline tiny base64 PNG as
// its initial `src` and a responsive `data-srcset` (+ `data-sizes`).
// When the image scrolls near the viewport, we hand the data attrs
// over to the browser as real srcset/sizes; the browser picks the
// appropriate variant based on viewport + DPR and fetches it.
(function() {
    function loadReal(img) {
        var srcset = img.dataset.srcset;
        var sizes = img.dataset.sizes;
        if (!srcset) return;

        // Cache probe: a detached <img> with the same srcset/sizes —
        // if it reports `complete` synchronously, the chosen variant
        // is already in HTTP cache, so skip the blur fade.
        var probe = new Image();
        if (sizes) probe.sizes = sizes;
        probe.srcset = srcset;
        if (probe.complete && probe.naturalWidth > 0) {
            if (sizes) img.sizes = sizes;
            img.srcset = srcset;
            return;
        }

        img.classList.add('loading');
        function done() {
            img.classList.remove('loading');
            img.removeEventListener('load', done);
            img.removeEventListener('error', done);
        }
        img.addEventListener('load', done);
        img.addEventListener('error', done);
        if (sizes) img.sizes = sizes;
        img.srcset = srcset;
    }

    var io = typeof IntersectionObserver !== 'undefined'
        ? new IntersectionObserver(function(entries, observer) {
            entries.forEach(function(entry) {
                if (!entry.isIntersecting) return;
                observer.unobserve(entry.target);
                loadReal(entry.target);
            });
        }, { rootMargin: '200px' })
        : null;

    document.querySelectorAll('img.lqip[data-srcset]').forEach(function(img) {
        if (io) io.observe(img); else loadReal(img);
    });
})();

(function() {
    var root = document.documentElement;
    var toggle = document.querySelector('.theme-toggle');
    var trigger = document.querySelector('.theme-toggle-button');
    var popover = document.querySelector('.theme-popover');
    var options = document.querySelectorAll('.theme-option');
    var allowedThemes = /^(auto|light|dark)$/;
    if (!toggle || !trigger || !popover || !options.length) return;

    function setPopoverOpen(open) {
        popover.classList.toggle('open', open);
        trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
    }

    function markActive(value) {
        options.forEach(function(btn) {
            var active = btn.dataset.themeValue === value;
            btn.classList.toggle('active', active);
            btn.setAttribute('aria-pressed', active ? 'true' : 'false');
        });
    }

    var activeTheme = root.getAttribute('data-theme') || 'auto';
    markActive(allowedThemes.test(activeTheme) ? activeTheme : 'auto');

    trigger.addEventListener('click', function(e) {
        e.stopPropagation();
        setPopoverOpen(!popover.classList.contains('open'));
    });

    options.forEach(function(btn) {
        btn.addEventListener('click', function() {
            var value = btn.dataset.themeValue;
            if (!allowedThemes.test(value)) return;
            try {
                localStorage.setItem('theme', value);
            } catch (e) {}
            root.setAttribute('data-theme', value);
            markActive(value);
            setPopoverOpen(false);
        });
    });

    document.addEventListener('click', function(e) {
        if (!toggle.contains(e.target)) setPopoverOpen(false);
    });

    document.addEventListener('keydown', function(e) {
        if (e.key !== 'Escape') return;
        setPopoverOpen(false);
        trigger.blur();
    });
})();

// Hamburger menu open/close animation
(function() {
    var checkbox = document.getElementById('menu-toggle');
    var label = document.querySelector('label[for="menu-toggle"]');
    var capsule = document.getElementById('header-content');
    var menu = document.getElementById('menu');
    var iconHam = document.querySelector('.icon-hamburger');
    var iconX = document.querySelector('.icon-close');
    if (!checkbox || !label || !capsule || !menu || !iconHam || !iconX) return;

    var iosEase = getComputedStyle(document.documentElement).getPropertyValue('--menu-ease').trim()
        || 'cubic-bezier(0.32, 0.72, 0, 1)';
    var heightDuration = 450;
    var fadeDuration = 500;
    var iconDuration = 250;
    var staggerStep = 35;

    var animating = false;

    function setExpanded(expanded) {
        label.setAttribute('aria-expanded', expanded ? 'true' : 'false');
    }

    setExpanded(checkbox.checked);

    function getColumnItems() {
        // Items in the vertical list (excludes the absolute-positioned icons row)
        return Array.prototype.slice.call(
            menu.querySelectorAll('li:not(.menu-hamburger):not(.menu-row-icons)')
        );
    }

    function getIconsRow() {
        return menu.querySelector('.menu-row-icons');
    }

    function getClosedBar() {
        return capsule.querySelector('.menu-closed-bar');
    }

    // Swap hamburger <-> X icons + cross-fade label background. Returns
    // the three animation handles so the caller can cancel them.
    function animateIconSwap(opening, fromBg, toBg) {
        var hamFrom = opening ? 1 : 0;
        var hamTo   = opening ? 0 : 1;
        var xFrom   = opening ? 0 : 1;
        var xTo     = opening ? 1 : 0;
        var opts = { duration: iconDuration, easing: iosEase, fill: 'forwards' };
        return [
            iconHam.animate(
                [{ opacity: hamFrom, transform: 'scale(' + hamFrom + ')' },
                 { opacity: hamTo,   transform: 'scale(' + hamTo   + ')' }],
                opts
            ),
            iconX.animate(
                [{ opacity: xFrom, transform: 'scale(' + xFrom + ')' },
                 { opacity: xTo,   transform: 'scale(' + xTo   + ')' }],
                opts
            ),
            label.animate(
                [{ backgroundColor: fromBg }, { backgroundColor: toBg }],
                opts
            )
        ];
    }

    checkbox.addEventListener('change', function() {
        if (animating) {
            // Revert checkbox back to its pre-click state so CSS state
            // doesn't desync with the in-flight animation.
            checkbox.checked = !checkbox.checked;
            setExpanded(checkbox.checked);
            return;
        }

        setExpanded(checkbox.checked);

        if (checkbox.checked) {
            animateOpen();
        } else {
            animateClose();
        }
    });

    function animateOpen() {
        animating = true;
        label.style.pointerEvents = 'none';

        // Pre-hide column items + icons row + closed-bar BEFORE the
        // checkbox toggle so they don't flash visible for one frame
        // when CSS enters the open state.
        var columnItems = getColumnItems();
        columnItems.forEach(function(item) {
            item.style.opacity = '0';
        });
        var iconsRow = getIconsRow();
        if (iconsRow) iconsRow.style.opacity = '0';

        // checkbox already checked (CSS in open state). Capture both heights + colors via temp-toggle.
        var endHeight = capsule.offsetHeight;
        var bgToColor = getComputedStyle(label).backgroundColor;
        checkbox.checked = false;
        var startHeight = capsule.offsetHeight;
        var bgFromColor = getComputedStyle(label).backgroundColor;
        checkbox.checked = true;

        capsule.style.height = startHeight + 'px';
        capsule.style.overflow = 'hidden';
        capsule.offsetHeight; // force reflow

        var iconAnims = animateIconSwap(true, bgFromColor, bgToColor);

        var heightAnim = capsule.animate(
            [{ height: startHeight + 'px' }, { height: endHeight + 'px' }],
            { duration: heightDuration, easing: iosEase, fill: 'forwards' }
        );
        heightAnim.onfinish = function() {
            capsule.style.height = '';
            capsule.style.overflow = '';
            heightAnim.cancel();
            iconAnims.forEach(function(a) { a.cancel(); });
            label.style.pointerEvents = '';
            animating = false;
        };

        // Stagger fade in column items (opacity was pre-set at the top)
        columnItems.forEach(function(item, i) {
            var anim = item.animate(
                [
                    { opacity: 0, transform: 'translateY(-4px)' },
                    { opacity: 1, transform: 'translateY(0)' }
                ],
                {
                    duration: fadeDuration,
                    delay: i * staggerStep,
                    easing: iosEase,
                    fill: 'both'
                }
            );
            anim.onfinish = function() {
                item.style.opacity = '';
                item.style.transform = '';
                anim.cancel();
            };
        });

        // Crossfade the icons row in (no stagger, quick)
        if (iconsRow) {
            var iconsAnim = iconsRow.animate(
                [{ opacity: 0 }, { opacity: 1 }],
                { duration: fadeDuration, delay: 60, easing: iosEase, fill: 'both' }
            );
            iconsAnim.onfinish = function() {
                iconsRow.style.opacity = '';
                iconsAnim.cancel();
            };
        }

        // Fade out closed-bar (was visible in closed state)
        var closedBar = getClosedBar();
        if (closedBar) {
            var closedBarAnim = closedBar.animate(
                [{ opacity: 1 }, { opacity: 0 }],
                { duration: fadeDuration, easing: iosEase, fill: 'forwards' }
            );
            closedBarAnim.onfinish = function() {
                closedBarAnim.cancel();
            };
        }
    }

    function animateClose() {
        animating = true;
        label.style.pointerEvents = 'none';

        // Capture current bg color (still in open state)
        var bgFromColor = getComputedStyle(label).backgroundColor;

        // Currently checkbox is unchecked (just toggled by user).
        // To keep open layout during animation, re-open it programmatically.
        var endHeight = capsule.offsetHeight; // closed height
        checkbox.checked = true;              // restore open layout
        var startHeight = capsule.offsetHeight; // open height

        capsule.style.height = startHeight + 'px';
        capsule.style.overflow = 'hidden';
        capsule.offsetHeight;

        // Manually drive the icon swap (X -> hamburger) since CSS is in open state
        var iconAnims = animateIconSwap(false, bgFromColor, 'transparent');

        var heightAnim = capsule.animate(
            [{ height: startHeight + 'px' }, { height: endHeight + 'px' }],
            { duration: heightDuration, easing: iosEase, fill: 'forwards' }
        );

        // Fade out column items + icons row in parallel
        var columnItems = getColumnItems();
        var itemAnims = columnItems.map(function(item) {
            return item.animate(
                [{ opacity: 1 }, { opacity: 0 }],
                { duration: fadeDuration, easing: iosEase, fill: 'forwards' }
            );
        });
        var iconsRow = getIconsRow();
        var iconsAnim = iconsRow ? iconsRow.animate(
            [{ opacity: 1 }, { opacity: 0 }],
            { duration: fadeDuration, easing: iosEase, fill: 'forwards' }
        ) : null;

        // Fade closed-bar IN as menu shrinks
        var closedBar = getClosedBar();
        var closedBarAnim = closedBar ? closedBar.animate(
            [{ opacity: 0 }, { opacity: 1 }],
            { duration: heightDuration, easing: iosEase, fill: 'forwards' }
        ) : null;

        heightAnim.onfinish = function() {
            checkbox.checked = false; // commit closed state at end
            setExpanded(false);
            capsule.style.height = '';
            capsule.style.overflow = '';
            heightAnim.cancel();
            iconAnims.forEach(function(a) { a.cancel(); });
            itemAnims.forEach(function(a) { a.cancel(); });
            if (iconsAnim) iconsAnim.cancel();
            if (closedBarAnim) closedBarAnim.cancel();
            label.style.pointerEvents = '';
            animating = false;
        };
    }
})();

// Embla Carousel: pointer drag (mouse + touch), arrow buttons, and snapping, without native scroll.
// (.gallery-track) as the slide container.
(function() {
    var viewport = document.querySelector('.gallery-scroller');
    if (!viewport || typeof EmblaCarousel === 'undefined') return;
    var prev = document.querySelector('.gallery-arrow--prev');
    var next = document.querySelector('.gallery-arrow--next');

    // Rest each slide one overhang-width in from the viewport edge so every
    // snapped card sits flush with the content column, clear of the edge fade.
    // The scroller is pulled out into the page margin (negative margin-inline
    // = --overhang), so a card aligned to the viewport's own start edge lands
    // out in that bleed, behind the gradient — which is what made the snap
    // positions look arbitrary. Read the resolved margin-left (a real px value)
    // and offset every snap inward by it. Reading the computed margin rather
    // than recomputing the clamp keeps this locked to the CSS --overhang no
    // matter how that's retuned; Embla calls it again on reInit (resize).
    function startInset() {
        return -(parseFloat(getComputedStyle(viewport).marginLeft) || 0);
    }
    var embla = EmblaCarousel(viewport, { align: startInset, containScroll: 'trimSnaps' });

    function update() {
        if (prev) prev.disabled = !embla.canScrollPrev();
        if (next) next.disabled = !embla.canScrollNext();
    }
    if (prev) prev.addEventListener('click', function() { embla.scrollPrev(); });
    if (next) next.addEventListener('click', function() { embla.scrollNext(); });
    embla.on('select', update).on('reInit', update);
    update();
})();

// Apps page: in-place content swap (progressive enhancement). Each app is a
// real page at /apps/<slug>/ that works without JS; this intercepts in-section
// navigation, fetches the target page, swaps only the .container contents, and
// keeps real URLs via the History API (so back/forward, refresh, and direct
// links all work). Any failure falls back to a normal navigation.
(function() {
    // The page content is a `.container` div inside <main> (class is
    // "ig-main-content container"), so target `main .container`, NOT
    // `main.container` (which matches nothing).
    var container = document.querySelector('main .container');
    if (!container || !window.history || !window.fetch || !window.DOMParser) return;

    // Only operate on Apps/Code/Art/Talks pages (grid or a detail page).
    function isCollectionPath(path) {
        return /^\/(apps|code|art|talks)\/$/.test(path)
            || /^\/(apps|code|talks)\/[^/]+\/$/.test(path)
            || /^\/art\/[^/]+\/[^/]+\/$/.test(path);
    }
    // A collection ITEM detail page (apps/code/talks: 2-deep; art: 3-deep) — NOT
    // a grid index. The content fade is reserved for navigating into an item, so
    // moving between section grids (Apps ↔ Code via nav) doesn't crossfade.
    function isDetailPath(path) {
        return /^\/(apps|code|talks)\/[^/]+\/$/.test(path)
            || /^\/art\/[^/]+\/[^/]+\/$/.test(path);
    }
    if (!isCollectionPath(location.pathname)) return;

    // Represent the initial page in history so the first back press is real.
    history.replaceState({ apps: true }, '', location.href);

    function swapTo(url, push, fade) {
        return fetch(url, { headers: { 'X-Requested-With': 'fetch' } })
            .then(function(resp) {
                if (!resp.ok) throw new Error('bad status ' + resp.status);
                return resp.text();
            })
            .then(function(htmlText) {
                var doc = new DOMParser().parseFromString(htmlText, 'text/html');
                var incoming = doc.querySelector('main .container');
                if (!incoming) throw new Error('no container in response');
                container.innerHTML = incoming.innerHTML;
                // Fade only when navigating INTO an item (fade === true): a fresh
                // node gets the class so the animation runs. Grid↔grid nav and
                // back-links swap without a crossfade.
                if (fade) {
                    var root = container.querySelector('.collection');
                    if (root) root.classList.add('collection-swapped');
                }
                if (push) history.pushState({ apps: true }, '', url);
                window.scrollTo(0, 0);
            })
            .catch(function() {
                // Fallback: hard navigation always gets the user somewhere.
                window.location.href = url;
            });
    }

    // In-page hash links (the jump-nav chips → #section) get an explicit,
    // controlled smooth-scroll. Handling them here — rather than letting the
    // native anchor jump run — avoids a race where the URL-hash change and the
    // swap/popstate machinery briefly scroll the page back to the top.
    var reduceMotion = window.matchMedia &&
        window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    document.addEventListener('click', function(e) {
        if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey ||
            e.shiftKey || e.altKey) return;
        var a = e.target.closest('a');
        if (!a) return;
        var href = a.getAttribute('href');
        if (!href || href.charAt(0) !== '#' || href.length < 2) return;
        var target = document.getElementById(href.slice(1));
        if (!target) return;
        e.preventDefault();
        target.scrollIntoView({ behavior: reduceMotion ? 'auto' : 'smooth', block: 'start' });
        history.replaceState(history.state, '', href);
    });

    // Intercept clicks on same-origin /apps/ links (cards + "Back to Apps").
    document.addEventListener('click', function(e) {
        if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey ||
            e.shiftKey || e.altKey) return;
        var a = e.target.closest('a');
        if (!a) return;
        var href = a.getAttribute('href');
        if (!href || a.target === '_blank' || a.origin !== location.origin) return;
        // In-page hash links are handled by the smooth-scroll listener above.
        if (href.charAt(0) === '#') return;
        if (!isCollectionPath(a.pathname)) return;
        e.preventDefault();
        // Fade only when the destination is an item detail page (clicking a
        // card), not when moving between section grids via the nav.
        swapTo(a.href, true, isDetailPath(a.pathname));
    });

    // Back/forward: swap to whatever URL history lands on (within /apps/);
    // outside the section, let the browser do a normal load.
    window.addEventListener('popstate', function() {
        if (isCollectionPath(location.pathname)) {
            swapTo(location.href, false);
        } else {
            window.location.reload();
        }
    });
})();

// Back-to-top: fade the button in after scrolling past a threshold; smooth-
// scroll to top on click. The button lives inside the swappable .container, so
// the content swap (above) replaces the node — hence we re-query it each tick
// and use event delegation for the click, rather than capturing the node once.
// No-op on pages that don't render the button.
(function() {
    var reduce = window.matchMedia &&
        window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function update() {
        var btn = document.querySelector('.back-to-top');
        if (!btn) return;
        // Visible once scrolled down, but hide again near the page bottom so the
        // fixed button never floats over the footer content (the credit sits
        // bottom-right, where the button lives).
        var fromBottom = document.documentElement.scrollHeight
            - (window.scrollY + window.innerHeight);
        if (window.scrollY > 600 && fromBottom > 160) {
            btn.classList.add('visible');
        } else {
            btn.classList.remove('visible');
        }
    }

    window.addEventListener('scroll', update, { passive: true });
    update();

    // Delegated click survives the .container innerHTML swap.
    document.addEventListener('click', function(e) {
        if (!e.target.closest('.back-to-top')) return;
        window.scrollTo({ top: 0, behavior: reduce ? 'auto' : 'smooth' });
    });
})();

// Contact email: assemble the mailto + reveal the real address from split
// data-* attrs, so the raw address isn't in the static HTML for scrapers.
// No-op on pages without such elements; degrades to the obfuscated text.
(function() {
    var els = document.querySelectorAll('[data-user][data-domain]');
    if (!els.length) return;
    Array.prototype.forEach.call(els, function(el) {
        var addr = el.getAttribute('data-user') + '@' + el.getAttribute('data-domain');
        if (el.tagName === 'A') el.setAttribute('href', 'mailto:' + addr);
        el.textContent = addr;
    });
})();

// Talks page: client-side search + topic + year filtering over the grid.
// No-op unless the talks grid is present. Reads the current selection straight
// from the DOM each run (no retained state), and binds via document-level
// delegation, so it survives the content-swap re-inserting the index. With JS
// off the full grid simply shows.
(function() {
    var YEAR_BUCKETS = {
        '2023-26': [2023, 2026],
        '2019-22': [2019, 2022],
        '2015-18': [2015, 2018],
        '2011-14': [2011, 2014]
    };

    function apply() {
        var grid = document.querySelector('.talks-grid');
        if (!grid) return;  // not on the talks page (or not yet swapped in)

        var topicBtn = document.querySelector('.talks-filter-topic.is-active');
        var yearBtn = document.querySelector('.talks-filter-year.is-active');
        var search = document.querySelector('.talks-search');
        var topic = topicBtn ? topicBtn.getAttribute('data-topic') : 'all';
        var year = yearBtn ? yearBtn.getAttribute('data-year') : 'all';
        var query = search ? search.value.trim().toLowerCase() : '';
        var bucket = YEAR_BUCKETS[year];

        var cards = grid.querySelectorAll('.talks-card');
        var visible = 0;
        Array.prototype.forEach.call(cards, function(card) {
            var topics = (card.getAttribute('data-topics') || '').split(' ');
            var cardYear = parseInt(card.getAttribute('data-year'), 10);
            var hay = card.getAttribute('data-search') || '';
            var okTopic = topic === 'all' || topics.indexOf(topic) !== -1;
            var okYear = year === 'all' || (bucket && cardYear >= bucket[0] && cardYear <= bucket[1]);
            var okQuery = query === '' || hay.indexOf(query) !== -1;
            var show = okTopic && okYear && okQuery;
            card.classList.toggle('hidden', !show);
            if (show) visible++;
        });

        var empty = document.querySelector('.talks-empty');
        if (empty) empty.hidden = visible !== 0;
        grid.classList.toggle('hidden', visible === 0);
    }

    document.addEventListener('click', function(e) {
        var btn = e.target.closest ? e.target.closest('.talks-filter') : null;
        if (!btn) return;
        var row = btn.closest('.talks-filter-row');
        if (!row) return;
        var sibs = row.querySelectorAll('.talks-filter');
        Array.prototype.forEach.call(sibs, function(s) {
            s.classList.toggle('is-active', s === btn);
        });
        apply();
    });

    document.addEventListener('input', function(e) {
        var t = e.target;
        if (!t || !t.classList || !t.classList.contains('talks-search')) return;
        apply();
    });
})();

// Instagram embeds: our legacy posts use plain /embed/ iframes (no Instagram
// script of our own). Instagram's embed page postMessages its rendered height —
// mirror what their embeds.js would do and resize the matching iframe so
// captions aren't clipped. Origin-checked; no-op on pages without IG embeds.
(function() {
    if (!document.querySelector('.ig-embed')) return;
    window.addEventListener('message', function(e) {
        var host;
        try { host = new URL(e.origin).hostname; } catch (err) { return; }
        if (host !== 'www.instagram.com' && host !== 'instagram.com') return;
        var data = e.data;
        if (typeof data === 'string') {
            try { data = JSON.parse(data); } catch (err) { return; }
        }
        if (!data || data.type !== 'MEASURE' || !data.details || !data.details.height) return;
        var frames = document.querySelectorAll('.ig-embed iframe');
        for (var i = 0; i < frames.length; i++) {
            if (frames[i].contentWindow === e.source) {
                frames[i].style.height = data.details.height + 'px';
                break;
            }
        }
    });
})();

// Archive: client-side title filter. Hides rows whose title doesn't match,
// collapses year sections that empty out, keeps the per-year count live, and
// toggles a no-results message. No-op on pages without the archive search box.
(function() {
    var input = document.querySelector('.archive-search');
    if (!input) return;
    var years = Array.prototype.slice.call(document.querySelectorAll('.archive-year'));
    var empty = document.querySelector('.archive-empty');
    // Stash each year's original count so it can be restored when the query clears.
    Array.prototype.forEach.call(document.querySelectorAll('.archive-year-count'), function(el) {
        el.setAttribute('data-total', el.textContent);
    });
    function apply() {
        var q = input.value.trim().toLowerCase();
        var totalVisible = 0;
        years.forEach(function(section) {
            var visible = 0;
            Array.prototype.forEach.call(section.querySelectorAll('.archive-row'), function(row) {
                var show = q === '' || (row.getAttribute('data-title') || '').indexOf(q) !== -1;
                row.classList.toggle('hidden', !show);
                if (show) visible++;
            });
            section.classList.toggle('hidden', visible === 0);
            var pc = section.querySelector('.archive-year-count');
            if (pc) pc.textContent = q === '' ? pc.getAttribute('data-total')
                : visible + (visible === 1 ? ' post' : ' posts');
            totalVisible += visible;
        });
        if (empty) empty.hidden = totalVisible !== 0;
    }
    input.addEventListener('input', apply);
})();

// Share + copy for any [data-share-path] control (the share badge at the top
// of a feed item, the end-of-article Share link). Share opens the native sheet
// where the Web Share API exists, else it copies the link. Copy shows a brief
// check + "Copied!" confirmation, using the async Clipboard API where available
// and a legacy execCommand textarea otherwise (so it works in non-secure
// contexts, e.g. local LAN preview). URLs are built client-side. The Permalink
// link carries no data-share-path — it's a plain navigation link.
(function() {
    var live = document.createElement('div');
    live.setAttribute('aria-live', 'polite');
    live.setAttribute('role', 'status');
    live.style.cssText = 'position:absolute;width:1px;height:1px;margin:-1px;'
        + 'padding:0;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap;border:0;';
    document.body.appendChild(live);

    function confirmCopied(btn) {
        var use = btn.querySelector('use');
        var label = btn.querySelector('.post-link-label');
        // Capture the originals once per control (stored on the element) so a
        // repeat click before the revert doesn't leave it stuck.
        if (!btn.classList.contains('is-copied')) {
            btn._iconHref = use ? use.getAttribute('href') : null;
            btn._labelText = label ? label.textContent : null;
        }
        if (btn._revertTimer) clearTimeout(btn._revertTimer);
        if (use) use.setAttribute('href', '/img/ui-icons.svg#clipboard-check');
        if (label) label.textContent = 'Copied!';
        btn.classList.add('is-copied');
        live.textContent = '';
        live.textContent = 'Link copied';
        btn._revertTimer = setTimeout(function() {
            btn._revertTimer = null;
            if (use && btn._iconHref) use.setAttribute('href', btn._iconHref);
            if (label && btn._labelText !== null) label.textContent = btn._labelText;
            btn.classList.remove('is-copied');
        }, 1500);
    }

    function legacyCopy(text) {
        try {
            var ta = document.createElement('textarea');
            ta.value = text;
            ta.setAttribute('readonly', '');
            ta.style.cssText = 'position:fixed;top:0;left:0;opacity:0;';
            document.body.appendChild(ta);
            ta.select();
            var ok = document.execCommand('copy');
            document.body.removeChild(ta);
            return ok;
        } catch (err) {
            return false;
        }
    }

    function copyLink(url, btn) {
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(url).then(function() {
                confirmCopied(btn);
            }).catch(function() {
                if (legacyCopy(url)) confirmCopied(btn);
            });
        } else if (legacyCopy(url)) {
            confirmCopied(btn);
        }
    }

    document.addEventListener('click', function(e) {
        var shareBtn = e.target.closest && e.target.closest('[data-share-path]');
        if (!shareBtn) return;
        e.preventDefault();
        var url = location.origin + shareBtn.getAttribute('data-share-path');
        if (navigator.share) {
            navigator.share({
                title: shareBtn.getAttribute('data-share-title') || document.title,
                url: url
            }).catch(function() {
                // AbortError (user cancelled) or genuine failure — no-op.
            });
            return;
        }
        copyLink(url, shareBtn);
    });
})();

// (Comentario-specific behaviour — comment-count badges, editor refocus, the
// login-dialog tweaks — lives in comentario-tweaks.js, loaded only on pages
// with Comentario elements.)
