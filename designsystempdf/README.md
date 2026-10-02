# DesignSystemPDF

Renders an XHTML print document as a paged, tagged PDF: page numbers in the contents, in the index and on cross-references; footnotes at the foot of the page; running heads; an outline; PDF/UA. Java is the only thing it needs.

It is the companion to the [GOV.UK DITA plugin](https://github.com/iStandUK/govuk-dita-plugin) (`org.istanduk.gov-uk`), which writes the print document, and it is a separate product: its own version numbers, its own releases, not a DITA-OT plugin, and never bundled with one. It reads any well-formed XHTML styled with CSS Paged Media, so it is useful on its own too.

## Install

1. Download `designsystempdf-<version>.zip` from the [releases page](https://github.com/iStandUK/govuk-dita-plugin/releases) — DesignSystemPDF releases are the ones tagged `pdf-v…`.
2. Check it. The release carries the zip's SHA-256 in `designsystempdf-<version>.zip.sha256` and a build-provenance attestation:

   ```bash
   sha256sum -c designsystempdf-<version>.zip.sha256
   gh attestation verify designsystempdf-<version>.zip --repo iStandUK/govuk-dita-plugin
   ```

3. Unzip it anywhere and put its `bin` directory on the `PATH`.
4. Have **Java 17 or later** available — on the `PATH` or through `JAVA_HOME`. DITA-OT needs the same, so a machine that builds the site already has it.

Nothing is installed into the toolkit and nothing is downloaded at run time.

## Use

```bash
designsystempdf --in out/site/print.html --out out/site/publication.pdf
```

With the plugin, build the print document (`-Dgovuk.print=yes`) and either name the generator as the formatter —

```bash
dita --input=publication.ditamap --format=govuk --output=out/site \
     -Dgovuk.print=yes -Dgovuk.pdf.command=designsystempdf
```

— or, from the plugin release that adds `govuk.pdf=auto`, simply have `designsystempdf` on the `PATH`: the build finds it as it finds Pagefind.

Plugin releases after 1.0.1 also link the PDF from the site's home page and every footer, beside the print version and with its size: "Whole publication (PDF, 1.2 MB)".

### Options

| Option | Meaning |
|---|---|
| `--in FILE`, `--out FILE` | The print document and the PDF to write. They may also be given as the last two arguments, which is how the plugin's `govuk.pdf.command` passes them. |
| `--paper SIZE` | `A5`, `A4`, `A3`, `B5`, `B4`, `JIS-B5`, `JIS-B4`, `Letter`, `Legal`, `Ledger`, or a width and height such as `"210mm 280mm"`. Without it the document's own stylesheet decides (the plugin writes `govuk.pdf.paper` into `print.css`). |
| `--orientation O` | `portrait` or `landscape`, with a named `--paper`. |
| `--margins M` | `standard` (20 mm top, 18 mm sides, 22 mm bottom), `narrow`, `wide`, or one to four CSS lengths in the order of the CSS `margin` shorthand. |
| `--sides S` | `single`, or `double` for mirrored margins with a wider inner margin for binding. |
| `--fonts DIR` | A directory of TrueType fonts the publisher supplies. They are used where the document's stylesheets name their families, and for characters the other fonts lack. |
| `--no-pdf-ua` | Write an untagged PDF. The default is tagged PDF/UA-1. |
| `--fixed-date ISO` | The document's date, such as `2026-10-01` or `2026-10-01T09:30:00Z`. Without it `SOURCE_DATE_EPOCH` is used if set; otherwise no date is written. |
| `--toc-depth N` | Depth of the PDF outline (bookmarks), 1–6; default 3. |
| `--verbose` | Report progress and the engine's own diagnostics. |
| `--version`, `--help` | The version and the print contracts understood; this summary. |

### Exit codes

`0` the PDF was written (warnings may have been reported) · `1` rendering failed · `2` the command line is wrong · `3` the print document is not one this version understands.

## What it does with the document

The file on disk is read and never rewritten. Before layout, on the parsed document in memory:

- **Footnotes** the plugin wrote as endnotes move to where they are called, and are set at the foot of that page with the author's own marker.
- **Running heads**: the publication title on the left and the chapter's title on the right of every page after the cover.
- **Outline**: the headings below the cover become the PDF's bookmarks.
- **Title, author and subject** of the PDF come from the cover.
- **Alternative text** of inline diagrams and formulas (`aria-label`, an SVG `title`, MathML `alttext`) is carried to the PDF's figure tags.

Its own stylesheet, `pdf.css`, follows the document's: it adds the running heads, the footnote area, repeated table headers and landscape pages for tables and figures marked `outputclass="landscape"`. Page references — "Installing the plugin (page 5)", page numbers in the contents and the index — come from rules the plugin's `print.css` already carries.

## Fonts

A tagged PDF must embed every font it uses, and no restricted typeface is shipped. DesignSystemPDF bundles **Noto Sans** and **Noto Sans Mono** (SIL Open Font License 1.1). Where a stylesheet asks for a family the publisher has not supplied — `arial`, `"Helvetica Neue"`, `sans-serif`, a monospace — the bundled family is used, as a browser falls back to an installed font.

To use other fonts, put their TrueType (`.ttf`) files in a directory and pass `--fonts DIR`: a stylesheet that names GDS Transport, Frutiger or Arial then gets exactly that, from the publisher's own licensed files. A supplied font also fills gaps: a character that the font chosen for its text cannot draw is looked for in the bundled fonts and then in the supplied ones, so a script the bundled fonts lack needs only a font that has it, not a change to the stylesheet. Fonts installed on the machine are never picked up on their own, so the same input gives the same PDF everywhere. OpenType fonts with CFF outlines cannot be embedded by the engine and are skipped with a warning.

## Messages

Messages go to standard error in the form `[DSPDF004W]: …` — the style of the plugin's `GOVK` messages, so a build can surface them unchanged. The last letter is the severity. Warnings never stop a PDF being written.

| Code | Meaning |
|---|---|
| `DSPDF001E` | The command line is wrong; the usage summary follows. Exit 2. |
| `DSPDF002E` | The document's `govuk-print-contract` is not one this version understands. The message names the plugin versions that write an understood contract. Exit 3. |
| `DSPDF003E` | The print document cannot be read, or is not well-formed XHTML. Exit 1. |
| `DSPDF004W` | Characters with no glyph in the bundled fonts or in `--fonts`; they print as a replacement mark. Supply a font that covers them with `--fonts`. The warning is given when, and only when, a replacement mark is printed. |
| `DSPDF005W` | A font in `--fonts` was skipped: not TrueType, unreadable, or the directory is missing. |
| `DSPDF006W` | A stylesheet, image or diagram the document names could not be loaded or drawn. |
| `DSPDF007E` | Rendering failed; no PDF was written. `--verbose` adds the detail. Exit 1. |
| `DSPDF008W` | A resource on another origin was not fetched. The generator makes no network request. |
| `DSPDF009W` | An image, diagram or formula has no alternative text, so the PDF will not meet PDF/UA. Add it in the source. |
| `DSPDF010W` | The document has text in a right-to-left script, which this version neither shapes nor orders (see Limits): it will not read correctly in the PDF, whatever fonts are supplied. Print the print document from a browser. |
| `DSPDF000I` | Progress, with `--verbose`. |

## The same input gives the same bytes

DesignSystemPDF never stamps the clock into a file. The PDF's creation and modification dates are the one given with `--fixed-date` (or `SOURCE_DATE_EPOCH`), or are left out; the file identifier is derived from the document and the options. Two runs over the same document give byte-identical PDFs.

## The print contract

The plugin writes `<meta name="govuk-print-contract" content="1">` into the print document. The number changes only when the structure a paged renderer relies on changes, independently of either product's version. `designsystempdf --version` lists the contracts a release understands; a document with another contract is refused rather than rendered wrongly, and a document with no marker is rendered as ordinary XHTML.

| DesignSystemPDF | Contracts | Written by |
|---|---|---|
| 0.1.x | 1 | `org.istanduk.gov-uk` 1.0.1 and later 1.x |

## Limits

- **Known defect: right-to-left scripts are not rendered** ([#153](https://github.com/iStandUK/govuk-dita-plugin/issues/153)). Right-to-left and complex scripts are not shaped or reordered, and a block's `dir="rtl"` is not honoured; the bundled fonts have no Arabic or Hebrew, so such text prints as replacement marks, with `DSPDF004W`. A font supplied with `--fonts` makes the letters appear, but unjoined and running from the left, so the text is still unreadable. `DSPDF010W` is given whenever a document has such text, with or without a font for it. Until it is fixed, make the PDF of such a publication by printing the print document from a browser.
- Text in any other script the fonts lack prints as replacement marks, with a warning; supply a font that has it with `--fonts`.
- MathML renders small and needs `alttext` to meet PDF/UA.
- PDF/UA-1 is produced; PDF/A is not.
- One paper size per publication, with landscape pages of the same paper.
- Flexbox and grid are not laid out — the plugin's print document does not use them.
- Memory grows with page count: about half a gigabyte for a thousand pages. If Java runs out, raise its limit: `DESIGNSYSTEMPDF_OPTS=-Xmx2g`.

## Building from source

```bash
cd designsystempdf
mvn -B verify
```

needs Java 17 or later and Maven 3.9 or later, and produces `target/designsystempdf-<version>.zip` with the engine's source jars in `target/engine-sources/`. The build is reproducible: the same tree gives the same zip.

## Licences

DesignSystemPDF's own code is licensed under the **Apache License 2.0** (`LICENSE`). The distribution also contains, unmodified:

- **Open HTML to PDF**, the layout engine — GNU Lesser General Public License 2.1 or later (`licenses/LGPL-2.1.txt`);
- Apache PDFBox, Batik and the other libraries listed in `THIRD-PARTY-NOTICES` — Apache License 2.0;
- the Noto fonts — SIL Open Font License 1.1 (`fonts/OFL.txt`).

`THIRD-PARTY-NOTICES` gives the copyright and notice of each.

### Replacing the engine library

The engine is shipped as separate jar files so that it can be replaced, as its licence provides. To run DesignSystemPDF with a modified or newer build, replace the four `lib/openhtmltopdf-*.jar` files with your own builds of the same modules. The launcher puts every jar in `lib/` on the class path; nothing else needs to change. The source of the shipped jars is attached to every release as `openhtmltopdf-*-sources.jar`.

## Versions and support

DesignSystemPDF follows semantic versioning on its own line (`pdf-v0.1.0`, …), independent of the plugin's. Changes are listed in `CHANGELOG.md`. Report problems at <https://github.com/iStandUK/govuk-dita-plugin/issues>, and security problems privately as [SECURITY.md](https://github.com/iStandUK/govuk-dita-plugin/blob/dev/SECURITY.md) describes.
