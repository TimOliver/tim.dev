/* comentario-tweaks.js
 *
 * Client-side behaviour fixes for the embedded Comentario widget. (All visual styling
 * lives in Assets/css/comentario.css; this file is only for things CSS can't do.)
 *
 * 1. Clear the editor draft after a successful post. Comentario saves the editor text
 *    as a per-page draft (localStorage "comentario_editor") and writes the
 *    just-submitted text back as a draft on a successful post, so it reappears the
 *    next time you open the box. We delete the page's draft once a submit succeeds.
 *
 * 2. Anonymous-commenting status + sign-out. After commenting anonymously, Comentario
 *    quietly enters "unregistered commenting" mode (comentario_settings) and posts
 *    further comments with the same name and no dialog — with no visual cue and no
 *    way out. When in that mode we replace the profile-bar "Sign in" button with the
 *    name + a "Sign out" control that clears the mode.
 */
(function () {
  'use strict';

  /* ---- 1. Clear the editor draft after a successful post ---- */

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

  /* ---- 2. Anonymous-commenting status + sign-out in the profile bar ---- */

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

  (function watchRoot() {
    var root = document.querySelector('.comentario-root');
    if (!root) { setTimeout(watchRoot, 150); return; }
    new MutationObserver(scheduleApply).observe(root, { childList: true, subtree: true });
    applyAnonStatus();
  })();
})();
