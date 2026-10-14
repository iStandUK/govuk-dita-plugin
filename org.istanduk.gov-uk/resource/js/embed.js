/*
 * This file is part of the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 *
 * Embedded view (#201, D-28), linked only when govuk.embed=yes. A page shown
 * inside a frame and opened with ?embed=1 shows its content only: the class
 * set here hides the masthead, contents, pagination and footer (plugin.css).
 * Loaded in the head, before the page is drawn, so the furniture never
 * appears first. Links to other pages of the same site keep embed=1, so the
 * reader stays in the embedded view; anything else behaves as usual.
 * Opened at the top level, or without JavaScript, the page is shown in full.
 */
(function () {
  'use strict';
  var framed;
  try {
    framed = window.self !== window.top;
  } catch (e) {
    framed = true;
  }
  if (!framed || !window.URL || !window.URLSearchParams) return;
  if (new URLSearchParams(window.location.search).get('embed') !== '1') return;

  document.documentElement.className += ' app-embed';

  document.addEventListener('click', function (event) {
    if (event.defaultPrevented || event.button !== 0 ||
        event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    var link = event.target.closest ? event.target.closest('a') : null;
    if (!link || link.hasAttribute('download')) return;
    var target = link.getAttribute('target');
    if (target && target !== '_self') return;
    // an SVG link's href is an animated string; either kind may be relative
    var raw = typeof link.href === 'string' ? link.getAttribute('href') :
      (link.href && link.href.baseVal) || link.getAttribute('xlink:href');
    if (!raw) return;
    var url;
    try {
      url = new URL(raw, document.baseURI);
    } catch (e) {
      return;
    }
    if (url.origin !== window.location.origin) return;
    // a place on this page: no reload
    if (url.pathname === window.location.pathname && url.search === window.location.search && url.hash) return;
    url.searchParams.set('embed', '1');
    event.preventDefault();
    window.location.assign(url.href);
  });
})();
