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
