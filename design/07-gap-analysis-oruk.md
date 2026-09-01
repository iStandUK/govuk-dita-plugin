# 07 — Gap analysis: Open Referral UK DITA corpus

**Date:** 2026-09-01 · **Status:** Complete; two residual items tracked as issues

## Scope and method

The corpus is the shared OneDrive directory `iStandUK/OpenReferral UK/DITA` — the Open
Referral UK (HSDS) data-standard documentation. The goal set for the plugin: **cover every
aspect of DITA this directory uses.**

Method: a full sweep of all **1,465 DITA files** (no sampling — every file was fetched and
DOM-parsed via the SharePoint API, aggregating element, attribute, and doctype usage), followed
by an **empirical rebuild** of each idiom found, using a purpose-built miniature fixture
([fixtures/oruk-mini](../fixtures/oruk-mini/)) run through `dita -f govuk` on DITA-OT 4.4.1.
"Verified" below means observed working in that build, not inferred.

## Corpus profile

| Location | Files | Content |
|---|---|---|
| root | 498 topics + 2 bookmaps + 1 key map + 32 SVG | item/table topics, `DT-*` data types, `E-*` stubs, publication maps |
| `element/` | 454 topics | one topic per schema element |
| `properties/` | 454 topics | one stub topic per property |
| `class/` | 45 topics | class topics with SVG diagrams |
| `dataTypes/` | 11 topics | data-type reference tables |
| `image/`, `images/` | 32 SVG each | class/item diagrams |

**Documents:** every topic uses the generic **Topic DTD** (no concept/task/reference shells);
publications are **2 bookmaps** (`booktitle` + `booktitlealt` abstract, `bookmeta`
author/rights, `frontmatter/booklists/toc`, `chapter`) plus **1 key-definition map** with
**530 `keydef`s**, pulled in via `mapref` with `processing-role="resource-only"`.

**Element inventory (aggregate counts):** `topic` 1,462 · `title` 2,330 · `shortdesc` 1,462 ·
`body` 1,462 · `p` 1,362 · `section` 297 · `b` 297 · `xref` **4,095 (all via `@keyref`)** ·
CALS `table` 506 (`entry` 8,745; **column spans** `@namest`/`@nameend` 361; `@frame` on all) ·
`fig` 64 · **`svg-container`/`svgref` 64** (SVG domain; some `svgref` by `@keyref`) ·
`topicref` 914 (**`@toc="no"` on most children**, `@navtitle` 88, **`@chunk="to-content"`**
32) · `keydef` 530.

**Not used anywhere:** lists (`ul`/`ol`/`sl`/`dl`), `note`, `codeblock`/`codeph`,
`simpletable`, `image`, task markup, glossary markup, `indexterm`, related-links/reltables,
`conref`, DITAVAL files, key scopes, footnotes. Sparse attribute use: `@audience` and
`@xml:lang` on 67 elements.

## Feature disposition

| Corpus feature | Status |
|---|---|
| Generic Topic DTD | ✅ **Verified** — all rendering is `@class`-based, shell-independent |
| `title`/`shortdesc`/`body`/`section`/`p`/`b` | ✅ Covered by PoC, verified |
| CALS tables (`thead`/`tbody`/`colspec`) | ✅ Covered by PoC (`govuk-table`), verified |
| Column spans (`@namest`/`@nameend`) | ✅ **Verified** — emerge as `@colspan` + `@headers`, styled cells intact |
| `@frame` on tables | ✅ Renders; GOV.UK table styling is uniform regardless of frame (accepted) |
| `xref` via `@keyref` (4,095) | ✅ **Verified** — keys resolve, link text auto-pulled, `govuk-link` applied |
| Key map: 530 `keydef` + resource-only `mapref` | ✅ **Verified** — inherited preprocessing |
| **Bookmap** structures | ✅ Builds and navigates. Masthead title bug **fixed** (F1); GOV.UK home page renders `booktitlealt` abstract and `bookmeta` attribution (F5 — **#8 closed**) |
| `chunk="to-content"` | ✅ **Verified** — children merge into the parent page with correctly demoted headings (`h2` + anchor ids); sidebar links to `page#anchor` |
| `@toc="no"` / `@navtitle` | ✅ **Verified** — hidden from the sidebar; navtitles honoured |
| SVG domain: `svgref` by `@href` **and** `@keyref` | ✅ **Verified** — renders as `<img src>`, SVG assets copied to output. Spurious `govuk-link` class **fixed** (F2) |
| `fig` + `title` captions | ✅ Styled captions; `svgref` images carry an accessible name derived from the figure title (F3 — **#10 closed**) |
| `xref` by key **to a chunked-away topic** | ⚠️ Upstream DITA-OT limitation observed (F4) — **issue #11** |
| `@audience`/`@xml:lang` pass-through | ✅ Inherited; DITAVAL filtering available if ever needed |
| Scale: 1,462 topics, 530 keys, ~90 nav-visible entries | ✅ Within the full-tree sidebar's comfort zone (the `toc="no"` idiom keeps the tree small) |

Features the plugin offers that this corpus doesn't need (glossary, index, notes, lists, code)
are unaffected and remain for the ContSys-style publications.

## Findings

**F1 — Bookmap masthead title (fixed).** Bookmap normalisation folds `mainbooktitle` *and*
`booktitlealt` into the map title; the masthead rendered "ORUK Mini TestA long abstract
paragraph…". ORUK's real `booktitlealt` is a full paragraph, so every page header would have
carried the abstract. The service-name derivation now prefers `mainbooktitle` when present.

**F2 — `svgref` styled as a link (fixed).** `svgref` specialises `xref`, so the typography
mapping put `govuk-link` on generated `<img>` elements. The mapping now excludes
`svg-d/svgref`.

**F3 — Figure captions unstyled (resolved via #10).** 64 diagrams rendered as
`figure`/`figcaption` with default browser styling and no accessible name on the image.
Captions now use GOV.UK-consistent typography and each `svgref` image derives its `alt` from
the enclosing figure title (empty when caption-less).

**F4 — Keys targeting chunked-away topics (characterised against the real corpus).** When a
`keydef` targets a topic that `chunk="to-content"` merges into another page, DITA-OT 4.4.1
fails to resolve references through that key and emits anchors pointing at **temp-file hash
names that don't exist in the output** — broken links, not dropped ones. Verified 2026-09-01
by building the real corpus:

- **Combined-schemas bookmap** (the chunked one): 287 `DOTX031E` errors ↦ **287 broken links
  on 11 of 73 pages**; 828 related `DOTX023W`/`DOTX027W` warnings; build exits 0.
- **Control with plain `-f html5`: byte-identical error set** — the behaviour is upstream
  DITA-OT preprocessing, entirely plugin-independent.
- **International bookmap** (same content, no chunking): **0 errors, 0 warnings, 486 pages**
  — completely clean under the plugin.

The minimal reproduction is an xref by key to a chunked child (see
`fixtures/oruk-mini/chapter.dita`, which deliberately avoids it for CI). Issue #11 holds the
findings and the upstream-report decision; the practical authoring workaround for the
combined publication is to key chunked children as `parent.dita#child-id` fragments (or to
generate a per-publication key map) so keys survive chunking.

**F5 — Home page (resolved via #8).** The bookmap cover (`index.html`) was the known unstyled
page. A GOV.UK cover stylesheet now renders the title, the `booktitlealt` abstract as the
lead, `bookmeta` attribution, and a styled contents tree, sharing the site's assets and
template furniture.

## Fixture

[fixtures/oruk-mini](../fixtures/oruk-mini/) reproduces every idiom: bookmap + key map +
resource-only mapref, keyref-only topicrefs and xrefs, `chunk="to-content"` with `toc="no"`
children, CALS spans with `@frame`, and `svg-container`/`svgref` by href and by keyref. CI
builds it alongside the PoC fixture and asserts the F1/F2 fixes.

## Conclusion

With F1, F2, F3, and F5 fixed in the plugin, **every DITA construct the ORUK directory uses
works verified**, with one residual item tracked: #11, characterising the upstream
chunk+keyref behaviour against the real corpus. No new architecture was required: the corpus
stays entirely within the extend-html5 design, and its heaviest demands — key resolution at
scale, chunking, the SVG domain — are carried by inherited DITA-OT processing exactly as the
architecture intended.
