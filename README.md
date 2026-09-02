# govuk-dita-plugin

An open **DITA Open Toolkit (DITA-OT) plugin** that publishes DITA content directly as a
static website styled with the **GOV.UK Design System**.

**Status: v0.9 — robust, entering live trials** —
[v0.9.0](https://github.com/iStandUK/govuk-dita-plugin/releases/tag/v0.9.0) closes the
[v0.9 epic](https://github.com/iStandUK/govuk-dita-plugin/issues/26): full DITA 1.3 spec
coverage and a CI safety net (WCAG 2.2 AA via axe-core, valid HTML, internal-link and
page-weight checks, build determinism). Next comes a period of live trials on real
publications, then a [1.0 registry listing](https://github.com/iStandUK/govuk-dita-plugin/issues/15)
(where official GOV.UK branding also lands). Coverage of bookmaps, keys, chunking, and the SVG
domain is verified against a real corpus ([gap analysis](design/07-gap-analysis-oruk.md)).

## Try it

```bash
dita install https://github.com/iStandUK/govuk-dita-plugin/releases/download/v0.9.0/org.istanduk.gov-uk-0.9.0.zip
dita --input=docs/manual/manual.ditamap --format=govuk --output=out/manual
```

Requires [DITA-OT 4.4.1+](https://www.dita-ot.org/) and Java 17+; nothing else. Optionally,
[Pagefind](https://pagefind.app/) on the build machine enables site search — the plugin does
not bundle the indexer, but published sites carry the search index and interface, so readers
never install anything. Without Pagefind, builds simply omit search. That second
command builds the **[user manual](docs/manual/)** — itself a DITA bookmap, so the result at
`out/manual/index.html` is both the documentation and a live demonstration of every
capability the plugin supports.

## What it will do

One command turns a DITA map into a complete, self-contained static site:

```bash
dita --input=publication.ditamap --format=govuk
```

The output uses GOV.UK Design System components, typography, and accessibility behaviour, laid
out in the style of the GDS Technical Documentation Template (persistent left-hand
navigation), with optional client-side search, a generated A–Z glossary, and a back-of-book
index. Generated sites are built to **WCAG 2.2 AA** and checked on every build with
[axe-core](https://github.com/dequelabs/axe-core), the Nu HTML validator, an internal
link checker, and a page-weight budget in CI.

## Why

Organisations publishing standards and guidance from DITA sources currently rely on
commercial help-output tooling. Those products demonstrate the market need, but there is no
open route from DITA straight to a GOV.UK-styled website. This plugin provides one: pure
DITA-OT + Java at build time, Apache-2.0 licensed, installable with `dita install`.

## Design

The design is documented in [design/](design/):

| Document | Contents |
|---|---|
| [design/README.md](design/README.md) | Index and summary of the agreed direction |
| [design/01-context.md](design/01-context.md) | Background, goals, constraints, prior art, feature-parity analysis |
| [design/02-requirements.md](design/02-requirements.md) | Prioritised functional and non-functional requirements, plus roadmap |
| [design/03-architecture.md](design/03-architecture.md) | Build pipeline, plugin anatomy, extension points, risks |
| [design/04-components.md](design/04-components.md) | Component inventory, DITA → GOV.UK element mapping, traceability |
| [design/05-decision-log.md](design/05-decision-log.md) | Decisions taken, with options and rationale |
| [design/06-open-questions.md](design/06-open-questions.md) | Open questions and next steps |

Architecture in one paragraph: the plugin's `govuk` transtype **extends the built-in
`org.dita.html5` transtype**, inheriting all DITA processing (keys, conref, filtering,
chunking) and overriding only the rendering. It **vendors a pinned release of
[govuk-frontend](https://github.com/alphagov/govuk-frontend)** so builds need no Node.js, and
adds three pieces the base toolkit lacks: glossary and index page generation, and an optional
[Pagefind](https://pagefind.app/) search step that degrades gracefully when not installed.

## Branding — important

The GOV.UK crown and the GDS Transport typeface are **legally restricted to official GOV.UK
services**. This plugin's default output is therefore *neutral*: Design System layout and
components, but system fonts and no crown. A `govuk.branding=official` build parameter enables
full GOV.UK branding and must only be used by genuine GOV.UK services.

## Licence

[Apache-2.0](LICENSE). The plugin will vendor
[govuk-frontend](https://github.com/alphagov/govuk-frontend) (MIT, © Crown Copyright, GDS)
with its licence and attribution retained.
