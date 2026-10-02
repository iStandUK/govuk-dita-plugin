# Changelog

DesignSystemPDF is versioned on its own line, independently of the GOV.UK DITA plugin. Releases are tagged `pdf-v<version>`.

## 0.1.0 — unreleased

The first release. Design: [13 — page numbers in print](https://github.com/iStandUK/govuk-dita-plugin/blob/dev/design/13-print-page-numbers.md); decisions D-23 and D-25.

- Renders the plugin's print document (print contract 1) as a paged PDF: page numbers in the contents, in the index and on cross-references; footnotes at the foot of the page; running heads; repeated table headers; landscape pages for tables and figures marked `outputclass="landscape"`; an outline from the headings.
- Tagged PDF/UA-1 by default, validated with veraPDF in CI; `--no-pdf-ua` writes an untagged file.
- Paper, orientation, margins and mirrored sides from the command line; A4 by default through the document's own stylesheet.
- Bundled Noto Sans and Noto Sans Mono; publisher fonts with `--fonts`.
- The same input gives the same bytes: a date is written only when `--fixed-date` or `SOURCE_DATE_EPOCH` gives one.
- No network request: resources on another origin are reported and left out.
- Refuses a print document whose contract it does not understand, with exit code 3.
- Engine: Open HTML to PDF 1.1.87 with Apache PDFBox 3.0.7, shipped as separate unmodified jars with their source attached to the release.
- A font supplied with `--fonts` also draws any character the font chosen for its text lacks, without the stylesheet naming it; the missing-glyph warning (`DSPDF004W`) is given when, and only when, a replacement mark is printed.
- Known defect: text in a right-to-left script is not rendered correctly — replacement marks without a font for it, unjoined letters running from the left with one — and is reported with `DSPDF010W` ([#153](https://github.com/iStandUK/govuk-dita-plugin/issues/153)). Print the print document from a browser for such publications.
