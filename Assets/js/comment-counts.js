/* comment-counts.js
 *
 * Fills the home feed's comment-count badges without loading the Comentario
 * widget. comentario.js (~28 KB compressed) asks for each <comentario-count>
 * separately - 20 requests for a ten-post feed - while its counts endpoint
 * takes every path at once. This makes that one request and renders the result
 * the way the widget would, honouring each element's suffix / placeholder /
 * zero-text / error-text attributes. Post pages still load the full widget.
 *
 * Same output as comentario.js + comentario-tweaks.js section 1: badges get
 * .has-count once a non-zero count shows (site.css reveals and animates it), and
 * the end-of-article " comments" suffix reads "1 comment" for a single one.
 * Re-check after Comentario upgrades: this depends on the embed counts API
 * (POST /api/embed/comments/counts {host, paths} -> {commentCounts: {path: n}},
 * zero counts omitted).
 */
(function () {
  'use strict';

  var API = 'https://comments.tim.dev/api/embed/comments/counts';
  var counts = document.querySelectorAll('comentario-count[path]');
  if (!counts.length || !window.fetch) return;

  function render(el, text) {
    if (el.closest('.post-link') && text === '1 comments') text = '1 comment';
    el.textContent = text;
    // Only the badges toggle .has-count (the end-of-article links always show
    // their label); `text` is blank there unless a real count came back.
    if (!el.closest('.post-link')) el.classList.toggle('has-count', text !== '');
  }

  function attr(el, name) { return el.getAttribute(name) || ''; }

  Array.prototype.forEach.call(counts, function (el) { render(el, attr(el, 'placeholder')); });

  var paths = [];
  Array.prototype.forEach.call(counts, function (el) {
    var path = el.getAttribute('path');
    if (paths.indexOf(path) === -1) paths.push(path);
  });

  fetch(API, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ host: location.host, paths: paths })
  })
    .then(function (response) {
      if (!response.ok) throw new Error('counts ' + response.status);
      return response.json();
    })
    .then(function (data) {
      var map = (data && data.commentCounts) || {};
      Array.prototype.forEach.call(counts, function (el) {
        var n = map[el.getAttribute('path')] || 0;
        render(el, n > 0 ? n + attr(el, 'suffix') : attr(el, 'zero-text'));
      });
    })
    .catch(function () {
      Array.prototype.forEach.call(counts, function (el) { render(el, attr(el, 'error-text')); });
    });
})();
