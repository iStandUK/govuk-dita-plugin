# Spike — the DesignSystemPDF engine against the print document

**Status:** complete; outcome recorded as **D-25** (go) · **Date:** 2026-10-01 · **Issue:** [#109](https://github.com/iStandUK/govuk-dita-plugin/issues/109), epic [#105](https://github.com/iStandUK/govuk-dita-plugin/issues/105) · **Feeds:** the DesignSystemPDF product ([#110](https://github.com/iStandUK/govuk-dita-plugin/issues/110)–[#112](https://github.com/iStandUK/govuk-dita-plugin/issues/112)) and `govuk.pdf=auto` ([#113](https://github.com/iStandUK/govuk-dita-plugin/issues/113)) · **Criteria from:** [10](../10-pdf-css.md) §9, [13](../13-print-page-numbers.md) §6a and §7

## Question

Can a pure-Java CSS Paged Media engine turn the plugin's **unchanged** `print.html` into a page-numbered, footnoted, bookmarked, tagged PDF/UA file — on A4, A5 and Letter, byte-identical across runs, at the 500-topic ceiling, as a separate process beside the toolkit — and which open font family should ship with it?

## Answer

**Yes — go.** Every criterion is met with the Open HTML to PDF community fork at 1.1.87. The engine lacks three things the design assumed (`string-set`, `bookmark-level`, footnotes floated from somewhere other than where they stand); each is covered by preparing the parsed document **in memory** before layout, so the file on disk is never rewritten and nothing is added that the document does not already say. The bundled family is **Noto Sans with Noto Sans Mono**.

## What was run

The spike was run as the product's first working code, not a throwaway: a launcher, a document-preparation pass, a `pdf.css`, and the engine as unmodified jars, built with Maven and unpacked as the distribution would be. Inputs were the manual's `print.html` (23 topic files, built by the plugin at 1.0.1 with `govuk.print=yes`, contract 1), the `dita13-kitchen` fixture's print document, a 300-row table, and the manual's body repeated to 529 topics. Windows 11, Java 21, eight cores; veraPDF 1.30.2 (greenfield parser, from Maven Central) for PDF/UA-1.

| Component | Version | Licence |
|---|---|---|
| Open HTML to PDF (`io.github.openhtmltopdf`: core, pdfbox, svg-support, mathml-support) | 1.1.87 (26 September 2026) | LGPL-2.1 **or later** — the licence text in each jar reads "either version 2.1 of the License, or (at your option) any later version" |
| Apache PDFBox, FontBox, XmpBox | 3.0.7 | Apache-2.0 |
| Apache Batik (SVG) | 1.17 | Apache-2.0 |
| JEuclid (MathML) | 3.1.12 | Apache-2.0, with an older Apache-style notice |
| veraPDF validation model (test only, never distributed) | 1.30.2 | GPL-3.0-or-later / MPL-2.0 |

## Results against the criteria

| Criterion | Result |
|---|---|
| The manual renders from the unchanged `print.html` | ✅ 53 pages on A4 in 3.9 s; cover, contents, chapters, glossary, index |
| A4, A5 and Letter from the paper parameter | ✅ 53, 98 and 55 pages; also explicit lengths (`210mm 280mm`) |
| Page numbers in the contents (`target-counter`, `leader()`) | ✅ from the rules already in the core's `print.css` — no change to the document |
| Page numbers on cross-references — "Installing the plugin (page 5)" | ✅ with the localised `data-page-label` |
| Page numbers in the index | ✅ |
| Footnotes at the page foot | ✅ `float: footnote` and the `@footnote` area work; the body has to stand at its call (see below) |
| Running heads | ✅ publication title left, chapter title right, through running elements — `string-set` is **not** implemented |
| Named pages for wide tables | ✅ `page:` and a landscape `@page`; the measure needs help (see below) |
| Repeated table header rows; the 300-row table | ✅ `-fs-table-paginate`; 32 pages in 2.7 s, PDF/UA valid |
| Bookmarks | ✅ 104 outline entries for the manual, nested by heading level — from a `bookmarks` element, as `bookmark-level` is **not** implemented |
| Inline SVG and MathML | ✅ Batik and JEuclid drawers; text inside diagrams drawn from the bundled fonts |
| Tagged PDF/UA passing veraPDF | ✅ PDF/UA-1, 227,172 checks passed on A4; A5 and Letter and the landscape and double-sided variants pass too. Footnotes do not break conformance (the engine's own notes say they might) |
| Byte-identical output across two runs | ✅ with a fixed date and with none |
| Performance and memory at the ceiling | ✅ 529 topics → 1,065 pages in 30 s; peak live heap 459 MB — completes with `-Xmx512m`, fails at 384 MB. The manual peaks at 87 MB |
| The engine's PDFBox beside the toolkit's | ✅ the toolkit carries PDFBox and FontBox 3.0.5 for `pdf2`; the generator runs 3.0.7 in its own process with only its own `lib/` on the class path. A real `dita` build produced the PDF through `govuk.pdf.command` with the launcher on the `PATH` |
| The contract-marker check | ✅ contract `1` renders; contract `2` is refused with exit code 3 and a message naming what to install; a document with no marker renders as ordinary XHTML |
| The fork's licence | ✅ LGPL-2.1-or-later; shipped as separate unmodified jars with the source jars attached to each release (D-23) |

## What the engine does not do, and how the generator covers it

All of these happen on the parsed document in memory. The contract (design 13 §7: the generator "never rewrites the document") holds: `print.html` is read, never written.

| Gap | Cover |
|---|---|
| **No `string-set`.** Margin boxes can only show running *elements*. | The publication title and each chapter-level part's title are repeated as elements with `position: running()`; a page shows the first on it or the last before it. |
| **Footnotes float from where they stand.** The plugin writes each topic's footnotes as endnotes with a call in the text. | Each endnote body that has a call moves to the call and takes `float: footnote`; the author's own marker (number or callout) is kept on both, so the engine's generated call and marker are switched off. A footnote used only by reference has no call of its own and stays an endnote. |
| **No `bookmark-level`.** | The outline is built from the headings (h2 downwards, to `--toc-depth`) as the engine's `bookmarks` element. Headings without an id are given one in memory. |
| **Generic font names are looked up literally.** Nothing is embedded for `sans-serif`, `arial` or `monospace` unless a font is registered under that name, and PDF/UA forbids the built-in fonts. | The bundled faces are registered under their own names **and** under the generic and system names stylesheets ask for — the same fallback the web output makes — unless a publisher font claims the name first. A weight the alias lacks would be faked with a stroke, so every alias carries every face. |
| **Figure alternatives come only from `alt`.** Inline SVG carries `aria-label` or a `title`; MathML carries `alttext`. | Copied across to `alt` in memory. A figure with none is **reported** (warning), never given invented words — the PDF then fails PDF/UA, as it should. |
| **Every page is laid out to the first page's measure.** A landscape page is wider, but its content is not. | The turned measure is given to the `.landscape` element as a width, computed from the paper and margins. |
| **The page canvas colour of the Design System template prints.** | Set to white in `pdf.css`. |
| **Diagram and formula text is drawn with whatever fonts the machine has.** | The bundled fonts are registered for SVG and MathML too, so a diagram is the same on every machine. |
| **The clock is stamped into the file** (creation date, XMP, and the PDF library's file identifier). | The date is the one the caller gives (`--fixed-date`, or `SOURCE_DATE_EPOCH`) or is left out; the identifier is seeded from the source and the options. |

Browser-only CSS in govuk-frontend (flexbox, `box-shadow`, `:not()`, `max()`, media-query syntax the engine does not parse) produces some 730 parser reports for the manual and no visible defect: the print document is plain flow layout by design. They are shown only with `--verbose`.

## Limits that remain

- **Right-to-left and complex scripts.** The kitchen fixture's Arabic paragraph prints as replacement marks: the bundled family has no Arabic, and the engine's bidirectional support is an optional module that is not shipped. The generator **warns** (`DSPDF004W`) naming the characters. A publisher font supplied with `--fonts` gives glyphs; correct shaping is not promised.
- **MathML** renders small and needs `alttext` for PDF/UA.
- **PDF/UA-1 only.** PDF/A is not attempted (it needs a colour profile and a different metadata set); the engine supports it and it can be added.
- **One paper size per publication**, with landscape pages of the same paper for marked tables and figures.
- **Memory** grows with page count: half a gigabyte at the ceiling. Java's default limit (a quarter of the machine's memory) is enough on any build machine; an out-of-memory failure reports how to raise it.
- **TrueType only.** A publisher's OpenType CFF font is skipped with a warning (`DSPDF005W`).

## Fonts

Measured from the font files (FontBox) and by rendering the manual with each family. Arial is the web output's fallback in neutral mode and is the yardstick; it cannot be redistributed.

| | Public Sans 2.001 | **Noto Sans 2.015** | Source Sans 3.052 | Arial (yardstick) |
|---|---|---|---|---|
| x-height / em — legibility at 12 pt | 0.517 | **0.536** | 0.486 | 0.519 |
| Width of a sample line at 12 pt | 462 pt | 465 pt | 410 pt | 441 pt |
| Manual on A4 | 53 pages | 53 pages | 51 pages | — |
| Welsh (ŵ ŷ and the acute, grave and diaeresis sets) | 56 / 56 | **56 / 56** | 56 / 56 | 56 / 56 |
| Western, central and eastern European Latin | complete | **complete** | complete | complete |
| Irish and Gaelic, including dotted consonants | 24 / 38 | **38 / 38** | 38 / 38 | 38 / 38 |
| Greek and Cyrillic | none | **complete** | complete | complete |
| Arrows, mathematical operators, ticks | 11 / 29 | 1 / 29 (the monospace has 21) | 28 / 29 | 20 / 29 |
| TrueType outlines, static faces | yes | **yes, hinted** | yes | yes |
| Size, four faces | 0.34 MB | 2.5 MB | 1.5 MB | — |
| Matching monospace | none in the family | **Noto Sans Mono** (regular and bold, 1.2 MB, same vertical metrics) | Source Code Pro (four faces, 0.75 MB) | — |
| Licence | OFL-1.1 | **OFL-1.1** | OFL-1.1 | proprietary |

**Choice: Noto Sans with Noto Sans Mono.** Public Sans is the smallest and closest to the Design System's look, but it has no Greek or Cyrillic — two scripts of official European languages — no matching monospace, and no arrows. Source Sans 3 covers everything but sets visibly smaller at the same point size (x-height 0.486 against Arial's 0.519), which works against the 12-point minimum in the accessible-documents guidance. Noto Sans is the most legible of the three at size, covers every European language in Latin, Greek and Cyrillic, comes with a monospace of identical vertical metrics from the same project and under one licence notice, and its one gap — arrows and operators — is filled by registering the monospace as the fallback for characters the sans lacks. The cost is two megabytes in a distribution whose engine jars are eleven.

## Engine health and the fallback

The fork was created in February 2023 and published six releases between 26 August and 26 September 2026; since 1 July it has merged 51 pull requests from 14 authors and closed 30 issues, with 40 open. Most commits come from one maintainer (23 of 52 in that period), so the bus factor is low but not one. `target-counter` across page-straddling boxes, the fix the design waited on, is in.

If the fork stalls or an accessibility regression appears, the **fallback is option A alone**: the same print document through `govuk.pdf.command` and an open-source Python formatter, which CI has proved since 1.0.1. Nothing in the plugin depends on the engine; the generator's `pdf.css` and preparation pass are the only engine-specific code, and they are small.

## What this changes in the plan

- **No change to the print contract.** Contract 1 carries everything the generator needs.
- **Java 17** is the generator's baseline, as it is the toolkit's.
- **veraPDF comes from Maven Central** as a test-scope dependency, pinned in the build, rather than as an installer fetched in CI.
- Two small items for the core, with [#113](https://github.com/iStandUK/govuk-dita-plugin/issues/113): the contents entries for the glossary and index carry no `data-page-label` (the generator's `pdf.css` numbers them regardless), and the build should pass the paper parameters and a date it can derive from the source.
- The `markdown-mini` and `oruk-mini` print documents come out nearly empty when the plugin is built on **Windows** (they are correct in CI on Linux). That is a plugin defect outside this epic, noted here because the spike met it.
