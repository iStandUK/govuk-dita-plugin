# 10 — PDF output through CSS: feasibility and scale

**Status:** agreed 2026-09-06 as **D-20**; the 1.0 half — FR-P1 and FR-P2 — implemented in [#63](https://github.com/iStandUK/govuk-dita-plugin/issues/63) (`print.css`, `map2govuk-print.xsl`, `print-document.xsl`); FR-P3 remains the 1.1 epic (FR-P1–P3 in [02](02-requirements.md)) · **Date:** 2026-09-06 · **Question:** can the plugin produce PDF
documents from the same DITA, styled with CSS rather than XSL-FO, on common UK, European and
international paper sizes — and is that feasible for the 1.0 release? · **Feeds:** a decision on
1.0 scope (D-15), the roadmap item R3, and a possible 1.1 epic.

## 1. Answer in brief

**Feasible, not for 1.0.** A CSS-based PDF route is technically sound on this plugin's own
foundations: a pure-Java, LGPL engine exists that renders CSS Paged Media well enough for a
book-style PDF (page sizes, running headers, page numbers, tables of contents with page numbers,
footnotes, repeated table headers, tagged PDF/UA output), it fits the "DITA-OT plus Java, no
Node" rule (D-12), and govuk-frontend already ships 152 print rules that do most of the
typography. But a publication-grade PDF is a **second rendering target**, not a stylesheet: a
merged print document, cover and contents, page furniture, fonts that can legally be embedded,
accessibility validation, and a new dependency to track. That is six to nine weeks of focused
work plus decisions on fonts and licensing, against a 1.0 whose remaining scope is trials and
the registry listing.

Recommendation: ship the **print stylesheet** (roadmap R3, a few days) in 1.0, so every page
prints and "saves as PDF" cleanly from a browser on A4 or Letter with page numbers; ship the
**print document** — the single merged file every engine needs — in 1.0 as well (Section 9a,
agreed 2026-09-06), so whole publications print from a browser and render through any CSS
formatter a publisher already has; and take the **build-time CSS PDF engine** to 1.1 through a
one-week spike whose acceptance criteria are set out in Section 9.

## 2. Where we start from

- The design records **no PDF output** as a non-goal ([01](01-context.md), goal list and
  parity table) and a **print stylesheet for single topics** as roadmap item R3
  ([02](02-requirements.md)). Nothing in the plugin today is print-aware: `plugin.css` has no
  `@media print` block.
- The vendored **govuk-frontend 6.5.0 CSS carries 152 `@media print` rules**: point-based type
  sizes for every heading and body style (76 rules), black text, sans-serif fallbacks, and link
  URLs printed after link text. The Design System's components therefore already know how to
  print; what is missing is the plugin's page chrome (masthead, sidebar, pagination, footer),
  which is laid out with flexbox (17 declarations in `plugin.css`) and has no print rules.
- DITA-OT 4.4.1 ships **three XSL-FO PDF routes** (`pdf2` with Apache FOP 2.11, plus adapters
  for two commercial formatters) and the **theme-driven PDF generator** `com.elovirta.pdf`
  0.8.0, whose JSON theme sets page size from an enumeration (A3, A4, A5, Executive, JIS B5,
  Tabloid, Legal, Letter, PA4), orientation, margins, header and footer content, fonts and
  colours. Both default to **US Letter**; `pdf2` sets the page in an attribute set
  (`page-width` 215.9 mm) that only a customisation plugin can change, and its published
  parameters carry no paper size at all. Neither route produces GOV.UK Design System
  components; both produce a competent generic book.
- GOV.UK's guidance for publishers is HTML first: *"Publish in HTML format wherever possible"*,
  PDF *"as a last resort"* with an accessible HTML version alongside, and any PDF must meet the
  same accessibility bar (headings, reading order, alternative text, language, tables with
  headers, 12-point sans-serif minimum). The Public Sector Bodies Accessibility Regulations
  2018 apply to published documents. For this plugin a PDF is a **secondary rendition** of the
  same content, and an inaccessible one would be a liability, not a feature.

## 3. What "a publication PDF" has to do

The requirements a standards or guidance publication puts on a PDF, drawn from the corpora the
plugin has been trialled on (ORUK bookmaps, the NHS Data Dictionary, this manual):

| ID | Requirement | Notes |
|---|---|---|
| P-1 | Paper size and orientation chosen by parameter: A4 default; A5, A3, Letter, Legal at least; landscape for wide tables | Section 4 |
| P-2 | Margins and mirrored (left/right) margins for double-sided printing | `@page :left` / `:right` |
| P-3 | Cover page from the bookmap: title, subtitle, author/organisation, date, edition | the cover data the home page already uses |
| P-4 | Table of contents **with page numbers**, to a configurable depth | needs `target-counter()` |
| P-5 | Running headers and footers: publication or chapter title, page numbers, "Page n of N" | margin boxes, `counter(page)`, `counter(pages)` |
| P-6 | Chapter and appendix starts on a new page; headings kept with following text; widows and orphans controlled | `break-before`, `break-after: avoid`, `widows`/`orphans` |
| P-7 | Tables: header rows repeated across pages; very wide tables on landscape pages | repeating `thead`, named pages |
| P-8 | Figures, inline SVG diagrams and MathML rendered; captions kept with figures | engine plugins |
| P-9 | Footnotes at the foot of the page (DITA `fn`) | `float: footnote` or engine equivalent |
| P-10 | Cross-references that say "on page n"; index and glossary entries with page numbers | `target-counter()` again |
| P-11 | PDF bookmarks (outline) from the map hierarchy; internal links live | |
| P-12 | **Tagged, accessible PDF (PDF/UA)**: heading structure, reading order, alt text, table headers, document language and title, all fonts embedded | GOV.UK guidance; regulations |
| P-13 | Branding modes carried through: neutral by default; NHS and official identities only under the same warnings; **no restricted font embedded unless the publisher supplies it** | design constraint C1 |
| P-14 | Deterministic output for unchanged source (FR-B6) | PDF dates and producer strings |
| P-15 | Node-free build; any external tool optional with graceful absence (as Pagefind, FR-S4) | D-12 |
| P-16 | CI verification: PDF/A or PDF/UA validation, page count, link check | veraPDF is open source and scriptable |

## 4. Paper sizes

CSS Paged Media names these sizes (`@page { size: … }`), and every candidate engine and modern
browser accepts them:

| Region | Keyword | Dimensions | Use |
|---|---|---|---|
| ISO 216 (UK, Europe, most of the world) | `A4` | 210 × 297 mm | default for UK public-sector documents |
| | `A5` | 148 × 210 mm | booklets, pocket guides |
| | `A3` | 297 × 420 mm | fold-out tables and diagrams; landscape for wide tables |
| ISO 216 B series | `B5`, `B4` | 176 × 250 mm, 250 × 353 mm | books; rarely asked for in government |
| Japan | `JIS-B5`, `JIS-B4` | 182 × 257 mm, 257 × 364 mm | international completeness only |
| North America | `letter` | 8.5 × 11 in (215.9 × 279.4 mm) | the toolkit's current default |
| | `legal` | 8.5 × 14 in | |
| | `ledger` (Tabloid) | 11 × 17 in | wide material |
| Custom | `<width> <height>` | any lengths | e.g. `PA4` 210 × 280 mm, the transatlantic compromise |

Proposed parameters, in the plugin's existing style: `govuk.pdf.paper` (`A4` default, any
keyword above, or two lengths), `govuk.pdf.orientation` (`portrait` default, `landscape`),
`govuk.pdf.margins` (a named preset such as `standard` 20 mm / 25 mm inner for binding, or
explicit lengths), and `govuk.pdf.sides` (`single` default, `double` for mirrored margins).
Wide tables and landscape diagrams get a named page of their own (`landscape` on the same paper)
selected by `outputclass="landscape"` on the table or figure, following the `search-*` token
convention. One publication, one paper size; mixed sizes are a print-shop matter, not a build
parameter.

## 5. Options

Five ways to get from the plugin's DITA to a PDF. "Paged media" below means the features P-4,
P-5, P-9 and P-10 depend on: margin boxes, page counters, running elements, named pages,
`target-counter`, footnotes.

### A. Print stylesheet only (roadmap R3)

Add `@media print` rules to `plugin.css`: hide masthead, sidebar, search, pagination and footer
chrome; single column; `@page` with `size: A4` and margins; page numbers in margin boxes;
break control on headings, tables and figures. Readers print or save a page as PDF from their
browser. Since December 2024 `@page size` and the margin boxes are Baseline across Chrome,
Firefox and Safari, so page numbers in headers and footers work everywhere; `target-counter`
and footnotes do not exist in any browser, so there is no contents page with page numbers and
no whole-publication PDF: one page per topic (or per merged chunk).

Cost: **S** (days). Risk: none to the build; no new dependency. Value: high for the common case
of printing one topic, and it is the foundation every other option reuses.

### B. Build-time PDF with a Java CSS engine, bundled

Generate one print document per publication from the merged map (Section 6), style it with the
print CSS, and render it inside the build with **Open HTML to PDF** (community fork of
`openhtmltopdf`; LGPL 2.1; pure Java 8+, PDFBox-based). What it supports, per its
documentation and tracker: `@page` sizes and lengths, margin boxes, `counter(page)` and
`counter(pages)`, running elements, named pages, page-break properties, repeating table
headers, `target-counter` for tables of contents (a page-straddling fix landed July 2026),
footnotes (since 2021), PDF/A and **PDF/UA tagged output** (fonts must be embedded TrueType;
OpenType CFF is not supported), SVG through a Batik adapter, MathML through a plugin. It does
not run JavaScript and does not lay out flexbox or grid, which is why the print document must
be assembled by the plugin rather than fed the site's pages. Health: releases 1.1.78 to 1.1.85
between 24 August and 1 September 2026, 50 commits in the last 90 days, 44 open issues; the
work is concentrated in a few maintainers, so longevity is a risk to assess in the spike. Size:
about 1.3 MB of engine jars plus 1.6 MB of FontBox (PDFBox and Batik are already in DITA-OT),
plus an embeddable font family; the plugin zip would grow from 0.2 MB to roughly 4 to 5 MB.

Cost: **L** (Section 8). Fits D-12. This is the only option that is both CSS-based and
Node-free.

### C. Build-time PDF with an optional external CSS engine

Same print document and CSS as B, rendered by an external tool the build looks for and skips
gracefully when absent, exactly as Pagefind (FR-S4). Candidates: **WeasyPrint** (Python and
Pango; BSD; full paged media including `target-counter`, `string-set`, footnotes and named
pages; PDF/A and PDF/UA output, unvalidated by the tool; automatic bookmarks; system fonts; no
right-to-left text); **Vivliostyle CLI** (Node and headless Chromium; AGPL-3.0 core; full paged
media); **Paged.js** (Node and Chromium; MIT; polyfills paged media in the browser — its
restructuring of the DOM into page boxes is a known question mark for tagged output);
**headless Chromium** alone (page sizes A0 to A6, Letter, Legal, Tabloid, Ledger; header and
footer templates with page numbers; `tagged` and `outline` options; but no `target-counter` or
footnotes, so no contents page numbers).

Cost: **M** for the print document and CSS (shared with B) plus **S** per engine adapter.
Precedent exists (Pagefind, Playwright in CI), but a PDF that appears only on machines with the
right Python or Node stack is a weaker promise than search that appears only with Pagefind.

### D. The incumbent XSL-FO routes, styled to look like GOV.UK

Use `pdf2` with a customisation plugin, or the bundled theme generator with a JSON theme
(fonts, colours, page size from its enumeration, headers, footers). Java-only, mature, tagged
PDF/UA-1 via FOP with `fox:alt-text` and language set. Not CSS, and not the Design System: notes
become generic notes, not inset text; tables lose the GOV.UK table styling; keeping two
stylesheet families (XSLT-to-HTML and XSLT-to-FO) in step is the maintenance burden the CSS
route is meant to avoid. The theme generator's schema also carries a defect (its orientation
enumeration offers `portrait` and `letter`), a reminder that it is a 0.8 release.

Cost: **M** for a "looks GOV.UK-ish" theme; ongoing double maintenance. Worth documenting now
as the interim whole-publication route; not worth adopting as the design.

### E. Commercial CSS formatters, bring-your-own

Prince, Antenna House and the CSS engine bundled in a commercial DITA editor implement CSS
Paged Media most completely, including PDF/UA. An open-source plugin cannot bundle them, but
the print document and CSS from B or C would work with them through a `govuk.pdf.command`
parameter. Zero cost beyond documentation once B or C exists; no part of the plugin's own
promise.

### Comparison

| | A print CSS | B Java engine | C external engine | D XSL-FO | E commercial |
|---|---|---|---|---|---|
| CSS-based | yes | yes | yes | no | yes |
| Node-free build (D-12) | yes | yes | build yes, PDF needs the tool | yes | yes |
| Licence to bundle | n/a | LGPL 2.1 (usable with Apache-2.0, notice required) | not bundled | Apache-2.0 (in DITA-OT) | not bundled |
| Whole-publication PDF | no | yes | yes | yes | yes |
| Contents with page numbers (P-4, P-10) | no | yes | WeasyPrint, Vivliostyle, Paged.js yes; Chromium no | yes | yes |
| Footnotes (P-9) | no | yes | WeasyPrint, Vivliostyle yes; Paged.js experimental; Chromium no | yes | yes |
| Tagged PDF/UA (P-12) | browser's own | yes, fonts embedded | WeasyPrint and Chromium yes (unvalidated) | yes (FOP) | yes |
| GOV.UK component fidelity | full | high (same CSS) | high (same CSS) | low | high |
| SVG / MathML | browser | plugins | engine-dependent | FOP | yes |
| New dependency risk | none | one library, active fork | tool availability per machine | none | licence cost |
| Effort | S | L | M + S per engine | M | S after B/C |

## 6. How B would be built (architecture sketch)

Everything before rendering is already there; the new work is one document, one stylesheet
and one step.

1. **A print document.** A second map-level transform beside `map2govuk-cover.xsl` walks the
   merged map in reading order and emits **one XHTML file**: cover (from the bookmap's
   `mainbooktitle`, `booktitlealt`, `bookmeta`), contents list with links, then every topic's
   body in map order with headings demoted by depth, chapter and appendix boundaries marked,
   glossary and index as final parts, all ids preserved for `target-counter`. The topic
   rendering reuses the existing `blocks.xsl` and `foreign.xsl` templates; only the page chrome
   is absent. Serialised as XHTML because the engine parses XML. This is the same "merged
   publication" idea `pdf2` implements with its topic-merge step, done in HTML.
2. **A print stylesheet.** `print.css` loads govuk-frontend's print rules and adds the paged
   rules: `@page` size and margins from the parameters; `:first` for the cover; `:left` and
   `:right` mirrored margins; margin boxes for running titles and "Page n of N"; a `landscape`
   named page; break control; `thead` repetition; footnote area; the contents page's
   `target-counter` leaders. The same file serves option A's browser printing, minus the
   features browsers lack, so A and B share one stylesheet.
3. **A render step.** An Ant target after the site build invokes the engine through a small
   Java entry point (registered with `dita.conductor.lib.import`, the mechanism the plugin's
   Ant already uses for its own jars), with SVG and MathML adapters, PDF/UA on, document title
   and language from the map, creation and modification dates fixed from a build parameter so
   output stays byte-identical (P-14), and the paper parameters passed as CSS variables.
4. **Fonts.** The engine embeds only fonts it is given, as TrueType. Neutral mode needs a
   bundled, redistributable family (an SIL Open Font Licence sans with a matching monospace;
   candidates to compare in the spike for legibility at 12 pt and for metric similarity to the
   web fallback stack). Official and NHS modes must **not** bundle GDS Transport or Frutiger;
   the publisher points `govuk.pdf.fonts` at their own licensed TrueType files, and the build
   falls back to the bundled family with a warning otherwise — the same posture as the web
   output (constraint C1, D-17).
5. **Verification.** CI builds the manual's PDF, checks page count and outline, runs the
   internal-link checker's PDF equivalent, and validates with veraPDF (open-source PDF/A and
   PDF/UA validator, Java, scriptable) so an accessibility regression fails the build as an axe
   violation does today.

Parameters: `govuk.pdf` (`no` default, `yes`), `govuk.pdf.paper`, `govuk.pdf.orientation`,
`govuk.pdf.margins`, `govuk.pdf.sides`, `govuk.pdf.fonts`, `govuk.pdf.toc.depth`,
`govuk.pdf.ua` (`yes` default), and for option E `govuk.pdf.command`. One PDF per publication,
written beside `index.html` and linked from the cover; publications of the NHS Data Dictionary's
size (10,000 topics) would set `govuk.pdf=no` or produce PDFs per part through submaps — a
10,000-page PDF is not a document anyone reads.

## 7. What the CSS route cannot do, or not yet

- **Flexbox and grid** are unavailable in the Java engine; the print document must be plain
  flow layout. Acceptable, since print has no sidebar, but any future component relying on
  flex (the summary list, the pagination) needs a print variant.
- **Right-to-left text** is limited in the Java engine and absent in WeasyPrint. The plugin's
  web output supports RTL (verified in the DITA 1.3 fixtures); the PDF would not, at first.
- **Fonts as OpenType CFF** are unsupported by the Java engine; TrueType only. Publisher-supplied
  brand fonts often come as CFF and would need conversion by the publisher.
- **Tagged-PDF quality** is asserted by engines and validated by veraPDF, but structure follows
  the HTML the plugin writes: heading levels, table header cells, alt text and language all have
  to be right in the print document, which is the same discipline the web output already meets.
- **Browsers** give page numbers but no contents page numbers or footnotes; option A remains
  single-topic printing, never a substitute for B.

## 8. Scale of the challenge

Indicative sizing for option B, one engineer familiar with the plugin, sizes as used elsewhere
in the design (S: up to a day, M: two to three days, L: a week or more):

| Workstream | Size | Notes |
|---|---|---|
| Print stylesheet (option A, shared) | S–M | reuse govuk-frontend print rules; chrome hidden; `@page`, breaks, margin boxes |
| Print document transform (merge, cover, contents, glossary, index, ids) | L | the largest piece; mirrors `pdf2`'s topic-merge in HTML |
| Engine integration (Ant target, Java entry point, SVG and MathML adapters, determinism) | M | |
| Page furniture: running heads, page numbers, mirrored margins, landscape pages | M | CSS, but every rule needs checking in the engine |
| Tables, figures, notes, code blocks, footnotes in paged layout | M | repeating heads, keeps, long-code wrapping |
| Contents, index and cross-reference page numbers | M | `target-counter`; index page-number lists |
| Fonts: selection, bundling, licence notice, publisher-supplied path, fallback warning | M | plus a decision |
| Accessibility: PDF/UA output, veraPDF in CI, alt text and language plumbing | M–L | the part most likely to surprise |
| Branding modes in print (neutral, iStandUK, NHS, official) | S–M | mastheads become cover and running-head treatments |
| Parameters, manual topics, design records | S–M | |
| **Total** | **6–9 weeks** | roughly the size of the v0.9 verification net (#35) and the branding variants (#47) together |

Option A alone is S–M and independent of everything else. Option D as a documented interim
route is S (write the manual page; the toolkit already does the work).

## 9. Recommendation and the spike

**For 1.0:** option A. Add the print stylesheet, document how to print or save a topic as PDF
on A4 or Letter from a browser, and document the toolkit's own `pdf2` and theme-generator
routes for a whole-publication PDF, with a worked theme that sets A4 and the publication's
fonts. This closes R3, costs days, adds no dependency, and keeps 1.0 on its current line:
trials, then the registry listing (#21).

**For 1.1:** option B, entered through a **one-week spike** with these acceptance criteria:

1. The manual (this bookmap) renders to a single A4 PDF through the Java engine from a
   hand-assembled print document: cover, contents with correct page numbers, running heads,
   "Page n of N", chapter breaks, one repeated-header table, one inline SVG, one footnote.
2. The same document renders on A5 and on Letter by changing only the paper parameter, and a
   wide table lands on a landscape page.
3. veraPDF reports PDF/UA-1 conformance with the bundled font family embedded; axe-equivalent
   structure (headings, table headers, alt text, language) is present in the tags.
4. Two identical builds produce byte-identical PDFs.
5. The engine's bookmark and metadata mechanisms, its `string-set` support for running chapter
   titles, and its behaviour on the ORUK bookmaps' 300-row tables are confirmed or ruled out.
6. Bus factor: the fork's maintainers, release process and issue response are assessed, and a
   fallback (option C with WeasyPrint through the same print document) is costed.

If the spike passes, the epic proceeds at the size in Section 8; if it fails on accessibility
or engine health, the same print document and CSS move to option C, which is why the document
and stylesheet are designed engine-neutral from the start.

## 9a. Revision: bring the print document into 1.0

Reviewing Section 9 with the sponsor (2026-09-06) settled that the **print document** — the
single merged XHTML file of Section 6, step 1 — belongs in 1.0 alongside the print stylesheet,
with only the engine step deferred to 1.1. The reasons:

- It is the L-sized workstream on which every engine option depends and which no engine
  changes. Built in 1.0, it lets the 1.1 spike start from the real document instead of a
  hand-assembled sample, and reduces the 1.1 residue to M-sized items: engine integration,
  fonts, PDF/UA validation, page-number features.
- It is useful on its own. Browsers print it whole, on A4 or Letter with running page numbers
  (margin boxes are Baseline); Chromium's print-to-PDF can add tags and an outline. A publisher
  who already has a CSS formatter can render a full PDF from it at 1.0 through a documented
  command (`govuk.pdf.command`, option E), with nothing bundled by the plugin.
- It is a deliverable in its own right: one self-contained page for offline reading, review
  circulation or archiving, which the site cannot offer today.

**What it is.** One XHTML document per publication, written beside `index.html` and linked
from the cover as "Whole publication (print version)": cover block from the bookmap
(`mainbooktitle`, `booktitlealt`, `bookmeta`); a hyperlinked contents list to a configurable
depth; every navigable topic in map reading order, rendered by the existing `blocks.xsl` and
`foreign.xsl` templates with headings demoted by map depth; chapter and appendix boundaries
marked for `break-before`; glossary and index as final parts, their entries linking to
anchors; no masthead, sidebar, search, pagination or footer chrome; `print.css` (the option A
stylesheet) plus a single-column screen layout so the file also reads on screen. Every topic
and element id is preserved exactly as on the site, so cross-references become in-document
anchors and the index resolves without page numbers.

**Limits at 1.0, stated plainly in the manual.** In a browser the contents list has no page
numbers, `fn` footnotes are rendered as endnotes at the end of their topic, and index and
glossary entries link rather than cite pages; all three become page-numbered under the 1.1
engine, from the same file. Tagged output in a browser is the browser's own.

**Guards.** `govuk.print` defaults to `no`; `govuk.print.max-topics` (default 500) skips the
document with a notice above the ceiling, since a 10,000-topic corpus is not one document —
such publications produce print documents per part through their submaps or not at all. The
print document carries no `data-pagefind-body`, so Pagefind never indexes it (the plugin scopes
indexing to that attribute, and a page without it is skipped), which stops it duplicating every
search result; it is excluded from the sitemap proposed in #60 by default. Heading depth: map
nesting beyond six levels keeps the visual style of level six with `aria-level` set correctly,
so the tag tree stays honest. Duplicate ids from `chunk` and `copy-to` topics are resolved the
way the site already resolves them (the html5 base's id rewriting), and CI asserts uniqueness.

**Verification in CI.** The manual's print document is built on every run: Nu, axe-core,
internal-link check (all anchors resolve within the file), the determinism double-build, and a
Chromium smoke through the Playwright already used for accessibility — print the document to
A4 with `tagged` and `outline`, assert a page count above one and a non-empty outline. That
smoke is CI-only evidence that the target works; it is not a build dependency.

**Sizing.** Print document transform **L** (the same item as in Section 8), print stylesheet
**S–M**, parameters, cover link, manual topic and CI **S–M**: about **two to three weeks**, on
top of a 1.0 whose remaining items are the live trials and the registry listing. The 1.1 engine
epic then needs roughly three to five weeks rather than six to nine.

**Requirement.** Add to [02](02-requirements.md) as FR-P1 (print stylesheet, R3 delivered) and
FR-P2 (print document), both 1.0, with FR-P3 (build-time PDF through a CSS engine) for 1.1.

## 10. Decisions taken (D-20, 2026-09-06)

All recorded in the [decision log](05-decision-log.md) as D-20:

- 1.0 takes the print stylesheet **and** the print document (Section 9a); the engine step is 1.1, entered through the Section 9 spike.
- A bundled SIL Open Font Licence TrueType family for neutral and iStandUK PDFs, chosen in the spike from Noto Sans, Public Sans and Source Sans 3 (each with a matching monospace) by legibility at 12 pt, coverage of Welsh and European diacritics, TrueType availability and size; its licence notice ships with it. Official and NHS PDFs embed only publisher-supplied fonts.
- Tagged PDF/UA on by default, with a documented opt-out, validated with veraPDF in CI.
- Default paper A4, with Letter and the other sizes one parameter away.
- One PDF per publication, linked from the cover and named after the map.

## 11. Sources checked (September 2026)

CSS Paged Media `size` keywords and Baseline status (MDN); `@page` margin boxes, named pages
and pseudo-classes (MDN); Open HTML to PDF community fork README, wiki (page features, fonts,
integration guide), release list and issue tracker; WeasyPrint 69 API reference; Paged.js and
Vivliostyle repositories; Playwright `page.pdf` reference; Apache FOP accessibility page;
veraPDF documentation; GOV.UK "Publishing accessible documents"; the installed DITA-OT 4.4.1
(`pdf2`, FOP 2.11, `com.elovirta.pdf` 0.8.0 and its theme schema); the vendored
govuk-frontend 6.5.0 stylesheet.
