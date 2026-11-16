/* comentario-cookie.js
 *
 * Keeps Comentario from storing a cookie for readers who aren't signed in.
 *
 * On startup the widget reads its session cookie (comentario_commenter_session)
 * and, when there isn't one, writes an all-zero "anonymous" placeholder token
 * for 30 days. A missing cookie and the placeholder mean the same thing to it
 * (no signed-in user; no auth header is sent), so the placeholder only puts an
 * information-free cookie on tim.dev that every later request carries.
 *
 * This wraps document.cookie so a write of the placeholder becomes a delete:
 * readers get no cookie, signing in still stores the real token, and signing
 * out (which also writes the placeholder) still clears it. It must load BEFORE
 * comentario.js, which can write the cookie as soon as it starts. Re-check
 * after Comentario upgrades: it relies on the cookie name and the all-"A"
 * placeholder value (AnonymousUserSessionToken in comentario.js).
 */
(function () {
  'use strict';

  var NAME = 'comentario_commenter_session';
  var PLACEHOLDER = new RegExp('^\\s*' + NAME + '=A+(;|$)');
  var EXPIRE = NAME + '=; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Path=/; SameSite=Strict';
  var native = Object.getOwnPropertyDescriptor(Document.prototype, 'cookie');
  if (!native || !native.get || !native.set) return;

  try {
    Object.defineProperty(document, 'cookie', {
      configurable: true,
      get: function () { return native.get.call(document); },
      set: function (value) {
        native.set.call(document, PLACEHOLDER.test(String(value)) ? EXPIRE : value);
      }
    });
  } catch (e) {
    return; // Can't wrap it here: leave Comentario's default behaviour alone.
  }

  // Returning readers may still have the placeholder from before this guard.
  if (/(^|;\s*)comentario_commenter_session=A+(;|$)/.test(native.get.call(document))) {
    native.set.call(document, EXPIRE);
  }
})();
