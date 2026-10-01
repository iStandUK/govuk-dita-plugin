# DesignSystemPDF

Renders an XHTML print document as a paged, tagged PDF: page numbers in the contents, in the index and on cross-references; footnotes at the foot of the page; running heads; an outline; PDF/UA. Java is the only thing it needs.

It is the companion to the [GOV.UK DITA plugin](https://github.com/iStandUK/govuk-dita-plugin) (`org.istanduk.gov-uk`), which writes the print document, and it is a separate product: its own version numbers, its own releases, not a DITA-OT plugin, and never bundled with one.

> **Status:** the product scaffold — the build, the launcher, the distribution and its licences. The command line and rendering follow in the next change; this page then gains the installation and usage sections.

## The distribution

`mvn -B verify` produces `target/designsystempdf-<version>.zip`:

| Path | Contents |
|---|---|
| `bin/designsystempdf`, `bin/designsystempdf.bat` | Launchers for Unix and Windows. They start Java with only `lib/` on the class path, so the generator's libraries never meet a toolkit's. |
| `lib/` | `designsystempdf-<version>.jar` (this product's own code) and the engine and its dependencies as **separate, unmodified jars**. |
| `fonts/` | Noto Sans and Noto Sans Mono with the SIL Open Font License; `fonts/README.md` records where each file came from and its checksum. |
| `LICENSE` | Apache License 2.0, for this product's own code. |
| `THIRD-PARTY-NOTICES`, `licenses/` | The copyright, notice and licence of every component shipped. |
| `README.md`, `CHANGELOG.md` | This page and the list of changes. |

## Building from source

```bash
cd designsystempdf
mvn -B verify
```

needs Java 17 or later and Maven 3.9 or later, and also leaves the engine's source jars in `target/engine-sources/`. The build is reproducible: the same tree gives the same zip.

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
