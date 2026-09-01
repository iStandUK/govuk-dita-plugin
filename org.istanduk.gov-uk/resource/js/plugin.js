/*
 * This file is part of the govuk-dita-plugin project.
 * Copyright 2026 iStandUK. Licensed under the Apache License, Version 2.0.
 *
 * Progressive enhancement for the sidebar navigation (FR-N2, FR-N4):
 * - small viewports: collapse the navigation behind a Menu button
 * - larger viewports: collapse branches that do not contain the current page
 * Without JavaScript none of this runs and the full tree stays visible.
 */
(function () {
  'use strict';
  var sidebar = document.querySelector('.app-sidebar');
  var nav = document.querySelector('.app-sidebar__nav');
  if (!sidebar || !nav) return;

  document.body.className += ' app-js-nav';

  // Mobile: Menu toggle
  var toggle = document.createElement('button');
  toggle.type = 'button';
  toggle.className = 'app-sidebar__toggle';
  toggle.setAttribute('aria-expanded', 'false');
  toggle.textContent = 'Menu';
  sidebar.insertBefore(toggle, sidebar.firstChild);
  toggle.addEventListener('click', function () {
    var open = sidebar.classList.toggle('app-sidebar--open');
    toggle.setAttribute('aria-expanded', String(open));
  });

  // Mark the current page when the build could not (chunked targets carry a
  // fragment, e.g. page.html#topic, so the static comparison misses them)
  if (!nav.querySelector('.active')) {
    var here = location.pathname.split('/').pop() || 'index.html';
    var links = nav.querySelectorAll('a[href]');
    for (var j = 0; j < links.length; j++) {
      var page = links[j].getAttribute('href').split('#')[0].split('/').pop();
      if (page === here) {
        links[j].parentNode.classList.add('active');
        break;
      }
    }
  }

  // Branch expand/collapse; ancestors of the current page start open
  var items = nav.querySelectorAll('li');
  for (var i = 0; i < items.length; i++) {
    var li = items[i];
    var sub = li.querySelector(':scope > ul');
    if (!sub || sub.children.length === 0) continue;
    var open = li.classList.contains('active') || !!li.querySelector('.active');
    var caret = document.createElement('button');
    caret.type = 'button';
    caret.className = 'app-nav__caret';
    caret.setAttribute('aria-expanded', String(open));
    caret.setAttribute('aria-label', 'Toggle section');
    li.insertBefore(caret, li.firstChild);
    li.classList.add('app-nav__branch');
    if (!open) li.classList.add('app-nav__branch--closed');
    caret.addEventListener('click', function () {
      var branch = this.parentNode;
      var closed = branch.classList.toggle('app-nav__branch--closed');
      this.setAttribute('aria-expanded', String(!closed));
    });
  }
})();
