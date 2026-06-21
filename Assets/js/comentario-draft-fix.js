/* comentario-draft-fix.js
 *
 * Comentario saves the comment editor's text as a per-page draft in localStorage
 * ("comentario_editor" -> { drafts: { [pageId]: text } }) and only deletes the entry
 * when the editor is empty. On a successful post it removes the editor without first
 * emptying it, so the just-submitted text gets written back as a draft and reappears
 * the next time you open the box.
 *
 * Fix: when a comment-editor <form> is submitted AND the post succeeds (its textarea
 * clears or the editor is removed), delete the current page's draft entry. Login and
 * settings forms are ignored (they have no <textarea>), and failed/validation submits
 * keep their text, so their draft is left intact.
 */
(function () {
  var KEY = 'comentario_editor';

  function removeDraft() {
    try {
      var raw = localStorage.getItem(KEY);
      if (!raw) return;
      var data = JSON.parse(raw);
      if (!data || !data.drafts) return;
      // Comentario keys drafts by pageId = the page path; match the current path
      // with or without a trailing slash.
      var p = location.pathname;
      var noSlash = p.replace(/\/$/, '');
      var variants = [p, noSlash, noSlash + '/'];
      var changed = false;
      Object.keys(data.drafts).forEach(function (k) {
        if (variants.indexOf(k) !== -1) { delete data.drafts[k]; changed = true; }
      });
      if (changed) localStorage.setItem(KEY, JSON.stringify(data));
    } catch (e) { /* localStorage unavailable or malformed — leave it alone */ }
  }

  // On a successful post Comentario empties or removes the editor's textarea; on a
  // validation/network failure the text stays put. Poll briefly to tell them apart.
  function clearDraftOnSuccess(form) {
    var tries = 0;
    var iv = setInterval(function () {
      tries++;
      var ta = form.isConnected ? form.querySelector('textarea') : null;
      if (!ta || !ta.value.trim()) {
        removeDraft();
        setTimeout(removeDraft, 800); // beat any pending debounced re-save
        clearInterval(iv);
      } else if (tries >= 24) {
        clearInterval(iv); // ~6s elapsed: treat as failed, keep the draft
      }
    }, 250);
  }

  document.addEventListener('submit', function (e) {
    var form = e.target;
    if (!form || !form.closest || !form.closest('.comentario-root')) return;
    // Only the comment editor carries a <textarea>; skip login/settings forms.
    if (!form.querySelector('textarea')) return;
    clearDraftOnSuccess(form);
  }, true);
})();
