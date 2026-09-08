/*
 * This file is part of the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 *
 * Search page (FR-S2): mounts the Pagefind UI on #app-search. The ranking
 * options and the "unavailable" text arrive as data attributes written by the
 * build, so the page carries no variable inline script (#79) and a strict
 * Content-Security-Policy can apply (#82).
 */
(function () {
  'use strict';
  function init() {
    var el = document.getElementById('app-search');
    if (!el) return;
    if (!window.PagefindUI) {
      el.textContent = el.getAttribute('data-unavailable') || 'Search is not available in this build.';
      return;
    }
    var options = { element: '#app-search', showSubResults: true };
    var ranking = el.getAttribute('data-ranking');
    if (ranking) {
      try { options.ranking = JSON.parse(ranking); } catch (e) { /* Pagefind's defaults apply */ }
    }
    new window.PagefindUI(options);
    var q = new URLSearchParams(window.location.search).get('q');
    if (q) {
      window.requestAnimationFrame(function () {
        var input = el.querySelector('input');
        if (input) {
          input.value = q;
          input.dispatchEvent(new Event('input', { bubbles: true }));
        }
      });
    }
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
