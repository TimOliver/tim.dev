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

        // Cache probe: a detached <img> with the same srcset/sizes -
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

    function initialize() {
        // Release removed collection images before observing the replacement.
        if (io) io.disconnect();
        document.querySelectorAll('img.lqip[data-srcset]').forEach(function(img) {
            if (img.srcset) return;
            if (io) io.observe(img); else loadReal(img);
        });
    }
    initialize();
    document.addEventListener('collection:swapped', initialize);
})();

// Header popovers (theme picker, RSS feeds): a trigger toggles its panel;
// clicking outside or pressing Escape closes it. Returns the open/close setter.
function bindPopover(wrap, trigger, popover, onTriggerClick) {
    function setOpen(open) {
        popover.classList.toggle('open', open);
        trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
    }
    trigger.addEventListener('click', function(e) {
        if (onTriggerClick) onTriggerClick(e);
        e.stopPropagation();
        setOpen(!popover.classList.contains('open'));
    });
    document.addEventListener('click', function(e) {
        if (!wrap.contains(e.target)) setOpen(false);
    });
    document.addEventListener('keydown', function(e) {
        if (e.key !== 'Escape') return;
        setOpen(false);
        trigger.blur();
    });
    return setOpen;
}

(function() {
    var root = document.documentElement;
    var toggle = document.querySelector('.theme-toggle');
    var trigger = document.querySelector('.theme-toggle-button');
    if (!toggle || !trigger) return;
    // Scoped to the wrapper - the RSS menu below reuses the popover classes.
    var popover = toggle.querySelector('.theme-popover');
    var options = toggle.querySelectorAll('.theme-option');
    var allowedThemes = /^(auto|light|dark)$/;
    if (!popover || !options.length) return;

    var setPopoverOpen = bindPopover(toggle, trigger, popover);

    function markActive(value) {
        options.forEach(function(btn) {
            var active = btn.dataset.themeValue === value;
            btn.classList.toggle('active', active);
            btn.setAttribute('aria-pressed', active ? 'true' : 'false');
        });
    }

    var activeTheme = root.getAttribute('data-theme') || 'auto';
    markActive(allowedThemes.test(activeTheme) ? activeTheme : 'auto');

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
})();

// RSS feed menu: the same popover pattern as the theme toggle (shared
// .theme-popover/.theme-option styling), but the entries are plain links and
// the trigger is a real <a> to /feed.xml - so without JS the icon still
// reaches the main feed (and CSS hover-open covers pointer devices).
(function() {
    var wrap = document.querySelector('.rss-toggle');
    var trigger = document.querySelector('.rss-toggle-link');
    var popover = wrap ? wrap.querySelector('.theme-popover') : null;
    if (!wrap || !trigger || !popover) return;
    // The href is the no-JS fallback.
    bindPopover(wrap, trigger, popover, function(e) { e.preventDefault(); });
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
    var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
    var mobileMenu = window.matchMedia('(max-width: 720px)');

    function setExpanded(expanded) {
        label.setAttribute('aria-expanded', expanded ? 'true' : 'false');
        checkbox.setAttribute('aria-expanded', expanded ? 'true' : 'false');
        var closedBar = getClosedBar();
        if (closedBar) {
            // Opacity alone leaves the duplicate About/Archive links focusable.
            closedBar.inert = expanded && mobileMenu.matches;
            closedBar.setAttribute('aria-hidden', closedBar.inert ? 'true' : 'false');
        }
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

    function resetMenu() {
        // A completed navigation can interrupt an opening animation. Cancel all
        // header animations and clear the same inline state their finish handlers
        // normally release, so no old callback can reopen the menu afterward.
        capsule.getAnimations({ subtree: true }).forEach(function(animation) {
            animation.cancel();
        });
        getColumnItems().concat([getIconsRow()]).forEach(function(item) {
            if (!item) return;
            item.style.opacity = '';
            item.style.transform = '';
        });
        capsule.style.height = '';
        capsule.style.overflow = '';
        label.style.pointerEvents = '';
        animating = false;
        checkbox.checked = false;
        setExpanded(false);
    }

    document.addEventListener('collection:before-swap', resetMenu);
    document.addEventListener('keydown', function(event) {
        if (event.key !== 'Escape' || !checkbox.checked || !mobileMenu.matches) return;
        resetMenu();
        checkbox.focus();
    });
    mobileMenu.addEventListener('change', resetMenu);

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

        // CSS already describes both final states; skip WAAPI entirely when
        // motion is reduced, including all per-item delays and icon transforms.
        if (reduceMotion.matches) return;

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
    if (typeof EmblaCarousel === 'undefined') return;

    // One page can hold several galleries (e.g. About has one per history
    // section), so init each independently with its own viewport and arrows.
    document.querySelectorAll('.gallery').forEach(function(gallery) {
        var viewport = gallery.querySelector('.gallery-scroller');
        if (!viewport) return;
        var prev = gallery.querySelector('.gallery-arrow--prev');
        var next = gallery.querySelector('.gallery-arrow--next');

        // Rest each slide one overhang-width in from the viewport edge so every
        // snapped card sits flush with the content column, clear of the edge fade.
        // The scroller is pulled out into the page margin (negative margin-inline
        // = --overhang), so a card aligned to the viewport's own start edge lands
        // out in that bleed, behind the gradient - which is what made the snap
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
    });
})();

// Collection URL shapes, shared by the in-section swap and back-to-top:
// a section index (/talks/) or a detail page (/talks/x/, /art/section/x/ -
// art URLs are one level deeper).
var COLLECTION_INDEX = /^\/(apps|code|art|talks)\/$/;
var COLLECTION_DETAIL = /^\/(?:(apps|code|talks)\/[^/]+|(art)\/[^/]+\/[^/]+)\/$/;
var reducedMotion = window.matchMedia ? window.matchMedia('(prefers-reduced-motion: reduce)') : { matches: false };

// Collection pages: preserve in-section content fades and real permalinks.
// Different sections use normal navigation so their assets load together.
(function() {
    var container = document.querySelector('main .container');
    if (!container || !window.history || !window.fetch || !window.DOMParser) return;

    function collectionSection(path) {
        var index = path.match(COLLECTION_INDEX);
        if (index) return index[1];
        var detail = path.match(COLLECTION_DETAIL);
        return detail ? (detail[1] || detail[2]) : null;
    }
    function isDetailPath(path) {
        return COLLECTION_DETAIL.test(path);
    }
    var section = collectionSection(location.pathname);
    if (!section) return;

    var sequence = 0;
    var controller = null;
    var positions = Object.create(null);
    var entrySequence = 0;
    function newEntry() {
        return { collection: true, key: Date.now() + ':' + (++entrySequence), scroll: [0, 0] };
    }
    var currentEntry = history.state && history.state.collection ? history.state : newEntry();
    history.replaceState(currentEntry, '', location.href);
    // Only suspend native restoration while a Back/Forward fetch is pending.
    // Initial loads, reloads and full-page navigations retain browser behavior.
    window.addEventListener('pagehide', function() { history.scrollRestoration = 'auto'; });

    function rememberPosition() {
        positions[currentEntry.key] = [window.scrollX, window.scrollY];
        currentEntry.scroll = positions[currentEntry.key];
    }

    function updateMetadata(doc) {
        document.title = doc.title;
        var selector = 'link[rel="canonical"], meta[name="description"], meta[property^="og:"], meta[name^="twitter:"]';
        document.head.querySelectorAll(selector).forEach(function(node) { node.remove(); });
        doc.head.querySelectorAll(selector).forEach(function(node) {
            document.head.appendChild(node.cloneNode(true));
        });
    }

    function hashTarget(hash) {
        if (!hash) return null;
        try { return document.getElementById(decodeURIComponent(hash.slice(1))); }
        catch (err) { return null; }
    }

    function swapTo(url, push, fade, destinationEntry) {
        var request = ++sequence;
        if (controller) controller.abort();
        controller = typeof AbortController !== 'undefined' ? new AbortController() : null;
        var options = {};
        if (controller) options.signal = controller.signal;
        return fetch(url, options)
            .then(function(resp) {
                if (!resp.ok) throw new Error('bad status ' + resp.status);
                // A server redirect can cross into a section requiring other assets.
                if (resp.url) {
                    var finalURL = new URL(resp.url, location.href);
                    if (finalURL.origin !== location.origin || collectionSection(finalURL.pathname) !== section) {
                        throw new Error('redirect outside collection');
                    }
                }
                return resp.text();
            })
            .then(function(htmlText) {
                if (request !== sequence) return;
                var doc = new DOMParser().parseFromString(htmlText, 'text/html');
                var incoming = doc.querySelector('main .container');
                if (!incoming) throw new Error('no container in response');
                if (push) {
                    rememberPosition();
                    // During a pending Back request, the address already names
                    // another entry while this DOM still belongs to currentEntry.
                    if (history.state && history.state.key === currentEntry.key) {
                        history.replaceState(currentEntry, '', location.href);
                    }
                    currentEntry = newEntry();
                    history.pushState(currentEntry, '', url);
                } else {
                    currentEntry = destinationEntry || newEntry();
                    history.replaceState(currentEntry, '', url);
                }
                document.dispatchEvent(new Event('collection:before-swap'));
                container.innerHTML = incoming.innerHTML;
                updateMetadata(doc);
                if (fade) {
                    var root = container.querySelector('.collection');
                    if (root) root.classList.add('collection-swapped');
                }
                var heading = container.querySelector('h1') || container;
                heading.setAttribute('tabindex', '-1');
                heading.focus({ preventScroll: true });
                var position = positions[currentEntry.key] || currentEntry.scroll || [0, 0];
                var target = hashTarget(new URL(url, location.href).hash);
                if (push && target) target.scrollIntoView({ behavior: 'instant', block: 'start' });
                else window.scrollTo({ left: position[0], top: position[1], behavior: 'instant' });
                history.scrollRestoration = 'auto';
                document.dispatchEvent(new Event('collection:swapped'));
            })
            .catch(function(error) {
                // Aborted/late requests must never replace the latest destination.
                if (request !== sequence || error.name === 'AbortError') return;
                window.location.href = url;
            });
    }

    document.addEventListener('click', function(e) {
        if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey ||
            e.shiftKey || e.altKey) return;
        var a = e.target.closest('a');
        if (!a || a.hasAttribute('download') || (a.target && a.target !== '_self') ||
            a.origin !== location.origin) return;
        var href = a.getAttribute('href');
        if (!href) return;

        // Keep jump chips on the current page out of the fetch/history machinery.
        if (a.pathname === location.pathname && a.search === location.search && a.hash) {
            var target = hashTarget(a.hash);
            if (!target) return;
            e.preventDefault();
            target.scrollIntoView({ behavior: reducedMotion.matches ? 'instant' : 'smooth', block: 'start' });
            history.replaceState(currentEntry, '', a.href);
            return;
        }
        // A link to the page already showing (e.g. "Talks" in the header while
        // on Talks): scroll back to the top rather than refetching it and
        // stacking a duplicate history entry.
        if (a.pathname === location.pathname && a.search === location.search) {
            e.preventDefault();
            window.scrollTo({ top: 0, behavior: reducedMotion.matches ? 'instant' : 'smooth' });
            return;
        }
        if (href.charAt(0) === '#' || collectionSection(a.pathname) !== section) return;
        e.preventDefault();
        swapTo(a.href, true, isDetailPath(a.pathname));
    });

    window.addEventListener('popstate', function(event) {
        // popstate precedes native scroll restoration; prevent a restore onto
        // the outgoing content, then apply it once the destination is inserted.
        history.scrollRestoration = 'manual';
        rememberPosition();
        if (collectionSection(location.pathname) === section) {
            swapTo(location.href, false, false, event.state);
        } else {
            ++sequence;
            if (controller) controller.abort();
            window.location.reload();
        }
    });
})();

// Back-to-top: fade the button in after scrolling past a threshold; smooth-
// scroll to top on click. The button lives inside the swappable .container, so
// the content swap (above) replaces the node - hence we re-query it each tick
// and use event delegation for the click, rather than capturing the node once.
// No-op on pages that don't render the button.
(function() {
    // Only the archive/art/talks indexes render the button, but the collection
    // swap can bring it in on Art and Talks detail pages - gate on either, so
    // every other page skips the per-scroll-tick DOM query entirely.
    if (!document.querySelector('.back-to-top') &&
        !/^\/(art|talks)\//.test(location.pathname)) return;

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
        window.scrollTo({ top: 0, behavior: reducedMotion.matches ? 'auto' : 'smooth' });
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
    // The talks index can also appear after a same-section detail-page swap.
    if (!/^\/talks\//.test(location.pathname)) return;

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
        // Reveals the featured talk's (otherwise hidden) duplicate card.
        grid.classList.toggle('is-filtering', topic !== 'all' || year !== 'all' || query !== '');

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
        var status = document.querySelector('.talks-results');
        if (status) status.textContent = visible + (visible === 1 ? ' talk' : ' talks') + ' found.';
    }

    document.addEventListener('click', function(e) {
        var btn = e.target.closest ? e.target.closest('.talks-filter') : null;
        if (!btn) return;
        var row = btn.closest('.talks-filter-row');
        if (!row) return;
        var sibs = row.querySelectorAll('.talks-filter');
        Array.prototype.forEach.call(sibs, function(s) {
            s.classList.toggle('is-active', s === btn);
            s.setAttribute('aria-pressed', s === btn ? 'true' : 'false');
        });
        apply();
    });

    document.addEventListener('input', function(e) {
        var t = e.target;
        if (!t || !t.classList || !t.classList.contains('talks-search')) return;
        apply();
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
// link carries no data-share-path - it's a plain navigation link.
(function() {
    // Screen-reader live region for the "Copied!" confirmation - created on
    // first use rather than eagerly, so the ~200 pages where nobody copies a
    // link never grow the extra node.
    var live = null;
    function getLive() {
        if (live) return live;
        live = document.createElement('div');
        live.setAttribute('aria-live', 'polite');
        live.setAttribute('role', 'status');
        live.style.cssText = 'position:absolute;width:1px;height:1px;margin:-1px;'
            + 'padding:0;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap;border:0;';
        document.body.appendChild(live);
        return live;
    }

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
        if (use) use.setAttribute('href', '/img/site/ui-icons.svg#clipboard-check');
        if (label) label.textContent = 'Copied!';
        btn.classList.add('is-copied');
        var region = getLive();
        region.textContent = '';
        region.textContent = 'Link copied';
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
                // AbortError (user cancelled) or genuine failure - no-op.
            });
            return;
        }
        copyLink(url, shareBtn);
    });
})();

// (Comentario-specific behaviour - comment-count badges, editor refocus, the
// login-dialog tweaks - lives in comentario-tweaks.js, loaded only on pages
// with Comentario elements.)
