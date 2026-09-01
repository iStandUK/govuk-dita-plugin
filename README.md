# govuk-dita-plugin

An open **DITA Open Toolkit (DITA-OT) plugin** that publishes DITA content directly as a
static website styled with the **GOV.UK Design System**.

**Status: proof of concept.** The [design](design/) is agreed (tagged
[`design`](https://github.com/iStandUK/govuk-dita-plugin/releases/tag/design)) and the walking
skeleton is building: the plugin in [org.istanduk.gov-uk/](org.istanduk.gov-uk/) renders the
[fixture publication](fixtures/poc/) as GOV.UK-styled pages with sidebar navigation on
DITA-OT 4.4.1. Progress is tracked in
[the PoC epic](https://github.com/iStandUK/govuk-dita-plugin/issues/1).

## Try it

```bash
cd org.istanduk.gov-uk && zip -qr ../org.istanduk.gov-uk.zip . && cd ..
dita install ./org.istanduk.gov-uk.zip
dita --input=fixtures/poc/poc.ditamap --format=govuk --output=out/poc
```

Requires [DITA-OT 4.4.1+](https://www.dita-ot.org/) and Java 17+; nothing else.

## What it will do

One command turns a DITA map into a complete, self-contained static site:

```bash
dita --input=publication.ditamap --format=govuk
```

The output uses GOV.UK Design System components, typography, and accessibility behaviour, laid
out in the style of the GDS Technical Documentation Template (persistent left-hand
navigation), with optional client-side search, a generated A–Z glossary, and a back-of-book
index.

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
