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
| **Bookmap** structures | ✅ Builds and navigates. Masthead title bug **fixed** (F1). Home-page styling remains issue #8 (extended for `booktitlealt`, F5) |
| `chunk="to-content"` | ✅ **Verified** — children merge into the parent page with correctly demoted headings (`h2` + anchor ids); sidebar links to `page#anchor` |
| `@toc="no"` / `@navtitle` | ✅ **Verified** — hidden from the sidebar; navtitles honoured |
| SVG domain: `svgref` by `@href` **and** `@keyref` | ✅ **Verified** — renders as `<img src>`, SVG assets copied to output. Spurious `govuk-link` class **fixed** (F2) |
| `fig` + `title` captions | ⚠️ Renders (`figure`/`figcaption`) but unstyled — **issue #10** (F3) |
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

**F3 — Figure captions unstyled.** 64 diagrams render as `figure`/`figcaption` with default
browser styling only. Needs GOV.UK-consistent caption/figure treatment (FR-R5) — issue #10.

**F4 — Keys targeting chunked-away topics.** When a `keydef` targets a topic that
`chunk="to-content"` merges into another page, DITA-OT 4.4.1 reports `DOTX031E`/missing-file
errors and drops the link (build still completes, exit 0). This is upstream behaviour, not
plugin behaviour; ORUK's combined-schemas bookmap chunks exactly such targets. Issue #11
verifies against the real corpus and decides whether to report upstream.

**F5 — Home page.** The bookmap cover (`index.html`) is the already-known unstyled page
(issue #8); for ORUK it should also present the `booktitlealt` abstract and `bookmeta`
attribution.

## Fixture

[fixtures/oruk-mini](../fixtures/oruk-mini/) reproduces every idiom: bookmap + key map +
resource-only mapref, keyref-only topicrefs and xrefs, `chunk="to-content"` with `toc="no"`
children, CALS spans with `@frame`, and `svg-container`/`svgref` by href and by keyref. CI
builds it alongside the PoC fixture and asserts the F1/F2 fixes.

## Conclusion

With F1 and F2 fixed in the plugin, **every DITA construct the ORUK directory uses either
works verified or is tracked** (#8 home page, #10 figure styling, #11 upstream chunk+key
verification). No new architecture is required: the corpus stays entirely within the
extend-html5 design, and its heaviest demands — key resolution at scale, chunking, the SVG
domain — are carried by inherited DITA-OT processing exactly as the architecture intended.
