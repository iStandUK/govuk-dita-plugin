# 13 — Page numbers in print: the options, and a two-product shape

**Status:** decided 2026-09-07 as **D-23** — option A first, then option G; the generator's name, repository and code licence still to choose (no code yet) · **Question:** how do the print outputs get page numbers in the contents, index and cross-references — and footnotes at the page foot, running heads, a tagged PDF — and should that capability ship inside the plugin or as a second product on a common core? · **Feeds:** FR-P3 in [02](02-requirements.md); an amendment to [D-20](05-decision-log.md); the release process (D-22).

## 1. Answer in brief

Page numbers need a paginating layout engine; nothing in the plugin can compute them from markup alone. There are only three places that engine can run: on the reader's machine (a browser, with or without a pagination polyfill), on the publisher's machine as a tool the plugin *calls*, or on the publisher's machine as a tool the plugin *bundles*. 1.0 covers the first as far as browsers allow (page numbers in the margins, none in the contents). The recommendation is to add the second now — a small `govuk.pdf.command` hook in the core, proven in CI with an open-source formatter — and to deliver the third as a **second product**, `org.istanduk.gov-uk.pdf`, built on the unchanged core: it carries the pure-Java engine, the fonts and the PDF/UA validation, runs the engine in its own process so its libraries never meet the toolkit's, and is installed by name with the core as a dependency. The core stays a quarter of a megabyte, Apache-licensed and Node-free; publishers who want page-numbered PDFs opt in with one install. This amends D-20's "bundled in the plugin" to "bundled in a companion plugin" — or, in the variant the sponsor is inclined to (option G, Section 6a), to "a separately licensed generator that the plugin merely calls": the same engine and fonts, shipped as their own product under their own licence, joined to the plugin only through the option-A command mechanism, exactly as Pagefind is today.

## 2. Where we are

FR-P1 and FR-P2 shipped in 1.0.0: every page prints on A4 (or the chosen size) with `n / N` in the margin, and `print.html` is the whole publication in one file with a hyperlinked contents list, per-topic endnotes and every id preserved. What a browser cannot do — and no shipping browser does — is `target-counter()` (the page a link points at, for the contents, the index and "see page N"), `string-set` running heads, and `float: footnote`. So the contents and index carry links, footnotes sit at the end of their topic, and the PDF a browser saves is tagged the way the browser chooses. The toolkit itself already carries a PDF stack for `pdf2`: FOP 2.11 with PDFBox 3.0.5, FontBox 3.0.5 and Batik 1.19 on the classpath of `org.dita.pdf2.fop`.

## 3. What "page numbers" actually needs

A CSS Paged Media engine that implements, over the existing print document: `target-counter(attr(href url), page)` for contents, index and cross-references; `string-set` and margin-box `string()` for running heads; `float: footnote` and the footnote area; named pages (`page: landscape` for wide tables); `bookmark-level` for the outline; `break-*` and widows/orphans (already in `print.css`); repeated `thead`; and, for a compliant government PDF, PDF/UA tagging with embedded TrueType fonts. Everything else — the document, the ids, the paper parameters — exists.

## 3a. What the reader sees: page references on cross-references

Both the external-formatter route (A) and the companion engine (D) give page numbers on cross-references, because both consume the same print document, in which every cross-reference to an included topic is already an in-document anchor — `<a class="xref govuk-link" href="#install">Installing the plugin</a>`. The number is then generated content in the stylesheet, not a change to the HTML:

```css
.app-print a.xref[href^="#"]::after {
  content: " (" attr(data-page-label) " " target-counter(attr(href url), page) ")";
}
```

which renders **"Installing the plugin (page 13)"**. The label is not a literal in the CSS: the print document's fix-up pass stamps `data-page-label` on each in-document link from the string registry, so the wording is localisable (NFR-I1). The same mechanism numbers the contents (`leader('.') target-counter(…)` where the formatter has `leader()`; a right-aligned number otherwise) and the index entries (`target-counter` in place of the link), and `target-text(attr(href url))` can add the target's title where a link's text does not already carry it.

Three limits are the vocabulary's, not the plugin's: "above"/"below" cannot be expressed — CSS has no way to compare the target's page with the current one, so the reference reads "(page 13)" whether the target is behind or ahead; a target on the *same* page is still numbered; and only targets inside the PDF get a number — a link to a page the print document excludes (`toc="no"`) stays a link to the website, which the Design System's print rules already annotate with its address. Browsers, which do not implement `target-counter`, treat the whole `content` declaration as invalid and print nothing extra, so the rule can live in the core's `print.css` from option A onwards without affecting the browser route; the companion adds its own richer rules in `pdf.css`. The open-source formatter used to prove option A documents exactly this pattern (`target-counter`, `target-text`, `leader()`); the pure-Java engine implements `target-text` and gained `target-counter` in 2026, to be confirmed in the spike.

## 4. Options

| | Option | Where the engine runs | Gives | Costs |
|---|---|---|---|---|
| **A** | **Call an external formatter** — `govuk.pdf.command` in the core: the build passes `print.html`, the paper parameters and an output path to a command the publisher names (an open-source Python formatter, a Chromium-based paginator, a commercial formatter) | publisher's machine, publisher's tool | page numbers, footnotes, running heads, PDF/UA — whatever the tool does; a PDF file beside `print.html` | the publisher installs a tool; quality and determinism are the tool's; the plugin only documents one open-source path and proves it in CI (that tool installs with `pip`, in CI only — no publisher dependency) |
| **B** | **Paginate in the reader's browser** — ship a pagination polyfill (MIT, roughly a megabyte of JavaScript) with `print.html`, opt-in | reader's browser | page numbers in the contents and cross-references when the reader prints; no build tool | JavaScript work and memory on every reader's machine (heavy at the 500-topic ceiling); the polyfill restructures the DOM into page boxes, which assistive technology sees; no PDF artefact; not deterministic; a stop-gap, never the answer for a published PDF |
| **C** | **Bundle the engine in the plugin** — D-20 as written: the pure-Java engine, its PDF library and a font family inside `org.istanduk.gov-uk` | publisher's machine, inside the toolkit | build-time PDF for everyone with one install | the plugin grows from ~250 KB to several megabytes for every publisher, including the ten-thousand-topic ones who will never make a PDF; an LGPL library and font licences inside an Apache-2.0 plugin; the engine's PDF library must coexist with the toolkit's PDFBox 3.0.5 — on a shared classpath one version wins and `pdf2` or the engine breaks, so the engine must run in a forked JVM anyway; one release cadence for two very different things |
| **D** | **Two products on a common core** — `org.istanduk.gov-uk` unchanged; a companion `org.istanduk.gov-uk.pdf` that `require`s it, defines transtype `govuk-pdf` extending `govuk`, and adds the engine step | publisher's machine, in a forked process the companion starts | the same build-time PDF as C, for publishers who ask for it | a second distributable to release (same repository, second plugin directory, second registry entry with `deps` on the core); a versioned interface — the print document and `print.css` — between the two; a compatibility row in CI |
| **G** | **A separately licensed generator, joined by the command mechanism** — the engine, fonts and PDF/UA validation as their own product (own repository, own licence, own releases, not a DITA-OT plugin); the core detects it like Pagefind (`govuk.pdf=auto` when the generator is on the PATH or at `govuk.pdf.cmd`) or reaches it through `govuk.pdf.command` | publisher's machine, a separate process by construction | the same build-time PDF as C and D, for publishers who install the generator | two installs and two version lines (the contract marker keeps them honest); no `--format=govuk-pdf`; the plugin's CI must fetch the generator's release by checksum to test the join; documentation in two places |
| E | Download the engine on demand at build time | — | small core | network at build time and undefined offline behaviour — rejected, as the plugin promises neither |
| F | XSL-FO through `pdf2`, styled to look like GOV.UK | toolkit | page numbers today | a second stylesheet family to keep in step — rejected in [10](10-pdf-css.md) |

## 5. Comparison

| Criterion | A external | B reader-side | C bundled in core | D companion product | G separate generator |
|---|---|---|---|---|
| Page numbers in contents, index, cross-references | yes (tool) | yes, at print time | yes | yes | yes |
| Footnotes at the page foot, running heads | yes (tool) | partly | yes | yes | yes |
| PDF/UA, validated | tool-dependent | no (browser's PDF) | yes, veraPDF in CI | yes, veraPDF in the companion's CI | yes, veraPDF in the generator's CI |
| Publisher dependency | a formatter | none | none | one more `dita install` | one download (Java already present) |
| Reader cost | none | JavaScript on every print | none | none | none |
| Core plugin size / licences | unchanged | +1 MB JS in output | ×20–40, LGPL + fonts inside | unchanged | unchanged; LGPL never inside any DITA-OT plugin |
| Classpath risk with the toolkit's PDFBox 3.0.5 | none | none | real unless forked | isolated by design (forked JVM, own classpath) | none — a separate program |
| Determinism (FR-B6) | tool-dependent | n/a | engine gives fixed dates; byte-identical achievable | same | same (fixed dates a generator option) |
| Release cadence | core | core | engine churn hits the core | companion tracks the engine; core untouched | generator tracks the engine on its own channel; core untouched |
| Effort | **S** (3–4 days with CI proof) | S–M | **L** (3–5 weeks after a spike) | **L** + ~1 week of product plumbing | **L** (the engine work) + ~1 week for a repository, release and detection; less DITA-OT plumbing than D |

## 6. Recommendation

1. **Now, in the core (1.0.x): option A.** `govuk.pdf.command` — a command template with placeholders for input, output and paper parameters, run after `govuk.print`, `no` by default, failures reported as a warning with the tool's output attached (the site is still complete without the PDF). CI installs an open-source formatter (Python, `pip`, pinned — a CI dependency, not a publisher one) and asserts that the resulting PDF has page numbers in the contents and more pages than the browser smoke, which also proves the print document paginates correctly under a full CSS Paged Media implementation before any engine is chosen. The core's `print.css` gains the page-reference rules of Section 3a and the fix-up pass stamps the localised label. Manual: one section in *Printing and PDF* with a generic command example and what page references look like.
2. **1.1: option D for the engine.** Amend D-20: the engine, fonts and PDF/UA validation ship in `org.istanduk.gov-uk.pdf`, built from the same repository (a second plugin directory), released by the same tag-triggered workflow as a second asset, listed in the registry with `deps: org.istanduk.gov-uk >= <core minor>`. Its transtype `govuk-pdf` extends `govuk`, so `--format=govuk-pdf` produces site and PDF in one build; the engine runs in a forked JVM with the companion's own classpath, never on the toolkit's. The design-10 spike applies unchanged, with three criteria added: coexistence with PDFBox 3.0.5 on the host toolkit (forked); the interface contract below; a byte-identical double build across both products.
3. **Option B only on request** — a publisher who wants page numbers in a browser print today and accepts the cost — and never as a default.

Why D over C: the core's publishers include very large corpora that will never produce a PDF and should not carry an engine and fonts for it; the LGPL library and font licences are cleaner in a product whose purpose they serve; the engine releases far more often than the core and its updates should not churn the site plugin; and the forked-process isolation that C needs anyway makes the split nearly free. Why A first: it delivers page numbers this quarter for anyone with a formatter, at small cost, and it validates the print document against a real paginator before the engine work starts.

## 6a. Option G in detail: a separately licensed generator, joined by the command mechanism

**Shape.** A second product — working name to be chosen; not a DITA-OT plugin — in its own repository under the organisation, with its own licence, `SECURITY.md`, Gitflow, tag-triggered release with attestation, and its own CI (the fork's weekly releases, veraPDF for PDF/UA, a byte-identical double run). Its release is a zip: `bin/` launcher scripts, `lib/` with the engine and its dependencies as **separate, unmodified jars** (the LGPL replaceability clause satisfied by construction), the OFL font family, `THIRD-PARTY-NOTICES`, the LGPL and OFL texts, and the engine's source jars attached to the same release. Java is the only runtime, and DITA-OT already requires it. The generator is useful on its own for any paged XHTML, not only the plugin's.

**Join.** The plugin gains what option A gives it and nothing more: `govuk.pdf` = `auto` (default: produce a PDF when the generator is found on the PATH or at `govuk.pdf.cmd`, otherwise build the site without one and say so in the log) | `yes` (fail early if it is missing, as `govuk.search=yes` does for Pagefind) | `no`; `govuk.pdf.command` for any other formatter. The plugin passes `print.html`, the output path and the paper parameters; the generator checks the `govuk-print-contract` marker and refuses a document it does not understand, naming the plugin version to install. Neither product carries the other's code, fonts or licences.

**Licensing.** The plugin stays Apache-2.0 with MIT govuk-frontend and no GPL-family component anywhere in its distribution or its registry entry. The generator's own code can be Apache-2.0 with the LGPL library and OFL fonts alongside under their notices, or LGPL-2.1 outright if a single licence is preferred for the whole product — a choice for its repository, invisible to the plugin. Organisations that cannot accept LGPL install the plugin alone and lose only PDFs.

**What it costs against D.** Two installs and two version lines instead of one `dita install` that brings both; no `--format=govuk-pdf`; the plugin's CI fetches the generator's release by checksum to prove the join, as it fetches Nu and Pagefind. What it saves: all the DITA-OT plumbing of a companion plugin (transtype, `require`, registry entry with `deps`, the forked-JVM launcher inside Ant), the licensing question inside the registry, and any coupling of the generator's release rhythm to the toolkit's plugin model. D remains available later as a thin wrapper that installs and configures the generator, should one-command installation prove to matter.

**Sequence.** The same spike (design 10 §9 plus the contract marker), then the generator repository with the CLI from the spike's launcher, the plugin's `govuk.pdf` detection and `govuk.pdf.command`, and a fixture in each CI that builds the manual to a page-numbered, veraPDF-clean PDF.

## 7. The interface between the two products

The companion depends only on what the core already publishes:

- **`print.html`** — XHTML, the `app-print-cover` / `app-print-contents` / `app-print-chapter` / `app-print-topic` / `app-print-part` structure, stable ids, `<link rel="stylesheet">` order, `lang`; the companion adds its own `pdf.css` after `print.css` (footnote floats, `target-counter` leaders, running heads, `@font-face` for the bundled family, named pages) and never rewrites the document.
- **`print.css`** and the paper parameters (`govuk.pdf.paper`, `govuk.pdf.orientation`, already in the core; `govuk.pdf.margins`, `govuk.pdf.sides`, `govuk.pdf.toc.depth`, `govuk.pdf.ua`, `govuk.pdf.fonts` in the companion).
- A **contract marker**: the core writes `<meta name="govuk-print-contract" content="1">` into `print.html`; the companion refuses a document with a contract it does not know, with a plain message naming the core version to install. The contract number changes only when the structure the companion relies on changes, independently of semver on either product.
- **Versions**: the companion's registry entry requires the core minor it was tested against; both are released from the same tag when the contract moves, otherwise independently.

## 8. Decisions needed (OQ-14)

1. Amend D-20 to a two-product shape: the companion DITA-OT plugin (D) or the separately licensed generator joined by the command mechanism (G, the sponsor's current inclination), or keep the engine inside the core.
2. Ship option A in a 1.0.x point release ahead of the engine work (recommended).
3. One repository with two plugin directories (recommended) or a second repository.
4. Version lockstep (same number for both) or independent numbers with a `deps` range.
5. Whether option B is offered at all.
6. For G: the generator's name, its repository and its licence (Apache-2.0 code with LGPL/OFL notices, or LGPL-2.1 throughout); whether `govuk.pdf=auto` detects it like Pagefind.

## 9. Sources checked (September 2026)

The installed DITA-OT 4.4.1 (`org.dita.pdf2.fop/lib`: FOP 2.11, PDFBox and FontBox 3.0.5, Batik 1.19); the Open HTML to PDF community fork release list (1.1.85, 1 September 2026); the DITA-OT registry (plugin dependencies expressed as `deps`, for example a theme plugin requiring two others); the pagination polyfill's package metadata (MIT, 0.4.x); an open-source Python CSS Paged Media formatter (69.0); browser support for `@page` margin boxes and page counters (Baseline) against the absence of `target-counter`, `string-set` and footnotes; [10-pdf-css.md](10-pdf-css.md) and D-20.
