/* comentario-tweaks.js
 *
 * ALL client-side behaviour for the embedded Comentario widget lives here. (All
 * visual styling lives in Assets/css/comentario.css; this file is only for things
 * CSS can't do.) Loaded only on post pages, alongside the widget. (The home
 * feed's count badges don't load the widget at all - see comment-counts.js.)
 *
 * 1. Comment-count badges: toggle .has-count so the count (and its spacing) only
 *    shows once a number is actually present.
 *
 * 2. Clear the editor draft after a successful post. Comentario saves the editor text
 *    as a per-page draft (localStorage "comentario_editor") and writes the
 *    just-submitted text back as a draft on a successful post, so it reappears the
 *    next time you open the box. We delete the page's draft once a submit succeeds.
 *
 * 3. Anonymous-commenting status + sign-out. After commenting anonymously, Comentario
 *    quietly enters "unregistered commenting" mode (comentario_settings) and posts
 *    further comments with the same name and no dialog - with no visual cue and no
 *    way out. When in that mode we replace the profile-bar "Sign in" button with the
 *    name + a "Sign out" control that clears the mode.
 *
 * 4. Collapsed-editor refocus: after Cancel the collapsed host keeps focus, so
 *    clicking it again fires no focus event and it won't re-expand - blur+refocus
 *    to re-fire it.
 *
 * 5. Login dialog (created on demand): relabel the email field's placeholder to
 *    "Email". (The sign-up button needs no relabel - comentario.css hides its text
 *    and supplies the "Create an account" pill label via ::after.) Also slug-tag
 *    each OAuth provider button with cmntr-idp-<name> (from its label): built-in
 *    providers carry a brand class (.comentario-btn-google) but generic-OIDC ones
 *    all share .comentario-btn-dark, so without the slug CSS can't tell Microsoft
 *    from a future LinkedIn to swap in the right brand glyph.
 *
 * 6. OAuth popup pre-open, so Safari doesn't block the sign-in window. Comentario
 *    only calls window.open() two async hops after the provider button is clicked
 *    (after the dialog's close animation, then a token fetch). Chrome's transient
 *    activation tolerates that; Safari doesn't, blocks the window, and Comentario
 *    falls into its "Popup blocked" / Retry dialog - whose Retry reuses the same
 *    one-time token and fails with "Token is missing or invalid" once the user has
 *    allowed the blocked window and signed in through it. We open a blank popup
 *    synchronously in the click instead and hand it to Comentario when it asks.
 *
 * 7. Arriving at #comments (the feed's comment links): the browser scrolls once,
 *    on load, before the widget has rendered, so the section is nearly the end of
 *    the page and the comments then load in below the fold. Once the first comment
 *    appears, smoothly scroll just far enough to show it (not its replies) -
 *    unless the visitor has already scrolled or it's already on screen. Posts
 *    with no comments stay put.
 */
(function () {
  'use strict';

  /* ---- 1. Comment counts (home feed badges, end-of-article links, post heading) ----
     Comentario keeps each <comentario-count> in place even at zero and fills it
     in later, so one observer per count: badges and the heading toggle
     .has-count once a number shows; the end-of-article links drop their
     fallback "Comments" text once Comentario's count span arrives, and use a
     fixed " comments" suffix, so a single comment's "1 comments" becomes
     "1 comment". */
  (function () {
    var counts = document.querySelectorAll('comentario-count');
    if (!counts.length) return;

    function sync(el) {
      var text = (el.textContent || '').trim();
      if (el.closest('.post-link')) {
        // The link ships with "Comments" as fallback text (a name before, or
        // without, the count). Comentario doesn't replace it: it appends its own
        // span ("10 comments", or "Comments" on error), which read as
        // "Comments10 comments". Once that span is in, drop the fallback.
        var count = el.querySelector('.comentario-comment-count');
        if (!count) return;
        Array.prototype.slice.call(el.childNodes).forEach(function (node) {
          if (node !== count) el.removeChild(node);
        });
        if (count.textContent.trim() === '1 comments') count.textContent = '1 comment';
      } else {
        el.classList.toggle('has-count', text !== '');
      }
    }

    Array.prototype.forEach.call(counts, function (el) {
      sync(el);  // in case the count resolved before this script ran
      new MutationObserver(function () { sync(el); })
        .observe(el, { childList: true, characterData: true, subtree: true });
    });
  })();

  // Everything below operates on the live comments widget - bail on pages that
  // only have count badges (the home feed) so no listeners/observers/polls are
  // left running against a widget that can never appear.
  var widget = document.querySelector('comentario-comments');
  if (!widget) return;

  // site.css spins a placeholder until the widget's root has content. If it
  // never fills (comentario.js blocked, or its API unreachable), stop the
  // spinner after 20 seconds rather than promise comments that aren't coming.
  setTimeout(function () {
    if (!widget.querySelector('.comentario-root > *')) widget.classList.add('is-unavailable');
  }, 20000);

  // Share one bounded readiness observer. A blocked/offline external script
  // may never render its root; stop waiting after 20 seconds without polling.
  var readyRoot = null;
  var readyCallbacks = [];
  var rootObserver = null;
  var rootTimeout = null;
  var rootUnavailable = false;
  function whenRootReady(callback) {
    if (readyRoot) { callback(readyRoot); return; }
    if (rootUnavailable) return;
    readyCallbacks.push(callback);
    function checkRoot() {
      readyRoot = widget.querySelector('.comentario-root');
      if (!readyRoot) return;
      if (rootObserver) rootObserver.disconnect();
      clearTimeout(rootTimeout);
      readyCallbacks.splice(0).forEach(function (apply) { apply(readyRoot); });
    }
    checkRoot();
    if (readyRoot || rootObserver) return;
    rootObserver = new MutationObserver(checkRoot);
    rootObserver.observe(widget, { childList: true, subtree: true });
    rootTimeout = setTimeout(function () {
      rootObserver.disconnect();
      readyCallbacks = [];
      rootUnavailable = true;
    }, 20000);
  }

  /* ---- 2. Clear the editor draft after a successful post ---- */

  var DRAFT_KEY = 'comentario_editor';

  // Comentario keys drafts by a server-assigned page id (from the page-load response),
  // NOT the URL path - so we can't match by path. Instead delete the draft whose
  // stored text equals what was just submitted: that's exactly the entry Comentario
  // writes back on a successful post (the bug we're papering over). Matching on content
  // also works whether the page had a prior draft or not.
  function removeSubmittedDraft(submitted) {
    var target = (submitted || '').trim();
    if (!target) return;
    try {
      var raw = localStorage.getItem(DRAFT_KEY);
      if (!raw) return;
      var data = JSON.parse(raw);
      if (!data || !data.drafts) return;
      var changed = false;
      Object.keys(data.drafts).forEach(function (k) {
        if ((data.drafts[k] || '').trim() === target) { delete data.drafts[k]; changed = true; }
      });
      if (changed) localStorage.setItem(DRAFT_KEY, JSON.stringify(data));
    } catch (e) { /* localStorage unavailable or malformed - leave it alone */ }
  }

  // On a successful post Comentario empties or removes the editor's textarea; on a
  // validation/network failure the text stays put. Poll to tell them apart, then clear
  // the draft (twice - the second pass beats Comentario's debounced re-save).
  function clearDraftOnSuccess(form, submitted) {
    var tries = 0;
    var iv = setInterval(function () {
      tries++;
      var ta = form.isConnected ? form.querySelector('textarea') : null;
      if (!ta || !ta.value.trim()) {
        removeSubmittedDraft(submitted);
        setTimeout(function () { removeSubmittedDraft(submitted); }, 800);
        clearInterval(iv);
      } else if (tries >= 24) {
        clearInterval(iv); // ~6s elapsed: treat as failed, keep the draft
      }
    }, 250);
  }

  // The comment editor is the only Comentario form with a <textarea> (login/settings
  // forms have none, so they're ignored). Capture the text being submitted up front.
  document.addEventListener('submit', function (e) {
    var form = e.target;
    if (!form || !form.closest || !form.closest('.comentario-root')) return;
    var ta = form.querySelector('textarea');
    if (!ta) return;
    clearDraftOnSuccess(form, ta.value);
  }, true);

  /* ---- 3. Anonymous-commenting status + sign-out in the profile bar ---- */

  var SETTINGS_KEY = 'comentario_settings';

  // The anon name if we're in unregistered-commenting mode, else null.
  function getAnonName() {
    try {
      var s = JSON.parse(localStorage.getItem(SETTINGS_KEY) || '{}');
      return s && s.unregisteredCommenting ? (s.unregisteredName || 'Anonymous') : null;
    } catch (e) { return null; }
  }

  function signOutAnon() {
    try {
      var s = JSON.parse(localStorage.getItem(SETTINGS_KEY) || '{}');
      s.unregisteredCommenting = false;
      delete s.unregisteredName;
      localStorage.setItem(SETTINGS_KEY, JSON.stringify(s));
    } catch (e) { /* ignore */ }
    // Reload so Comentario re-reads the (now cleared) state and shows "Sign in" again
    // and prompts to log in on the next comment.
    location.reload();
  }

  // Idempotent: only mutates when the rendered state differs from the desired one, so
  // it's safe to call repeatedly from the observer below without looping.
  function applyAnonStatus() {
    var bar = document.querySelector('.comentario-profile-bar');
    if (!bar) return;
    var name = getAnonName();
    var isAnon = name !== null;

    if (bar.classList.contains('cmntr-anon-mode') !== isAnon) {
      bar.classList.toggle('cmntr-anon-mode', isAnon); // CSS hides "Sign in" when set
    }

    var status = bar.querySelector('.cmntr-anon-status');
    if (!isAnon) { if (status) status.remove(); return; }

    if (!status) {
      status = document.createElement('div');
      status.className = 'cmntr-anon-status';
      var nameEl = document.createElement('span');
      nameEl.className = 'cmntr-anon-name';
      var out = document.createElement('button');
      out.type = 'button';
      out.className = 'cmntr-anon-signout';
      out.textContent = 'Sign out';
      out.addEventListener('click', signOutAnon);
      status.appendChild(nameEl);
      status.appendChild(out);
      bar.appendChild(status);
    }
    var current = status.querySelector('.cmntr-anon-name');
    if (current.textContent !== name) current.textContent = name;
  }

  // Comentario rebuilds the profile bar on (re-)render, so re-apply on any change.
  var applyScheduled = false;
  function scheduleApply() {
    if (applyScheduled) return;
    applyScheduled = true;
    requestAnimationFrame(function () { applyScheduled = false; applyAnonStatus(); });
  }

  whenRootReady(function (root) {
    new MutationObserver(scheduleApply).observe(root, { childList: true, subtree: true });
    applyAnonStatus();
  });

  /* ---- 4. Collapsed-editor refocus ----
     Comentario's "Add a comment" host expands on focus, but after Cancel it stays
     focused while collapsed - so clicking it again fires no focus event and won't
     re-open (only clicking away then back does). If the collapsed host is clicked
     while it's already the focused element, blur+refocus it to re-fire the focus
     event so it re-opens. (Detected by the placeholder being present = collapsed.) */
  document.addEventListener('click', function (e) {
    var host = e.target.closest && e.target.closest('.comentario-add-comment-host');
    if (!host) return;
    if (document.activeElement === host &&
        host.querySelector('.comentario-add-comment-placeholder')) {
      host.blur();
      host.focus();
    }
  });

  /* ---- 5. Login dialog: relabel the email field's placeholder ---- */
  (function () {
    function find(node, sel) {
      return node.matches && node.matches(sel) ? node
        : (node.querySelector && node.querySelector(sel));
    }

    function apply(node) {
      if (node.nodeType !== 1) return;
      var email = find(node, '#comentario-login-form input[name="email"]');
      if (email && email.placeholder !== 'Email') email.placeholder = 'Email';

      var row = find(node, '.comentario-oauth-buttons');
      if (row) {
        Array.prototype.forEach.call(row.querySelectorAll('.comentario-btn'), function (btn) {
          var slug = (btn.textContent || '').trim().toLowerCase().replace(/[^a-z0-9]+/g, '-');
          if (slug) btn.classList.add('cmntr-idp-' + slug);
        });
      }
    }

    // Observe the widget root, not the whole document - the dialog always
    // mounts inside .comentario-root (every dialog override in comentario.css
    // is scoped through it), and a document-wide subtree observer would fire
    // for lightbox insertions, the share live-region, and every other page
    // mutation for the life of the page.
    whenRootReady(function (root) {
      apply(root);
      new MutationObserver(function (mutations) {
        for (var i = 0; i < mutations.length; i++) {
          var added = mutations[i].addedNodes;
          for (var j = 0; j < added.length; j++) apply(added[j]);
        }
      }).observe(root, { childList: true, subtree: true });
    });
  })();

  /* ---- 6. Pre-open the OAuth popup so Safari doesn't block it ----
     A popup only survives Safari's blocker if window.open() runs synchronously
     inside the user's click. So on a provider button click (capture phase, ahead
     of Comentario's own handler) open a blank window right away, then shim
     window.open(): when Comentario later asks for its auth URL, navigate our
     window there and hand it back instead of opening a new one. Comentario then
     polls that handle for closure exactly as it would its own. The shim is
     one-shot and self-removing; any other window.open() call passes straight
     through. This mirrors the fix that would go upstream (open first, fetch the
     token second) without carrying a fork. */
  (function () {
    var FEATURES = 'popup,width=800,height=600'; // same as Comentario's own
    var nativeOpen = window.open;
    var pending = null;   // blank popup waiting for Comentario's window.open()
    var timer = null;

    function unshim() {
      if (window.open === shimmedOpen) window.open = nativeOpen;
      clearTimeout(timer);
      timer = null;
    }

    // Give up on the pre-opened window: close it so a blank popup isn't left behind.
    function abandon() {
      if (pending && !pending.closed) pending.close();
      pending = null;
      unshim();
    }

    function shimmedOpen(url) {
      var p = pending;
      if (p && !p.closed && /\/api\/oauth\//.test(String(url))) {
        pending = null;
        unshim();
        p.location.href = url;
        return p;
      }
      return nativeOpen.apply(window, arguments);
    }

    document.addEventListener('click', function (e) {
      var btn = e.target.closest && e.target.closest('.comentario-oauth-buttons .comentario-btn');
      if (!btn) return;
      abandon(); // stale leftover from an earlier attempt, if any
      pending = nativeOpen.call(window, 'about:blank', '_blank', FEATURES);
      if (!pending) return; // blocked even now (popups fully disabled): leave Comentario to its own dialog
      window.open = shimmedOpen;
      // If Comentario never asks for the window (token fetch failed, etc.), don't
      // leave a blank one open forever.
      timer = setTimeout(abandon, 20000);
    }, true);
  })();

  /* ---- 7. Arriving at #comments: bring the first comment into view ---- */

  (function () {
    if (location.hash !== '#comments') return;

    // Any input of the visitor's own means they've taken over; never fight it.
    // (Not a scroll listener: the browser's own jump to #comments fires those.)
    var userMoved = false;
    var INPUTS = ['wheel', 'touchstart', 'keydown', 'mousedown'];
    function onInput() { userMoved = true; stop(); }
    INPUTS.forEach(function (type) {
      window.addEventListener(type, onInput, { passive: true, once: true });
    });

    var observer = null;
    var timer = null;
    var done = false;
    function stop() {
      done = true;
      if (observer) observer.disconnect();
      clearTimeout(timer);
      INPUTS.forEach(function (type) { window.removeEventListener(type, onInput); });
    }

    // Scroll only as far as it takes to show the whole first comment, with a
    // little room beneath it - not pull it to the top. A comment taller than
    // the screen stops with its top just under the sticky nav (html's
    // scroll-padding-top).
    var ROOM_BELOW = 24;
    var NAV_CLEARANCE = 100;
    function scrollToFirst(card) {
      stop();
      if (userMoved) return;
      // Just the comment itself (header, text, toolbar): a card also wraps its
      // whole reply chain in .comentario-card-children, which we don't chase.
      var self = card.querySelector('.comentario-card-self') || card;
      var rect = self.getBoundingClientRect();
      var distance = Math.min(rect.bottom + ROOM_BELOW - window.innerHeight,
                              rect.top - NAV_CLEARANCE);
      if (distance <= 0) return; // already on screen
      var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      if (reduce) { window.scrollBy(0, distance); return; }
      glide(distance);
    }

    // The browser's smooth scroll has a fixed, quick duration and curve, so
    // animate by hand: a quintic ease-out (fast start, long gentle settle, close
    // to an iOS scroll view decelerating). Longer trips take a little longer,
    // within 900-1600ms: the curve covers most of the distance early, so the
    // tail is what reads as the slow settle. Any wheel, touch or key input
    // cancels it on the spot.
    function glide(distance) {
      var startY = window.scrollY;
      var duration = Math.max(900, Math.min(1600, 800 + distance));
      var startTime = null;
      var cancelled = false;
      function cancel() { cancelled = true; }
      var CANCELS = ['wheel', 'touchstart', 'keydown', 'mousedown'];
      CANCELS.forEach(function (type) {
        window.addEventListener(type, cancel, { passive: true, once: true });
      });
      function frame(now) {
        if (cancelled) return;
        if (startTime === null) startTime = now;
        var t = Math.min(1, (now - startTime) / duration);
        var eased = 1 - Math.pow(1 - t, 5);
        window.scrollTo(0, startY + distance * eased);
        if (t < 1) {
          requestAnimationFrame(frame);
        } else {
          CANCELS.forEach(function (type) { window.removeEventListener(type, cancel); });
        }
      }
      requestAnimationFrame(frame);
    }

    // Watch the <comentario-comments> host, not .comentario-root: the widget
    // re-renders its root once the page's data arrives.
    function check() {
      if (done) return;
      var card = widget.querySelector('.comentario-card');
      if (card) scrollToFirst(card);
    }
    check();
    if (!done) {
      observer = new MutationObserver(check);
      observer.observe(widget, { childList: true, subtree: true });
      // Comments arrive with the widget's first load; don't watch forever.
      timer = setTimeout(stop, 15000);
    }
  })();
})();
