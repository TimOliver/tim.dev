/* comentario-tweaks.js
 *
 * ALL client-side behaviour for the embedded Comentario widget lives here. (All
 * visual styling lives in Assets/css/comentario.css; this file is only for things
 * CSS can't do.) Loaded only on pages with Comentario elements: post pages
 * (<comentario-comments>) and the home feed (<comentario-count> badges).
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
 *    further comments with the same name and no dialog — with no visual cue and no
 *    way out. When in that mode we replace the profile-bar "Sign in" button with the
 *    name + a "Sign out" control that clears the mode.
 *
 * 4. Collapsed-editor refocus: after Cancel the collapsed host keeps focus, so
 *    clicking it again fires no focus event and it won't re-expand — blur+refocus
 *    to re-fire it.
 *
 * 5. Login dialog (created on demand): relabel the email field's placeholder to
 *    "Email". (The sign-up button needs no relabel — comentario.css hides its text
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
 *    falls into its "Popup blocked" / Retry dialog — whose Retry reuses the same
 *    one-time token and fails with "Token is missing or invalid" once the user has
 *    allowed the blocked window and signed in through it. We open a blank popup
 *    synchronously in the click instead and hand it to Comentario when it asks.
 */
(function () {
  'use strict';

  /* ---- 1. Comment-count badges (home feed + article heading) ----
     Comentario keeps the <comentario-count> element in place even at zero, so
     read the rendered text and toggle .has-count as it changes. */
  (function () {
    var counts = document.querySelectorAll('.post-badge comentario-count, .post-comments-count');
    if (!counts.length) return;

    function sync(el) {
      el.classList.toggle('has-count', (el.textContent || '').trim() !== '');
    }

    Array.prototype.forEach.call(counts, function (el) {
      sync(el);  // in case the count resolved before this script ran
      new MutationObserver(function () {
        sync(el);
      }).observe(el, { childList: true, characterData: true, subtree: true });
    });
  })();

  /* ---- 1b. Singular comment count on the end-of-article links ----
     Those links use a fixed " comments" suffix, so a single comment renders
     "1 comments"; rewrite it to "1 comment". (The badge and heading counts show a
     bare number, so they need no fix.) */
  (function () {
    var links = document.querySelectorAll('.post-link comentario-count');
    if (!links.length) return;
    function fix(el) {
      if ((el.textContent || '').trim() === '1 comments') el.textContent = '1 comment';
    }
    Array.prototype.forEach.call(links, function (el) {
      fix(el);  // in case the count resolved before this script ran
      new MutationObserver(function () { fix(el); })
        .observe(el, { childList: true, characterData: true, subtree: true });
    });
  })();

  // Everything below operates on the live comments widget — bail on pages that
  // only have count badges (the home feed) so no listeners/observers/polls are
  // left running against a widget that can never appear.
  if (!document.querySelector('comentario-comments')) return;

  /* ---- 2. Clear the editor draft after a successful post ---- */

  var DRAFT_KEY = 'comentario_editor';

  // Comentario keys drafts by a server-assigned page id (from the page-load response),
  // NOT the URL path — so we can't match by path. Instead delete the draft whose
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
    } catch (e) { /* localStorage unavailable or malformed — leave it alone */ }
  }

  // On a successful post Comentario empties or removes the editor's textarea; on a
  // validation/network failure the text stays put. Poll to tell them apart, then clear
  // the draft (twice — the second pass beats Comentario's debounced re-save).
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

  // The widget element exists on this page (checked above), so this poll always
  // terminates — comentario.js creates .comentario-root inside it on render.
  (function watchRoot() {
    var root = document.querySelector('.comentario-root');
    if (!root) { setTimeout(watchRoot, 150); return; }
    new MutationObserver(scheduleApply).observe(root, { childList: true, subtree: true });
    applyAnonStatus();
  })();

  /* ---- 4. Collapsed-editor refocus ----
     Comentario's "Add a comment" host expands on focus, but after Cancel it stays
     focused while collapsed — so clicking it again fires no focus event and won't
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

    // Observe the widget root, not the whole document — the dialog always
    // mounts inside .comentario-root (every dialog override in comentario.css
    // is scoped through it), and a document-wide subtree observer would fire
    // for lightbox insertions, the share live-region, and every other page
    // mutation for the life of the page.
    (function watchDialog() {
      var root = document.querySelector('.comentario-root');
      if (!root) { setTimeout(watchDialog, 150); return; }
      new MutationObserver(function (mutations) {
        for (var i = 0; i < mutations.length; i++) {
          var added = mutations[i].addedNodes;
          for (var j = 0; j < added.length; j++) apply(added[j]);
        }
      }).observe(root, { childList: true, subtree: true });
    })();
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
})();
